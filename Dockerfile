FROM ubuntu:jammy AS base

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -q && apt-get install -qy --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    python3 \
    device-tree-compiler \
    cmake \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/opt/systemc/include
ENV LIBRARY_PATH=$LIBRARY_PATH:/opt/systemc/lib-linux64
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/systemc/lib-linux64

ENV SYSTEMC_LIBDIR=/opt/systemc/lib-linux64
ENV SYSTEMC_INCLUDE=/opt/systemc/include

ENV CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/opt/uvm-systemc/include
ENV LIBRARY_PATH=$LIBRARY_PATH:/opt/uvm-systemc/lib-linux64
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/uvm-systemc/lib-linux64

FROM base AS build

RUN apt-get update -q && apt-get install -qy --no-install-recommends \
    autoconf flex bison libfl2 libfl-dev \
    help2man \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV CXXFLAGS='-std=c++14'

WORKDIR /opt/download
RUN curl https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.3.tar.gz | tar -xzC /opt/download \
 && cd systemc-2.3.3 \
 && mkdir -p objdir \
 && cd objdir \
 && cmake -DENABLE_PHASE_CALLBACKS_TRACING=OFF \
    -DINSTALL_TO_LIB_TARGET_ARCH_DIR=ON \
    -DCMAKE_CXX_STANDARD=14 \
    .. \
 && make \
 && make install

WORKDIR /opt/download
RUN curl https://www.accellera.org/images/downloads/drafts-review/uvm-systemc-10-beta3tar.gz | tar -xzC /opt/download \
 && cd uvm-systemc-1.0-beta3 \
 && mkdir objdir \
 && cd objdir \
 && ../configure --prefix=/opt/uvm-systemc --with-systemc=/opt/systemc \
 && make \
 && make install

WORKDIR /opt/download
RUN git clone -b v5.006 https://github.com/verilator/verilator \
 && cd verilator \
 && autoconf \
 && ./configure --prefix=/opt/verilator \
 && make \
 && make install

RUN rm -rf /opt/download

FROM base AS install

COPY --from=build /opt /opt
ENV PATH=$PATH:/opt/verilator/bin
