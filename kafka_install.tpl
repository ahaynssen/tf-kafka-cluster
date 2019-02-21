#!/bin/bash
set -e

# dump parameters to a tmp file
echo ${hosted_zone_id} >> /tmp/app.txt
echo ${hosted_zone_name} >> /tmp/app.txt

function install_confluent() {
    yum update -y
    rpm --import http://packages.confluent.io/rpm/4.1/archive.key

    echo '
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/4.1/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/4.1/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/4.1
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/4.1/archive.key
enabled=1
    ' > /etc/yum.repos.d/confluent.repo
    yum clean all -y
    yum install -y confluent-platform-oss-2.11

}

function update_kafka_configurations() {
    for i in {1..${zookeeper_cluster_size}}; do
        zk_dns+="zk$i.${hosted_zone_name}:2181,"
    done

    # update zookeeper IP address
    sed -i "s#localhost:2181#$zk_dns#g" /etc/kafka/server.properties
    sed -i "s#localhost:2181#$zk_dns#g" /etc/kafka/consumer.properties
    sed -i "s#localhost:2181#$zk_dns#g" /etc/schema-registry/schema-registry.properties

    #server properties
    sed -i "s#broker.id=0#broker.id=${broker_id}#g" /etc/kafka/server.properties
    sed -i "s#log.retention.hours=168#log.retention.hours=336#g" /etc/kafka/server.properties
    sed -i "s#offsets.topic.replication.factor=1#offsets.topic.replication.factor=3#g" /etc/kafka/server.properties
    echo "" >> /etc/kafka/server.properties
    echo "min.insync.replicas=2" >> /etc/kafka/server.properties
    echo "default.replication.factor=3" >> /etc/kafka/server.properties

    #broker properties
    echo "retries=1" >> /etc/kafka/producer.properties
    echo "max.in.flight.requests.per.connection=1" >> /etc/kafka/producer.properties
}

echo "Starting kafka."
install_confluent
update_kafka_configurations

sysctl -w fs.file-max=500000

cmd="(kafka-server-start /etc/kafka/server.properties 2>&1 > /var/log/kafka.log  & ) ; sleep 5;
     (schema-registry-start /etc/schema-registry/schema-registry.properties 2>&1 > /var/log/schema-registry.log  & )"
action=poweroff # let ASG bring a new one
# put cmd to /etc/rc.local so it can start when system reboot
echo "$cmd" >> /etc/rc.local

