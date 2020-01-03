#!/bin/sh

set -e

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
set -e
echo "-----------------Rsync started at"
date
sudo -u "${RSYNC_USER}" -g "${RSYNC_GROUP}" \
    rsync \
        ${RSYNC_OPTIONS} \
        /rsync_src/ \
        /rsync_dst --log-file=$LOGFILE


echo Rsync ended at
date

#Email Notification
if [[ $? -eq 0 ]]; then
echo "Backup Process was Successful"
else
SUBJECT="Rsync Process error"
echo "Rsync Process error. Sending Email..."
cat $LOGFILE | mail -s "$SUBJECT" "${MAIL_TO}"
echo "Email Sent."
fi
EOF
chmod +x /run-rsync.sh

# Setup our crontab entry
export CRONTAB_ENTRY="${RSYNC_CRONTAB} sh /run-rsync.sh"
