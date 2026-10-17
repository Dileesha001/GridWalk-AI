FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates git unzip \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(uname -m)" \
    && case "$arch" in \
         x86_64) checksum=bb93ea1920b776592af2e38f6cd0cb1db1f71c7afdadf7ba841210b645212ce6 ;; \
         aarch64) checksum=0e4ada659c89b8be572203109203c84e0b799f5dfcf409be5f4b404da070cfbf ;; \
         *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
       esac \
    && curl --fail --location --show-error \
       "https://github.com/jaseci-labs/jac/releases/download/v0.34.23/jac-0.34.23-linux-${arch}" \
       --output /usr/local/bin/jac \
    && printf '%s  %s\n' "$checksum" /usr/local/bin/jac | sha256sum --check --status \
    && chmod 755 /usr/local/bin/jac \
    && jac --version

WORKDIR /app
COPY . .
RUN jac install

ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "jac start main.jac --port ${PORT:-8080}"]
