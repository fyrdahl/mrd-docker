FROM python:3.12-slim-bookworm AS build
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    g++ make cmake ninja-build  git ca-certificates \
    libhdf5-serial-dev h5utils cmake libboost-all-dev \
    libboost-all-dev xsdcxx libxerces-c-dev \
    libhdf5-serial-dev h5utils hdf5-tools \
    libtinyxml-dev libxml2-dev libxslt1-dev libpugixml-dev && \
    rm -rf /var/lib/apt/lists/*

RUN  mkdir -p /opt/code

# ISMRMRD library
RUN cd /opt/code && \
    git clone https://github.com/ismrmrd/ismrmrd.git -b v1.14.1 && \
    cd /opt/code/ismrmrd && \
    mkdir build && \
    cd build && \
    cmake -G Ninja ../ && \
    ninja && \
    ninja install && \
    rm -rf /opt/code/ismrmrd && \
    cd /usr/local/lib && \
    tar -czvf libismrmrd.tar.gz libismrmrd*

# siemens_to_ismrmrd
RUN cd /opt/code && \
    git clone https://github.com/ismrmrd/siemens_to_ismrmrd.git && \
    cd /opt/code/siemens_to_ismrmrd && \
    mkdir build && \
    cd build && \
    cmake -G Ninja ../ && \
    ninja && \
    ninja install && \
    rm -rf /opt/code/siemens_to_ismrmrd

# Clone from GitHub
RUN cd /opt/code && \
    git clone https://github.com/ismrmrd/ismrmrd-python-tools && \
    git clone https://github.com/kspaceKelvin/python-ismrmrd-server

FROM python:3.12-slim-bookworm
ARG DEBIAN_FRONTEND=noninteractive
COPY --from=build /usr/local/bin/siemens_to_ismrmrd /usr/local/bin/
COPY --from=build /usr/local/lib/libismrmrd.tar.gz /usr/local/lib/
COPY --from=build /opt/code /opt/code

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    libboost-all-dev xsdcxx libxerces-c-dev libhdf5-serial-dev h5utils \
    hdf5-tools libtinyxml-dev libxml2-dev libxslt1-dev libpugixml1v5 && \
    rm -rf /var/lib/apt/lists/*

RUN cd /usr/local/lib && \
    tar -zxvf libismrmrd.tar.gz && \
    rm -f libismrmrd.tar.gz && \
    ldconfig

RUN python3 -m pip install -U pip && \
    python3 -m pip --no-cache-dir install pyxb-x h5py numpy scipy ismrmrd pillow pydicom pynetdicom && \
    python3 -m pip --no-cache-dir install /opt/code/ismrmrd-python-tools/

WORKDIR /tmp
ADD extras.tar.gz .

ENTRYPOINT ["/bin/bash"]
