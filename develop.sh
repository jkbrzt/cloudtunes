#!/bin/sh

pip install -e ./cloudtunes-server


# Get the `iterm-multiple' command at:
# <https://gist.github.com/jakubroztocil/6018903>
iterm-multiple \
    "mongod run --config /usr/local/etc/mongod.conf -vvv & tail -f /usr/local/var/log/mongodb/mongo.log | grep --color cloudtunes" \
    "killall redis-server; sleep 2; redis-server" \
    "sleep 5 && redis-cli monitor" \
    "sleep 3 && workon cloudtunes && cloudtunes-server" \
    "sleep 3 && workon cloudtunes && cloudtunes-worker worker --loglevel=INFO -c 4" \
    "cd cloudtunes-webapp && brunch watch" \
    &


