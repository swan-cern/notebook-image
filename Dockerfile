
# Analogous to jupyter/notebook, based on SLC6.
# Installs Jupyter Notebook and IPython kernel from the current branch.
# Another Docker container should inherit with `FROM cernphsft/notebook`
# to run actual services.

FROM cern/slc6-base

MAINTAINER Enric Tejedor Saavedra <enric.tejedor.saavedra@cern.ch>

# Not essential, but wise to set the lang
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8

# Install developer tools
RUN yum -y update 
RUN yum -y install \
    gcc \
    gcc-c++ \
    git \
    kernel-devel \
    libcurl-openssl-devel \
    libffi-devel \
    ncurses-devel \
    nodejs \
    npm \
    pandoc \
    patch \
    sqlite-devel \
    tar \
    texlive-latex \
    texlive-texmf-fonts \
    wget \
    zeromq3-devel \
    zlib-devel

# Install Tini
RUN curl -L https://github.com/krallin/tini/releases/download/v0.6.0/tini > tini && \
    echo "d5ed732199c36a1189320e6c4859f0169e950692f451c03e7854243b95f4234b *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Install Python 2.7
RUN mkdir /tmp/pytmp
WORKDIR /tmp/pytmp
RUN wget http://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz && \
    tar xvzf Python-2.7.10.tgz
WORKDIR /tmp/pytmp/Python-2.7.10
RUN ./configure --enable-shared && \
    make install
ENV LD_LIBRARY_PATH /usr/local/lib/:$LD_LIBRARY_PATH

# Install Python 3
WORKDIR /tmp/pytmp
RUN wget https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz && \
    tar xzvf Python-3.5.0.tgz
WORKDIR /tmp/pytmp/Python-3.5.0
RUN ./configure --enable-shared && \
    make install

# Cleanup
RUN rm -rf /tmp/pytmp

# Install the recent pip release
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip2 --no-cache-dir install requests[security] && \
    pip3 --no-cache-dir install requests[security]

# Install some dependencies
RUN pip2 --no-cache-dir install ipykernel && \
    pip3 --no-cache-dir install ipykernel && \
    \
    python2 -m ipykernel.kernelspec && \
    python3 -m ipykernel.kernelspec

# Move notebook contents into place
RUN JSRCDIR=/usr/src/jupyter-notebook && \
    mkdir $JSRCDIR && \
    git clone https://github.com/jupyter/notebook $JSRCDIR

# Install dependencies and run tests
RUN pip2 install --no-cache-dir readline mock nose requests testpath && \
    pip3 install --no-cache-dir --pre -e /usr/src/jupyter-notebook && \
    pip3 install --no-cache-dir readline nose requests testpath && \
    \
    iptest2 && iptest3 && \
    \
    pip2 uninstall -y funcsigs mock nose pbr requests six testpath && \
    pip3 uninstall -y nose requests testpath

# Add a notebook profile
RUN mkdir -p -m 700 /root/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> /root/.jupyter/jupyter_notebook_config.py

VOLUME /notebooks
WORKDIR /notebooks

EXPOSE 8888

ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "notebook"]
