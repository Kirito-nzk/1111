FROM ubuntu:20.04
SHELL ["/bin/bash", "-c"]
ENV RISCV=/opt/riscv
ENV PATH=$RISCV/bin:$PATH
RUN export DEBIAN_FRONTEND=noninteractive &&\
    sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    gcc-riscv64-unknown-elf gdb-multiarch dosfstools cmake \
    git wget python3 vim file curl \
    autoconf automake autotools-dev  libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo gperf libtool patchutils bc \
    zlib1g-dev libexpat-dev \
    ninja-build pkg-config libglib2.0-dev libpixman-1-dev libsdl2-dev \ 
    && rm -rf /var/lib/apt/lists/*
#seL4 Build Dependencies(Cross-compiling for RISC-V targets)
RUN  export DEBIAN_FRONTEND=noninteractive \
&& apt-get -y update \
&& apt-get install -y build-essential \
&& apt-get install -y bison \
&& apt-get install -y cmake ccache ninja-build cmake-curses-gui \
&& apt-get install -y libxml2-utils ncurses-dev \
&& apt-get install -y curl git doxygen device-tree-compiler \
&& apt-get install -y u-boot-tools \
&& apt-get install -y python3-dev python3-pip python-is-python3 \
&& apt-get install -y protobuf-compiler python3-protobuf \
&& apt-get install -y qemu-system-arm qemu-system-x86 qemu-system-misc \ 
&& apt-get install -y gcc-arm-linux-gnueabi g++-arm-linux-gnueabi \
&& apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
$$ apt-get install repo

RUN pip3 install --user camkes-deps


#CAmkES Build Dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
&& curl -sSL https://get.haskellstack.org/ | sh \
&& apt-get install -y haskell-stack \
&& apt-get install -y clang gdb \
&& apt-get install -y libssl-dev libclang-dev libcunit1-dev libsqlite3-dev \
&& apt-get install -y qemu-kvm \
&& apt-get install -y python3.8-venv \
&& apt-get install -y pkg-config \
&& apt-get install -y libglib2.0-dev 

WORKDIR /root
#Rust
ARG RUST_VERSION=nightly
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
RUN mkdir .cargo && \
    echo '[source.crates-io]' >> .cargo/config && \
    echo 'registry = "https://github.com/rust-lang/crates.io-index"' >> .cargo/config && \
    echo 'replace-with = "ustc"' >> .cargo/config && \
    echo '[source.ustc]' >> .cargo/config && \
    echo 'registry = "git://mirrors.ustc.edu.cn/crates.io-index"' >> .cargo/config && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --default-toolchain ${RUST_VERSION} --target riscv64imac-unknown-none-elf && \
    rm rustup-init && \
    source $HOME/.cargo/env && \
    cargo install cargo-binutils && \
    rustup component add llvm-tools-preview && \
    rustup component add rust-src && \
    rustup toolchain install nightly && \
    rustup target add riscv64gc-unknown-none-elf


RUN git clone  https://gitee.com/mirrors/riscv-gnu-toolchain \
&& cd riscv-gnu-toolchain \
&& git clone --depth 1 https://gitee.com/mirrors/riscv-dejagnu \
&& git clone --depth 1 -b riscv-gcc-12.1.0 https://gitee.com/mirrors/riscv-gcc \
&& git clone --depth 1 -b riscv-glibc-2.31 https://gitee.com/mirrors/riscv-glibc \
&& git clone --depth 1 -b riscv-newlib-3.2.0 https://gitee.com/mirrors/riscv-newlib \
&& git clone --depth 1 -b riscv-binutils-2.38 https://gitee.com/mirrors/riscv-binutils-gdb  riscv-binutils \
&& git clone --depth 1 -b fsf-gdb-10.1-with-sim https://gitee.com/mirrors/riscv-binutils-gdb  riscv-gdb \
&& apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev \
&& mkdir build \
&& cd build \
&& ../configure --prefix=$RISCV \
&& sed -i -e '5cGCC_SRCDIR := $(srcdir)/riscv-gcc' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '6cBINUTILS_SRCDIR := $(srcdir)/riscv-binutils' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '7cNEWLIB_SRCDIR := $(srcdir)/riscv-newlib' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '8cGLIBC_SRCDIR := $(srcdir)/riscv-glibc' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '9cMUSL_SRCDIR := $(srcdir)/riscv-musl' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '11cGDB_SRCDIR := $(srcdir)/riscv-gdb' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '16cDEJAGNU_SRCDIR := $(srcdir)/riscv-dejagnu' /root/riscv-gnu-toolchain/build/Makefile \ 
&& sed -i -e '17cDEJAGNU_SRCDIR := $(srcdir)/riscv-dejagnu' /root/riscv-gnu-toolchain/build/Makefile \ 
&& make -j4

