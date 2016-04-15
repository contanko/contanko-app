#!/bin/bash

# Fail hard and fast
set -eo pipefail

if [ ! -f .secret ]; then
    rake secret > .secret
    rake db:seed
fi

value=`cat .secret`
export SECRET_KEY_BASE=$value

value2=`ip route | awk 'NR==1 {print $3}'`
export HOST_GATEWAY=$value2

#export HOST_IP=${HOST_IP:-172.17.42.1}
#export ETCD=$HOST_IP:4001

echo "[contanko] booting container. : $SECRET_KEY_BASE"


# Start redis
echo "[redis] starting redis service..."
service redis-server start
bundle exec sidekiq &

rails server -b 0.0.0.0

# Tail all nginx log files
tail -f /usr/src/app/log/*.log
