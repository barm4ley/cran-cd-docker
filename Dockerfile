FROM debian:jessie

# ===== COMMON =====

# remove several traces of debian python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libsqlite3-0 \
        libssl1.0.0 \
    && rm -rf /var/lib/apt/lists/*


RUN set -x \
    && buildDeps=' \
        curl \
        gcc \
        libbz2-dev \
        libc6-dev \
        libncurses-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        make \
        xz-utils \
        zlib1g-dev \
        openjdk-7-jre-headless \
        vim ' \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends

RUN rm -rf /var/lib/apt/lists/*


# ===== PYTHON 2 =====

ENV PYTHON_VERSION 2.7.10

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 7.1.0


RUN mkdir -p /usr/src/python \
    && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
    && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz* \
    && cd /usr/src/python \
    && ./configure --enable-shared --enable-unicode=ucs4 \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
    && pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
    && find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && rm -rf /usr/src/python

RUN pip install --no-cache-dir -U pip
# install "virtualenv", since the vast majority of users of this image will want it
RUN pip install --no-cache-dir virtualenv
RUN pip install --no-cache-dir mercurial


# ===== PYTHON 3 =====

ENV PYTHON_VERSION 3.4.3

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 7.1.0

RUN mkdir -p /usr/src/python \
    && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
    && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz* \
    && cd /usr/src/python \
    && ./configure --enable-shared --enable-unicode=ucs4 \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && pip3 install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
    && find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && rm -rf /usr/src/python

RUN pip3 install --no-cache-dir -U pip


# ===== MONGO DB =====

ENV MONGO_VERSION 2.6.11

RUN curl -SL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz" -o mongo.tgz \
    && curl -SL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz.sig" -o mongo.tgz.sig \
    && tar -xvf mongo.tgz -C /usr/local --strip-components=1 \
    && rm mongo.tgz*

VOLUME /data/db


# ===== JENKINS =====

ADD http://mirrors.jenkins-ci.org/war/1.624/jenkins.war /opt/jenkins.war

RUN chmod 644 /opt/jenkins.war

ENV JENKINS_HOME /jenkins
ENV JENKINS_USER maxim

RUN groupadd $JENKINS_USER && useradd --create-home --home-dir /home/$JENKINS_USER -g $JENKINS_USER $JENKINS_USER

RUN mkdir -p /var/lib/jenkins   && chown -R $JENKINS_USER:$JENKINS_USER /var/lib/jenkins
RUN mkdir -p /var/cache/jenkins && chown -R $JENKINS_USER:$JENKINS_USER /var/cache/jenkins
RUN mkdir -p /var/log/jenkins   && chown -R $JENKINS_USER:$JENKINS_USER /var/log/jenkins

RUN ln -s /jenkins /home/$JENKINS_USER/.jenkins


# ===== RUNTIME =====

USER $JENKINS_USER
ENTRYPOINT ["java", "-jar", "/opt/jenkins.war"]
EXPOSE 8080
CMD [""]
