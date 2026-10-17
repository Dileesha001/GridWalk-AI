FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates git unzip \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(uname -m)" \
    && curl --fail --location --show-error \
       "https://github.com/jaseci-labs/jac/releases/download/v0.34.13/jac-0.34.13-linux-${arch}" \
       --output /usr/local/bin/jac \
    && chmod 755 /usr/local/bin/jac \
    && jac --version

WORKDIR /app
COPY . .
RUN jac install

ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "jac start main.jac --port ${PORT:-8080}"]
