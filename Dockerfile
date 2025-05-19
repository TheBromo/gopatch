FROM golang:1.24.3-bookworm AS build

ENV PATH=/usr/local/go/bin:$PATH

ENV GOLANG_VERSION=1.24.3


RUN git clone https://github.com/golang/go -b release-branch.go1.24 --depth 1 ~/go1.24

COPY ./critical-dirname-constraint.patch /tmp/critical-dirname-constraint.patch
RUN cd ~/go1.24/src && git apply /tmp/critical-dirname-constraint.patch; \
	rm /tmp/critical-dirname-constraint.patch 

RUN cd ~/go1.24/src && ./make.bash

RUN  rm -rf /usr/local/go

RUN mkdir /target /target/usr /target/usr/local; \
	mv -vT ~/go1.24/ /target/usr/local/go; \
	ln -svfT /target/usr/local/go /usr/local/go; \	
	ln -svfT /target/usr/local/go /go; \	
	touch -t "$touchy" /target/usr/local /target/usr /target; \
	\
# smoke test
	go version

FROM buildpack-deps:bookworm-scm

# install cgo-related dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
	; \
	rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION=1.24.3

# don't auto-upgrade the gotoolchain
# https://github.com/docker-library/golang/issues/472
ENV GOTOOLCHAIN=local

ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
# (see notes above about "COPY --link")
COPY --from=build --link /target/ /
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 1777 "$GOPATH"
WORKDIR $GOPATH