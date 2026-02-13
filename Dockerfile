FROM debian:stable-slim

ARG OPENSSL_VERSION=3.5.0
ARG NGINX_VERSION=1.26.2

RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    ca-certificates \
    perl \
    zlib1g-dev \
    libpcre2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# =========================
# Build OpenSSL 3.5
# =========================
RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -xzf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./Configure linux-x86_64 --prefix=/opt/openssl --openssldir=/opt/openssl shared \
    && make -j$(nproc) \
    && make install

ENV PATH="/opt/openssl/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/openssl/lib"

# =========================
# Build nginx against custom OpenSSL
# =========================
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure \
        --prefix=/opt/nginx \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-openssl=/tmp/openssl-${OPENSSL_VERSION} \
        --with-openssl-opt="shared" \
    && make -j$(nproc) \
    && make install

# =========================
# Generate certs & keys 
# =========================
COPY scripts/gen_certs.sh /opt/nginx/conf/
COPY scripts/gen_ml_dsa_certs.sh /opt/nginx/conf/

# Add build argument
ARG USE_MLDSA=false

# Make scripts executable
RUN chmod +x /opt/nginx/conf/gen_certs.sh /opt/nginx/conf/gen_ml_dsa_certs.sh

# Conditionally run one or the other
RUN if [ "$USE_MLDSA" = "true" ]; then \
        /opt/nginx/conf/gen_ml_dsa_certs.sh; \
    else \
        /opt/nginx/conf/gen_certs.sh; \
    fi

# =========================
# Minimal nginx config
# =========================

COPY nginx.conf /opt/nginx/conf/nginx.conf

EXPOSE 443

WORKDIR /opt/nginx

CMD ["./sbin/nginx", "-g", "daemon off;"]

