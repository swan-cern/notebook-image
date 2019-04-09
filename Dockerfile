# Analogous to jupyter/notebook, based on CC7.
# Installs Jupyter Notebook and IPython kernel from the current branch.
# Another Docker container should inherit with `FROM cernphsft/notebook`
# to run actual services.

FROM cern/cc7-base:20181210

MAINTAINER SWAN Admins <swan-admins@cern.ch>

# Not essential, but wise to set the lang.
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8

# Install developer tools
# Install Latex packages (needed to convert notebooks to PDF)
RUN yum -y update && \
    yum -y install \
        bzip2 \
        gcc \
        gcc-c++ \
        git \
        kernel-devel \
        libcurl-openssl-devel \
        libffi-devel \
        make \
        ncurses-devel \
        nano \
        nodejs \
        npm \
        openssl-devel \
        patch \
        sqlite-devel \
        unzip \
        wget \
        which \
        zeromq3-devel \
        zlib-devel \
        texlive-xetex \
        texlive-adjustbox.noarch \
        texlive-collection-latexrecommended.noarch \
        texlive-collection-xetex.noarch \
        texlive-upquote.noarch && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install a newer version of pandoc, than the one available in yum repos
# For converting markdown to formats other than HTML
RUN mkdir /tmp/pandoc && \
    cd /tmp/pandoc && \
    wget --quiet https://github.com/jgm/pandoc/releases/download/2.3.1/pandoc-2.3.1-linux.tar.gz && \
    tar xvzf pandoc-2.3.1-linux.tar.gz --strip-components 1 -C /usr/local/ && \
    rm -rf /tmp/pandoc

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Install Python 3
RUN mkdir /tmp/pytmp && \
    cd /tmp/pytmp && \
    wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tgz && \
    tar xzvf Python-3.6.1.tgz && \
    cd /tmp/pytmp/Python-3.6.1 && \
    ./configure --enable-shared && \
    make install && \
    rm -rf /tmp/pytmp

# Set up the LD_LIBRARY_PATH for Pip3 and Python3 to work
ENV LD_LIBRARY_PATH /usr/local/lib/
RUN echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /etc/environment

# Install the recent pip release
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

# Force tornado 5 as version 6 breaks jupyter
RUN pip3 --no-cache-dir install \
            'tornado==5.1.1' \
            'notebook==5.7.8' \
            'jupyterhub==0.9.6' \
            'jupyterlab==0.35.4' \
            'jupyter_nbextensions_configurator'

VOLUME /notebooks
WORKDIR /notebooks

EXPOSE 8888

ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "notebook"]

