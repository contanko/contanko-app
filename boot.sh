#!/bin/bash

# Fail hard and fast
set -eo pipefail

value=`cat .secret`
export SECRET_KEY_BASE=$value

#export HOST_IP=${HOST_IP:-172.17.42.1}
#export ETCD=$HOST_IP:4001

echo "[contanko] booting container. : $SECRET_KEY_BASE"


# Start redis
echo "[redis] starting redis service..."
bundle exec sidekiq &
service redis-server start

rails server -b 0.0.0.0

# Tail all nginx log files
tail -f /usr/src/app/log/*.log
