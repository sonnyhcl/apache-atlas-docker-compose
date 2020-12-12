FROM maven:3.5.4-jdk-8 AS stage-atlas

ENV ATLAS_VERSION "3.0.0-e44eb9d64"
ARG ATLAS_BRANCH=branch-2.0
ENV TARBALL apache-atlas-${ATLAS_VERSION}-sources.tar.gz
ENV	ATLAS_REPO      https://dist.apache.org/repos/dist/release/atlas/${ATLAS_VERSION}/${TARBALL}
ENV	MAVEN_OPTS	"-Xms2g -Xmx2g"

RUN git clone http://github.com/apache/atlas.git \
	&& cd atlas \
	&& git checkout $ATLAS_BRANCH \
	&& mvn clean -DskipTests package -Pdist,embedded-hbase-solr \
	&& mv distro/target/apache-atlas-*-bin.tar.gz /apache-atlas.tar.gz

FROM centos:7

COPY --from=stage-atlas /apache-atlas.tar.gz /apache-atlas.tar.gz

RUN yum update -y \
	&& yum install -y python python36 java-1.8.0-openjdk java-1.8.0-openjdk-devel net-tools \
	&& yum clean all
RUN groupadd hadoop && \
	useradd -m -d /opt/atlas -g hadoop atlas


RUN pip3 install amundsenatlastypes

USER atlas

RUN cd /opt \
	&& tar xzf /apache-atlas.tar.gz -C /opt/atlas --strip-components=1

COPY model /tmp/model
COPY resources/atlas-setup.sh /tmp
COPY resources/credentials /tmp
COPY resources/init_amundsen.py /tmp

COPY resources/atlas-application.properties /opt/atlas/conf/

USER root
ADD resources/entrypoint.sh /entrypoint.sh
RUN rm -rf /apache-atlas.tar.gz

USER atlas

ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]

EXPOSE 21000
