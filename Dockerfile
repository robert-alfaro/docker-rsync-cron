FROM balenalib/armv7hf-alpine

ENV CRONTAB_ENTRY=""

RUN apk --update --upgrade add ssmtp mailx gawk

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]

ENV \
    RSYNC_CRONTAB="0 0 * * *" \
    RSYNC_OPTIONS="--archive --timeout=3600" \
    RSYNC_UID="0" \
    RSYNC_GID="0"

RUN set -x; \
    apk add --no-cache --update rsync sudo \
    && rm -rf /tmp/* \
    && rm -rf /var/cache/apk/*

VOLUME ["/rsync_src", "/rsync_dst"]

ADD ssmtp.conf.tmpl /etc/ssmtp/ssmtp.conf.tmpl

COPY rsync-entrypoint.sh /entrypoint.d/rsync.sh

CMD ["crond", "-f", "-l", "0"]

