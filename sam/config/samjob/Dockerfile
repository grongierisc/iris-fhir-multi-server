FROM alpine

RUN apk add bind-tools curl

COPY samjob.sh /tmp/samjob.sh

RUN mkdir /tmp/crontabs \
    && echo 'SHELL=/bin/sh' > /tmp/crontabs/root \
    && echo '* * * * * /tmp/samjob.sh' >> /tmp/crontabs/root \
    && chmod 0755 /tmp/samjob.sh

CMD ["crond", "-c", "/tmp/crontabs", "-l", "0", "-d", "0", "-f"] 