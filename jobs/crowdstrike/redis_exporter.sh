#!/bin/bash
curl -ORL https://github.com/oliver006/redis_exporter/releases/download/v1.52.0/redis_exporter-v1.52.0.linux-amd64.tar.gz
curl -ORL https://github.com/oliver006/redis_exporter/releases/download/v1.52.0/sha256sums.txt

sha256sum -c --ignore-missing sha256sums.txt

tar xzvvf redis_exporter-v1.52.0.linux-amd64.tar.gz

mkdir -p /usr/local/redis_exporter/redis_exporter-v1.52.0.linux-amd64

cp -p redis_exporter-v1.52.0.linux-amd64/* /usr/local/redis_exporter/redis_exporter-v1.52.0.linux-amd64/

chown -R root:root /usr/local/redis_exporter
chmod 755 /usr/local/redis_exporter/redis_exporter-v1.52.0.linux-amd64/redis_exporter

cat << EOF | tee /etc/systemd/system/redis_exporter.service
[Unit]
Description=Redis Exporter
Documentation=https://github.com/oliver006/redis_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/redis_exporter/redis_exporter-v1.52.0.linux-amd64/redis_exporter \
    -redis.addr="redis://127.0.0.1:6379" \
    -redis.password-file=/etc/redis_exporter/pwd-file.json

SyslogIdentifier=redis_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

mkdir /etc/redis_exporter

cat << EOF | tee /etc/redis_exporter/pwd-file.json
{
  "redis://127.0.0.1:6379": "z4YHvgKhXj2Ffcmb"
}
EOF

chown root:prometheus /etc/redis_exporter/pwd-file.json
chmod 640 /etc/redis_exporter/pwd-file.json

systemctl enable redis_exporter.service
systemctl start redis_exporter
systemctl status redis_exporter

sleep 30
curl http://localhost:9121/metrics

rm -rf redis_exporter-v1.52.0.linux-amd64*
