FROM ghcr.io/intersectmbo/cardano-node:8.9.2
WORKDIR /app
COPY . /app
RUN apt-get update && apt-get install -y jq whiptail
RUN chmod +x *.sh examples/*.sh || true
CMD ["bash"]
