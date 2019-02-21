#!/bin/bash
set -e

# dump parameters to a tmp file
echo ${hosted_zone_id} >> /tmp/app.txt
echo ${hosted_zone_name} >> /tmp/app.txt

# get availability zone: eg. ap-southeast-2a
az=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

# get number from az tail value. ap-southeast-2a => a => 1
launch_index=$(echo -n $az | tail -c 1 | tr abcdef 123456)
private_ip=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")

function install_confluent() {
    yum update -y
    rpm --import http://packages.confluent.io/rpm/3.2/archive.key

    echo '
[Confluent.dist]
name=Confluent repository (dist)
baseurl=http://packages.confluent.io/rpm/3.2/6
gpgcheck=1
gpgkey=http://packages.confluent.io/rpm/3.2/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=http://packages.confluent.io/rpm/3.2
gpgcheck=1
gpgkey=http://packages.confluent.io/rpm/3.2/archive.key
enabled=1 
    ' > /etc/yum.repos.d/confluent.repo
    yum clean all -y
    yum install -y confluent-platform-oss-2.11

}

function update_zookeeper_dns() {
    tmp_file_name=tmp-record.json

    echo '{
    "Comment": "DNS updated by zookeeper'${node_id}' autoscaling group",
    "Changes": [
        {
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "'zk${node_id}'.${hosted_zone_name}",
            "Type": "A",
            "TTL": 30,
            "ResourceRecords": [
            {
                "Value": "'$private_ip'"
            }
            ]
        }
        }
    ]
    }' > $tmp_file_name

    aws route53 change-resource-record-sets --hosted-zone-id ${hosted_zone_id} --change-batch file://$tmp_file_name
}

function update_zookeeper_configuration() {
    echo 'autopurge.snapRetainCount=3
autopurge.purgeInterval=24
tickTime=2000
initLimit=10
syncLimit=2' >> /etc/kafka/zookeeper.properties

    for i in {1..${cluster_size}}; do
        if [ "$i" == "${node_id}" ]; then
            echo "server.$i=0.0.0.0:2888:3888" >> /etc/kafka/zookeeper.properties
        else
            echo 'server.'$i'=zk'$i.${hosted_zone_name}':2888:3888' >> /etc/kafka/zookeeper.properties
        fi
    done

    mkdir -p /var/lib/zookeeper
    echo ${node_id} >> /var/lib/zookeeper/myid
}

echo "Starting zookeeper."
install_confluent
update_zookeeper_dns
update_zookeeper_configuration

cmd="zookeeper-server-start /etc/kafka/zookeeper.properties 2>&1 > /var/log/zookeeper.log &"
action=reboot # restart zookeeper on failure
# put cmd to /etc/rc.local so it can start when system reboot
echo "$cmd" >> /etc/rc.local
