FROM registry.altlinux.org/alt/alt

RUN \
	apt-get update && \
	apt-get install -y docker-registry && \
	ln -sf /usr/bin/docker-registry /bin/registry

VOLUME ["/var/lib/registry"]
EXPOSE 5000

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/docker-registry/config.yml"]
