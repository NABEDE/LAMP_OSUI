FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y sudo wget curl vim net-tools rsyslog && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY apps/debian/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh

CMD ["/bin/bash", "/tmp/install.sh", "--no-confirm"]

EXPOSE 80
