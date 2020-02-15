#!/bin/sh

set -e

/usr/bin/envsubst < "/etc/ssmtp/ssmtp.conf.tmpl" > "/etc/ssmtp/ssmtp.conf"

# Make sure that the group and users specified by the user exist
if ! getent group "${RSYNC_GID}" &>/dev/null; then
    addgroup -g "${RSYNC_GID}" "rsynccron"
fi
RSYNC_GROUP="$(getent group "${RSYNC_GID}" | cut -d: -f1)"

if ! getent passwd "${RSYNC_UID}" &>/dev/null; then
    adduser -u "${RSYNC_UID}" -H "rsynccron" "${RSYNC_GROUP}"
fi
RSYNC_USER="$(getent passwd "${RSYNC_UID}" | cut -d: -f1)"

if ! getent group "${RSYNC_GROUP}" | grep "${RSYNC_USER}" &>/dev/null; then
    addgroup "${RSYNC_USER}" "${RSYNC_GROUP}"
fi

# Create a rsync script, makes it easier to sudo
cat << EOF > /run-rsync.sh
echo "-----------------Rsync started at \$(date)"
rm /rsync.log
sudo -u "${RSYNC_USER}" -g "${RSYNC_GROUP}" \
    rsync \
        ${RSYNC_OPTIONS} \
        /rsync_src/ \
        /rsync_dst --log-file=/rsync.log

#Email Notification
if [[ \$? -eq 0 ]]; then
echo "Rsync successful at \$(date)"
else
echo "Rsync error at \$(date). Sending Email..."
cat /rsync.log | mail -s "Rsync error detected on host: ${HOSTNAME}" "${MAIL_TO}"
echo "Email sent"
fi

EOF
chmod +x /run-rsync.sh

df -h /dev/sda1 | mail -s "Rsync error (EmailTest) detected on host: ${HOSTNAME}" "${MAIL_TO}"

# Setup our crontab entry
export CRONTAB_ENTRY="${RSYNC_CRONTAB} sh /run-rsync.sh"
