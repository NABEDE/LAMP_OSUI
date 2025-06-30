FROM ubuntu:22.04

RUN apt-get update || true && \
    apt-get install -y gnupg curl && \
    curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x871920D1991BC93C | gpg --dearmor -o /etc/apt/trusted.gpg.d/ubuntu-keyring.gpg


COPY apps/ubuntu/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh

CMD ["/bin/bash", "/tmp/install.sh", "--no-confirm"]

EXPOSE 80
