# Analogous to jupyter/notebook, based on CC7.
# Installs Jupyter Notebook and IPython kernel from the current branch.
# Another Docker container should inherit with `FROM cernphsft/notebook`
# to run actual services.

FROM gitlab-registry.cern.ch/linuxsupport/cc7-base:20230801-1.x86_64

LABEL maintainer="swan-admins@cern.ch"

# Not essential, but wise to set the lang.
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8

# Install developer tools
# Install Latex packages (needed to convert notebooks to PDF)
RUN curl -sL https://rpm.nodesource.com/setup_12.x | bash - && \
    yum -y update && \
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
        openssl-devel \
        patch \
        sqlite-devel \
        unzip \
        wget \
        which \
        zeromq3-devel \
        zlib-devel \
        perl-Digest-MD5 \
        fontconfig && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install a newer version of pandoc, than the one available in yum repos
# For converting markdown to formats other than HTML
RUN mkdir /tmp/pandoc && \
    cd /tmp/pandoc && \
    wget --quiet https://github.com/jgm/pandoc/releases/download/2.3.1/pandoc-2.3.1-linux.tar.gz && \
    tar xvzf pandoc-2.3.1-linux.tar.gz --strip-components 1 -C /usr/local/ && \
    rm -rf /tmp/pandoc

# Install a newer version of TeX Live, than the one available in yum repos
# For converting to PDF
ENV PATH /usr/local/texlive/2023/bin/x86_64-linux/:$PATH
RUN mkdir /tmp/texlive && \
    cd /tmp/texlive && \
    wget --quiet http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar xvzf install-tl-unx.tar.gz --strip-components 1 -C ./ && \
    echo "I" | ./install-tl -scheme scheme-small && \
    tlmgr install   adjustbox \
                    tcolorbox \
                    environ \
                    trimspaces \
                    adjustbox \
                    collectbox \
                    ucs \
                    titling \
                    enumitem \
                    type1cm \
                    cm-super \
                    collection-fontsrecommended && \
    rm -rf /tmp/texlive

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.19.0/tini && \
    echo "93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Install Python 3
RUN mkdir /tmp/pytmp && \
    cd /tmp/pytmp && \
    wget https://www.python.org/ftp/python/3.9.6/Python-3.9.6.tgz && \
    tar xzvf Python-3.9.6.tgz && \
    cd /tmp/pytmp/Python-3.9.6 && \
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

RUN pip3 --no-cache-dir install \
            'ipyparallel==6.3.0' \
            'notebook==6.4.2' \
            'jupyterhub==4.0.2' \
            'jupyterlab==3.0.17' \
            'jupyter_nbextensions_configurator' \
            'voila'

VOLUME /notebooks
WORKDIR /notebooks

EXPOSE 8888

ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "notebook"]

