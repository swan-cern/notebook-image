
# Analogous to jupyter/notebook, based on CC7.
# Installs Jupyter Notebook and IPython kernel from the current branch.
# Another Docker container should inherit with `FROM cernphsft/notebook`
# to run actual services.

FROM cern/cc7-base

MAINTAINER Enric Tejedor Saavedra <enric.tejedor.saavedra@cern.ch>

# Not essential, but wise to set the lang
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Python binary dependencies, developer tools
RUN yum -y update; exit 0 
RUN yum -y install \
    gcc \
    gcc-c++ \
    kernel-devel \
    make \
    zlib-devel \
    git \
    python-devel \
    python-pip \
    python-sphinx \
    python34-devel \
    zeromq3-devel \
    sqlite \
    sqlite-devel \
    pandoc \
    libcurl-openssl-devel \
    nodejs \
    npm \
    wget

RUN ln -s /usr/bin/python3.4 /usr/bin/python3

# Install pip3
WORKDIR /usr/local/src
RUN wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py
RUN python3 ez_setup.py
RUN easy_install-3.4 pip

# Upgrade setuptools and pip
RUN pip2 install --upgrade setuptools pip
RUN pip3 install --upgrade setuptools pip

# Install sphinx3
RUN pip3 install sphinx

# Install Jupyter Notebook and IPython kernels
RUN mkdir -p /srv/
WORKDIR /srv/
RUN git clone --depth 1 https://github.com/ipython/ipykernel /srv/ipykernel
WORKDIR /srv/ipykernel
RUN pip2 install --pre -e .
RUN pip3 install --pre -e .

RUN git clone https://github.com/jupyter/notebook /srv/notebook
WORKDIR /srv/notebook/
RUN chmod -R +rX /srv/notebook

RUN pip3 install -e .[test]

RUN python2 -m ipykernel.kernelspec
RUN python3 -m ipykernel.kernelspec

# Run Notebook tests
WORKDIR /tmp/
RUN nosetests notebook

