# Copyright (c) Alton Barbehenn.
# In part based on the Jupyter Development Team's jupyter/pyspark-notebook 
# (accessed on DockerHub July 9, 2019)

FROM ubuntu:18.04


MAINTAINER barbehe2@illinois.edu


USER root


# Needed to properly handle UTF-8
ENV PYTHONIOENCODING=UTF-8


# relevant versions to install
ENV APACHE_SPARK_VERSION 2.4.3
ENV HADOOP_VERSION 2.7


# Install Java 8 JDK and other prerequisites
# Also install python 3.7
RUN apt-get update && \
	apt-get install -y --no-install-recommends apt-utils
RUN apt-get update --fix-missing 
RUN apt-get install -y openjdk-8-jdk \
	software-properties-common \
	python3.7 python3-pip \
	sudo \
	make \
	wget


# Set up Python 3.7 and set it as default python3 and python
RUN ln -sf /usr/bin/python3.7 /usr/bin/python3 && \
	ln -s /usr/bin/python3.7 /usr/bin/python && \
	ln -s /usr/bin/pip3 /usr/bin/pip


# Install native Hadoop library
RUN cd /tmp && \
	wget -q https://www-us.apache.org/dist/hadoop/common/hadoop-2.7.6/hadoop-2.7.6.tar.gz && \
	tar xzf hadoop-2.7.6.tar.gz -C /usr/local/ && \
	ln -s /usr/local/hadoop-2.7.6 /usr/local/hadoop && \
	rm hadoop-2.7.6.tar.gz


# Set enviromental variables 
ENV HADOOP_HOME /usr/local/hadoop
ENV LD_LIBRARY_PATH $HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
ENV PATH $HADOOP_HOME/bin:$PATH


# Install Spark and Hadoop 
# starting from https://spark.apache.org/downloads.html
RUN cd /tmp && \
    wget -q http://mirror.cogentco.com/pub/apache/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    echo "E8B7F9E1DEC868282CADCAD81599038A22F48FB597D44AF1B13FCC76B7DACD2A1CAF431F95E394E1227066087E3CE6C2137C4ABAF60C60076B78F959074FF2AD *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark


# Set enviromental variables 
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip
ENV PATH $SPARK_HOME/bin:$PATH


# Copy custom jars to enable Spark-Azure connection
COPY jars/* $SPARK_HOME/jars/


# Get list of python libraries
COPY requirements.txt /


# Install python libraries
RUN python3 -m pip install --no-cache-dir -r /requirements.txt


# Start notebook with `jupyter notebook --ip=0.0.0.0`


# Install PostgreSQL 
# example Dockerfile for https://docs.docker.com/engine/examples/postgresql_service/
# Needed to aviod entering timezone info when installing PostgreSQL (hide warnings on build)
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get install -y postgresql postgresql-contrib postgresql-server-dev-all
	

USER postgres


RUN /etc/init.d/postgresql start && \
	psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" && \
	createdb -O docker docker


# Add user for autograder (like the prairielearn/centos7-python image)
USER root
RUN useradd ag


# start postgresql
# need to run this when the image launches
# RUN service postgresql start
