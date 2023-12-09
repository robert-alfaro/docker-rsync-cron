#!/bin/sh

if test -f /entrypoint.d/*; then
    . /entrypoint.d/*
fi

cat << EOF > /var/spool/cron/crontabs/root
${CRONTAB_ENTRY}
EOF

echo cron entry is $(cat /var/spool/cron/crontabs/root)

#exec "$@"
/usr/sbin/crond -f -l 8
