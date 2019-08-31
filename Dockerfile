FROM debian:stretch

# Install deps
RUN apt-get update -y && apt-get install -y \
    curl \
    unzip \
    git \
    build-essential \
    autoconf \
    dh-autoreconf \
    automake

WORKDIR /tmp/

RUN git clone -b $(curl -L https://grpc.io/release) https://github.com/grpc/grpc && \
    cd grpc && \
    git submodule update --init

# Make plugins
RUN cd /tmp/grpc && \
    make && \
    make install && \
    make grpc_php_plugin && \
    mv /tmp/grpc/bins/opt/grpc_php_plugin /usr/local/bin && \
    rm -r /tmp/*

# Get binaries
RUN curl -L -o /tmp/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protoc-3.9.1-linux-x86_64.zip && \
    unzip /tmp/protoc.zip bin/protoc -d /tmp/ &&  \
    mv /tmp/bin/protoc /usr/local/bin/protoc && \
    chmod a+x /usr/local/bin/protoc && \
    rm -r /tmp/bin && \
    rm /tmp/protoc.zip

RUN curl -L -o /tmp/spiral.tar.gz https://github.com/spiral/php-grpc/releases/download/v1.0.7/protoc-gen-php-grpc-1.0.7-linux-amd64.tar.gz && \
    tar -xvf /tmp/spiral.tar.gz protoc-gen-php-grpc-1.0.7-linux-amd64/protoc-gen-php-grpc &&  \
    mv /tmp/protoc-gen-php-grpc-1.0.7-linux-amd64/protoc-gen-php-grpc /usr/local/bin/protoc-gen-php-grpc && \
    chmod a+x /usr/local/bin/protoc-gen-php-grpc && \
    rm -r /tmp/protoc-gen-php-grpc-1.0.7-linux-amd64 && \
    rm /tmp/spiral.tar.gz

# Get protobuf includes
RUN curl -L -o /tmp/protobuf.tar.gz https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protobuf-all-3.9.1.tar.gz && \
    tar -xvf /tmp/protobuf.tar.gz protobuf-3.9.1/src/google &&  \
    mv /tmp/protobuf-3.9.1/src/google /usr/include/google && \
    chmod a+x /usr/local/bin/protoc-gen-php-grpc && \
    rm -r /tmp/protobuf-3.9.1 && \
    rm /tmp/protobuf.tar.gz

FROM debian:stretch-slim

COPY --from=0 /usr/local/bin/protoc /usr/local/bin/protoc
COPY --from=0 /usr/local/bin/protoc-gen-php-grpc /usr/local/bin/protoc-gen-php-grpc
COPY --from=0 /usr/local/bin/grpc_php_plugin /usr/local/bin/grpc_php_plugin
COPY --from=0 /usr/include/google /usr/include/google
RUN ln -s /usr/local/bin/grpc_php_plugin /usr/local/bin/protoc-gen-grpc && \
    chmod a+x /usr/local/bin/protoc-gen-grpc
ENV PATH="/usr/include/:${PATH}"


WORKDIR /tmp/

ENTRYPOINT ["protoc", "-I", "/usr/include"]
