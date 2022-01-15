FROM python:3.10.1-buster
USER root

ARG pj_dpath=/root/

ADD requirements.txt $pj_dpath

WORKDIR $pj_dpath

RUN apt-get update && apt-get install -y \
        vim \
        less \
        locales \
    && localedef -f UTF-8 -i ja_JP ja_JP.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --upgrade \
        pip \
        setuptools \
    && pip install -r requirements.txt \
    && rm -rf ~/.pip/cache

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ JST-9
ENV TERM xterm-256color
