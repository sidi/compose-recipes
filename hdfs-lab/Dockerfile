FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

ARG HADOOP_VERSION=3.4.0
ARG HIVE_VERSION=4.0.0
ARG PG_JDBC_VERSION=42.7.4

# Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-8-jdk \
    openssh-client openssh-server \
    wget curl ca-certificates \
    python3 \
    postgresql-client \
    net-tools iproute2 procps \
    sed \
 && rm -rf /var/lib/apt/lists/*

# Detect JAVA_HOME (robust across Ubuntu/JDK layouts)
# We compute it from javac location, then store it in a system-wide file for later layers.
RUN JAVA_HOME_DETECTED="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" \
 && echo "Detected JAVA_HOME=${JAVA_HOME_DETECTED}" \
 && echo "${JAVA_HOME_DETECTED}" > /etc/java_home_detected

# Create user + dirs
RUN useradd -m -s /bin/bash hdoop \
 && mkdir -p /opt/hadoop /opt/hive \
 && chown -R hdoop:hdoop /opt/hadoop /opt/hive \
 && mkdir -p /var/run/sshd

# Download Hadoop
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
 && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt/hadoop --strip-components=1 \
 && rm -f hadoop-${HADOOP_VERSION}.tar.gz \
 && chown -R hdoop:hdoop /opt/hadoop

# Download Hive
RUN wget -q https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
 && tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt/hive --strip-components=1 \
 && rm -f apache-hive-${HIVE_VERSION}-bin.tar.gz \
 && chown -R hdoop:hdoop /opt/hive

# PostgreSQL JDBC driver for Hive metastore
RUN wget -q https://jdbc.postgresql.org/download/postgresql-${PG_JDBC_VERSION}.jar \
 && mv postgresql-${PG_JDBC_VERSION}.jar /opt/hive/lib/ \
 && chown hdoop:hdoop /opt/hive/lib/postgresql-${PG_JDBC_VERSION}.jar

# Set JAVA_HOME from detected value (this becomes the image default)
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN JAVA_HOME_DETECTED="$(cat /etc/java_home_detected)" \
 && echo "export JAVA_HOME=${JAVA_HOME_DETECTED}" > /etc/profile.d/java_home.sh \
 && chmod 0644 /etc/profile.d/java_home.sh

# Global env (non-login shells)
ENV HADOOP_HOME=/opt/hadoop \
    HIVE_HOME=/opt/hive
ENV PATH=/opt/hadoop/bin:/opt/hadoop/sbin:/opt/hive/bin:$PATH

# Make Hadoop/Hive available to login shells (su - hdoop), using detected JAVA_HOME
RUN JAVA_HOME_DETECTED="$(cat /etc/java_home_detected)" \
 && tee /etc/profile.d/hadoop_hive.sh >/dev/null <<EOF
export HADOOP_HOME=/opt/hadoop
export HIVE_HOME=/opt/hive
export JAVA_HOME=${JAVA_HOME_DETECTED}
export PATH=\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$HIVE_HOME/bin:\$PATH
EOF
RUN chmod 0644 /etc/profile.d/hadoop_hive.sh

# Ensure hdoop sources the env scripts
RUN echo 'source /etc/profile.d/hadoop_hive.sh' >> /home/hdoop/.profile \
 && echo 'source /etc/profile.d/hadoop_hive.sh' >> /home/hdoop/.bashrc \
 && chown hdoop:hdoop /home/hdoop/.profile /home/hdoop/.bashrc

# Set JAVA_HOME in Hadoop's own env file
RUN JAVA_HOME_DETECTED="$(cat /etc/java_home_detected)" \
 && echo "export JAVA_HOME=${JAVA_HOME_DETECTED}" >> /opt/hadoop/etc/hadoop/hadoop-env.sh

# Config files
COPY conf/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
COPY conf/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
COPY conf/mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml
COPY conf/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml

COPY conf/hive-site.xml.template /opt/hive/conf/hive-site.xml.template

# Hive logs
RUN mkdir -p /opt/hive/logs \
 && cp /opt/hive/conf/hive-log4j2.properties.template /opt/hive/conf/hive-log4j2.properties \
 && sed -i 's|^property.hive.log.dir *=.*|property.hive.log.dir = /opt/hive/logs|' /opt/hive/conf/hive-log4j2.properties \
 && chown -R hdoop:hdoop /opt/hive/logs /opt/hive/conf/hive-log4j2.properties

# SSH config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
 && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
 && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# HDFS dirs
RUN mkdir -p /home/hdoop/tmpdata \
             /home/hdoop/dfsdata/namenode \
             /home/hdoop/dfsdata/datanode \
             /home/hdoop/apps \
             /home/hdoop/yarn/local \
             /home/hdoop/yarn/logs \
 && chown -R hdoop:hdoop /home/hdoop

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9870 8088 9000 10000 9083 8042

CMD ["/entrypoint.sh"]
