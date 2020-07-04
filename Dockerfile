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
    wget -qO- https://dl.google.com/go/go1.15beta1.linux-amd64.tar.gz | tar xvz -C /usr/local && \
    cd /usr/local/go/src &&    ./make.bash && \
    rm -rf /usr/local/go/pkg/bootstrap /usr/local/go/pkg/obj 
    
ENV GOPATH /go
ENV GO111MODULE off
ENV GOCACHE /.cache
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN export GOPATH="/go" && \
    mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg" && \
    export PATH="$GOPATH/bin:/usr/local/go/bin:$PATH" && \
    cd /projects && git clone https://github.com/cri-o/cri-o && \
    cd cri-o && GO111MODULE=off go get -u -d -v -fix ... && cd /usr/local/go/src && rm -rf /projects/cri-o && \
    go get -u -v github.com/go-delve/delve/cmd/dlv && \
    go get -u -v github.com/ramya-rao-a/go-outline && \
    go get -u -v github.com/acroca/go-symbols &&  \
    go get -u -v github.com/stamblerre/gocode &&  \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v golang.org/x/tools/cmd/godoc && \
    go get -u -v github.com/zmb3/gogetdoc && \
    go get -u -v golang.org/x/lint/golint && \
    go get -u -v github.com/fatih/gomodifytags &&  \
    go get -u -v golang.org/x/tools/cmd/gorename && \
    go get -u -v sourcegraph.com/sqs/goreturns && \
    go get -u -v golang.org/x/tools/cmd/goimports && \
    go get -u -v github.com/cweill/gotests/... && \
    go get -u -v golang.org/x/tools/cmd/guru && \
    go get -u -v github.com/josharian/impl && \
    go get -u -v github.com/haya14busa/goplay/cmd/goplay && \
    go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct && \
    go get -u -v github.com/go-delve/delve/cmd/dlv && \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs && \
    go get -u -v golang.org/x/tools/cmd/gotype && \
    go get -u -v google.golang.org/grpc && \
    go get -u -v  google.golang.org/genproto/... && \
    go get -u github.com/jinzhu/gorm && \
    go get -d -u -v github.com/infobloxopen/protoc-gen-gorm && \
    GO111MODULE=on go get -v golang.org/x/tools/gopls@latest && \
    go build -o /go/bin/gocode-gomod github.com/stamblerre/gocode && \
    chmod -R 777 "$GOPATH" && \
    apk del .build-deps && \
    chmod -R 777 /home/theia/.cache && mkdir -p /home/theia/.cache/golangci-lint && chmod -R 777 /home/theia/.cache && mkdir -p /home/theia/.theia/plugins && \
    mkdir -p mkdir -p /home/theia/.theia/extensions && chmod -R 777 /home/theia/.theia && \
    cd /usr/local && wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.24.0 -b /usr/local && \
    apk add git curl file pkgconfig bash ssh

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}
