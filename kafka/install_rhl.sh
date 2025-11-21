#!/bin/bash
# =============================================================================
# One-click Apache Kafka 3.8.0 + ZooKeeper installer for RHEL 9 & RHEL 8
# Run as root → fully working Kafka in < 3 minutes
# =============================================================================

set -euo pipefail

KAFKA_VERSION="3.5.1"
SCALA_VERSION="2.13-3.5.1"
KAFKA_TGZ="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
DOWNLOAD_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"
INSTALL_DIR="/opt/kafka"
KAFKA_USER="kafka"
KAFKA_DATA_DIR="/var/lib/kafka"
ZOO_DATA_DIR="/var/lib/zookeeper"

echo "Installing Apache Kafka $KAFKA_VERSION on RHEL..."

# 1. Create kafka user
id -u $KAFKA_USER &>/dev/null || useradd -r -m -s /sbin/nologin $KAFKA_USER

# 2. Install Java 17 (Kafka 3.8 requires Java 11+)
dnf install -y java-17-openjdk java-17-openjdk-devel

# 3. Download and extract Kafka
cd /tmp
wget -q "$DOWNLOAD_URL"
tar -xzf "$KAFKA_TGZ"
mv "kafka_${SCALA_VERSION}-${KAFKA_VERSION}" "$INSTALL_DIR"
chown -R $KAFKA_USER:$KAFKA_USER "$INSTALL_DIR"
rm -f "$KAFKA_TGZ"

# 4. Create data directories
mkdir -p "$KAFKA_DATA_DIR" "$ZOO_DATA_DIR"
chown -R $KAFKA_USER:$KAFKA_USER "$KAFKA_DATA_DIR" "$ZOO_DATA_DIR"

# 5. Configure ZooKeeper (myid = 1 for single node)
echo "1" > "$ZOO_DATA_DIR/myid"
chown $KAFKA_USER:$KAFKA_USER "$ZOO_DATA_DIR/myid"

# 6. Minimal config files (optimized for single node)
cat > $INSTALL_DIR/config/zookeeper.properties <<EOF
dataDir=$ZOO_DATA_DIR
clientPort=2181
maxClientCnxns=50
admin.enableServer=false
EOF

cat > $INSTALL_DIR/config/server.properties <<EOF
broker.id=0
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://$(hostname -I | awk '{print $1}'):9092
log.dirs=$KAFKA_DATA_DIR
num.partitions=3
default.replication.factor=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
zookeeper.connect=localhost:2181
EOF

# 7. Create systemd services
cat > /etc/systemd/system/zookeeper.service <<EOF
[Unit]
Description=Apache ZooKeeper
After=network.target

[Service]
Type=forking
User=$KAFKA_USER
ExecStart=$INSTALL_DIR/bin/zookeeper-server-start.sh $INSTALL_DIR/config/zookeeper.properties
ExecStop=$INSTALL_DIR/bin/zookeeper-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka Server
After=network.target zookeeper.service
Requires=zookeeper.service

[Service]
Type=simple
User=$KAFKA_USER
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $INSTALL_DIR/config/server.properties
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 8. Reload systemd and start services
systemctl daemon-reload
systemctl enable zookeeper kafka
systemctl start zookeeper
systemctl start kafka

# 9. Open firewall ports (2181 ZooKeeper, 9092 Kafka)
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-port=2181/tcp
    firewall-cmd --permanent --add-port=9092/tcp
    firewall-cmd --reload
fi

# 10. Quick test topic
sleep 8
sudo -u kafka $INSTALL_DIR/bin/kafka-topics.sh --create --topic quickstart --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 || true

clear
echo "============================================================"
echo " Apache Kafka $KAFKA_VERSION is successfully installed!"
echo "============================================================"
echo "   ZooKeeper  → localhost:2181"
echo "   Kafka       → $(hostname -I | awk '{print $1}'):9092"
echo ""
echo "Test commands:"
echo "   # List topics"
echo "   $INSTALL_DIR/bin/kafka-topics.sh --list --bootstrap-server localhost:9092"
echo ""
echo "   # Producer (in one terminal)"
echo "   $INSTALL_DIR/bin/kafka-console-producer.sh --topic quickstart --bootstrap-server localhost:9092"
echo ""
echo "   # Consumer (in another terminal)"
echo "   $INSTALL_DIR/bin/kafka-console-consumer.sh --topic quickstart --from-beginning --bootstrap-server localhost:9092"
echo ""
echo "Service status:"
echo "   systemctl status zookeeper kafka"
echo "============================================================"

exit 0
