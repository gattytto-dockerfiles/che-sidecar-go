# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM node:10.16-alpine

ENV HOME=/home/theia

RUN mkdir /projects ${HOME} && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

RUN set -e \
    && \
    apk add --update --no-cache  --virtual .build-deps \
        bash \
        gcc \
        g++ \
        musl-dev \
        openssl \
        go \
        git \
        make \
    && \
    export \
        GOROOT_BOOTSTRAP="$(go env GOROOT)" \
        GOOS="$(go env GOOS)" \
        GOARCH="$(go env GOARCH)" \
        GOHOSTOS="$(go env GOHOSTOS)" \
        GOHOSTARCH="$(go env GOHOSTARCH)" \
    && \
    apkArch="$(apk --print-arch)" \
    && \
    case "$apkArch" in \
        armhf) export GOARM='6' ;; \
        x86) export GO386='387' ;; \
    esac \
    && \
    wget -qO- https://dl.google.com/go/go1.12.17.linux-amd64.tar.gz | tar xvz -C /usr/local && \
    cd /usr/local/go/src &&    ./make.bash && \
    rm -rf /usr/local/go/pkg/bootstrap /usr/local/go/pkg/obj && \
    export GOPATH="/go" && \
    mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg" && \
    export PATH="$GOPATH/bin:/usr/local/go/bin:$PATH" && \
    go get -u -v github.com/go-delve/delve/cmd/dlv && \
    GO111MODULE=on go get -v golang.org/x/tools/gopls@latest && \
    go build -o /go/bin/gocode-gomod github.com/stamblerre/gocode && \
    cd /projects && git clone https://github.com/cri-o/cri-o && \
    cd cri-o && go get -d -v all && cd /usr/local/go/src && rm -rf /projects/cri-o && \
    chmod -R 777 "$GOPATH" && \
    apk del .build-deps && \
    mkdir /.cache && chmod -R 777 /.cache && \
    cd /usr/local && wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.24.0 -b /usr/local && \
    cd /go/bin && mkdir protoc-download && cd protoc-download && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v3.11.2/protoc-3.11.2-linux-x86_64.zip && \
    unzip protoc-3.11.2-linux-x86_64.zip && rm -f protoc-3.11.2-linux-x86_64.zip && cp -R include ../ && \
    cp bin/protoc ../ && cd ../ && rm -rf protoc-download     

ENV GOPATH /go
ENV GOCACHE /.cache
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
