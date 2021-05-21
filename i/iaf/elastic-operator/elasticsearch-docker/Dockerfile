######################################################### {COPYRIGHT-TOP} ###
# IBM Confidential
# OCO Source Materials
# 5900-AEO
#
# Copyright IBM Corp. 2020, 2021
#
# The source code for this program is not published or otherwise
# divested of its trade secrets, irrespective of what has been
# deposited with the U.S. Copyright Office.
######################################################### {COPYRIGHT-END} ###
ARG SECURITY_PLUGIN_IMAGE=us.icr.io/abp-builds/elastic-security-plugin@sha256:b8de64d53213700d6536ccf70af38d095bb154b558380308b6d515fe3a210e8c
FROM ${SECURITY_PLUGIN_IMAGE} as plugin

FROM registry.access.redhat.com/ubi8/ubi-minimal as elasticbuild

COPY elasticsearch_7.8.0_ubi8_minimal.sh /root
COPY elasticsearch_7.8.0.patch /root

RUN set -eux \
    && chmod +x /root/elasticsearch_7.8.0_ubi8_minimal.sh \
    && /root/elasticsearch_7.8.0_ubi8_minimal.sh

RUN mkdir /ElasticSearch && cp /root/elasticsearch/distribution/archives/oss-no-jdk-ppc64le-tar/build/distributions/elasticsearch-oss-7.8.0-SNAPSHOT-no-jdk-linux-ppc64le.tar.gz /ElasticSearch/

FROM us.icr.io/abp-ubi8/iaf-minimal:latest

# Java jdk-11.0.9+11 (Hotspot) JDK details
# ARG JAVA_ESUM='fc8af86bc0cff91e1f96860d22a9611fdaa74a53d68f88ffb887d998593370a1'
# ARG JAVA_BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.9%2B11/OpenJDK11U-jdk_x64_linux_hotspot_11.0.9_11.tar.gz'
ARG JAVA_ESUM='d206a63cd719b65717f7f20ee3fe49f0b8b2db922986b4811c828db57212699e'
ARG JAVA_BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.8_10.tar.gz'

# ENV ES_VERSION=7.8.0 \
    # ES_HOME=/usr/share/elasticsearch \
    # JAVA_VERSION=jdk-11.0.9+11 \
    # JAVA_HOME=/opt/java/openjdk
ENV ES_VERSION=7.8.0 \
    ES_HOME=/usr/share/elasticsearch \
    JAVA_VERSION=jdk-11.0.8+10 \
    JAVA_HOME=/opt/java/openjdk

ENV PATH="${ES_HOME}/bin:/opt/java/openjdk/bin:$PATH" \
    ES_STORAGE=${ES_HOME}/storage \
    ES_PATH_CONF=${ES_HOME}/config

COPY --from=plugin /project/target/releases/security-plugin-0.0.1-SNAPSHOT.zip ${ES_HOME}/security-plugin-0.0.1-SNAPSHOT.zip
COPY --from=elasticbuild /ElasticSearch/elasticsearch-oss-7.8.0-SNAPSHOT-no-jdk-linux-ppc64le.tar.gz .

COPY log4j2.audit.properties log4j2.audit.properties

RUN set -eux \
    # Install openjdk & other utils
    && curl -LfsSo /tmp/openjdk.tar.gz ${JAVA_BINARY_URL} \
    && echo "${JAVA_ESUM} */tmp/openjdk.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/java/openjdk \
    && tar -xf /tmp/openjdk.tar.gz -C /opt/java/openjdk --strip-components=1 \
    && rm -rf /tmp/openjdk.tar.gz \
    && microdnf install util-linux shadow-utils tar gzip --nodocs \
    && microdnf clean all \
    # Install ElasticSearch
    && mkdir -p ${ES_HOME} \
    # && curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-${ES_VERSION}-no-jdk-linux-x86_64.tar.gz \
    # && tar -xf elasticsearch-oss-${ES_VERSION}-no-jdk-linux-x86_64.tar.gz -C ${ES_HOME} --strip-components 1 \
    && tar -xf elasticsearch-oss-${ES_VERSION}-SNAPSHOT-no-jdk-linux-ppc64le.tar.gz -C ${ES_HOME} --strip-components 1 \
    # && rm elasticsearch-oss-${ES_VERSION}-no-jdk-linux-x86_64.tar.gz \
    && rm elasticsearch-oss-${ES_VERSION}-SNAPSHOT-no-jdk-linux-ppc64le.tar.gz \
    && curl -L https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.1/jna-4.5.1.jar -o jna-4.5.1.jar \
    && mv -f jna-4.5.1.jar ${ES_HOME}/lib \
    # && curl -kL https://github.com/mikefarah/yq/releases/download/3.3.4/yq_linux_amd64 -o /usr/local/bin/yq \
    && curl -kL https://github.com/mikefarah/yq/releases/download/3.3.4/yq_linux_ppc64le -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && groupadd --gid 1000 elasticsearch \
    && useradd elasticsearch -u 1000 -g root -G elasticsearch \
    && echo > ${ES_PATH_CONF}/elasticsearch.yml \
    # Fixed config MUST use the dot-separated key form, to allow subsequent merging with user config to work
    && echo "path.data: ${ES_STORAGE}/data" >> ${ES_PATH_CONF}/elasticsearch.yml \
    && echo "path.logs: ${ES_STORAGE}/logs" >> ${ES_PATH_CONF}/elasticsearch.yml \
    && echo "action.destructive_requires_name: true" >> ${ES_PATH_CONF}/elasticsearch.yml \
    && cat log4j2.audit.properties >> ${ES_PATH_CONF}/log4j2.properties \
    && rm log4j2.audit.properties \
    # Remove the default JVM heap values to enable JVM container support
    && sed -i -e 's/-Xms1g/#-Xms1g/g' -e 's/-Xmx1g/#-Xmx1g/g' ${ES_PATH_CONF}/jvm.options \
    # Add in default values for the initial and max heap percentage of available RAM
    && echo "9-:-XX:MaxRAMPercentage=25" >> ${ES_PATH_CONF}/jvm.options \
    && echo "9-:-XX:InitialRAMPercentage=25" >> ${ES_PATH_CONF}/jvm.options \
    && chgrp -R 0 ${ES_HOME} \
    && chmod -R g=u ${ES_HOME} \
    && ${ES_HOME}/bin/elasticsearch-plugin install --batch file:///${ES_HOME}/security-plugin-0.0.1-SNAPSHOT.zip

WORKDIR ${ES_HOME}
COPY run.sh run.sh
COPY live.sh bin/
USER 1000
ENTRYPOINT ["./run.sh"]

