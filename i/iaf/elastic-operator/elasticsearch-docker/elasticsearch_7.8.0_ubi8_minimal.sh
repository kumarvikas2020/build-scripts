# ----------------------------------------------------------------------------
#
# Package       : elasticsearch
# Version       : 7.8.0
# Source repo   : https://github.com/elastic/elasticsearch.git
# Tested on     : ubi8 minimal
# Script License: Apache License Version 2.0
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

cd $HOME
WORKDIR=`pwd`   
ELASTICSEARCH_VERSION=7.8.0

# install dependencies
microdnf install -y wget sudo git tar

cd $WORKDIR

# install java 13
wget https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk13u-2020-02-24-07-25/OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz
tar -C /usr/local -xzf OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz
export JAVA_HOME=/usr/local/jdk-13.0.2+8/
export JAVA13_HOME=/usr/local/jdk-13.0.2+8/
export PATH=$PATH:/usr/local/jdk-13.0.2+8/bin
sudo ln -sf /usr/local/jdk-13.0.2+8/bin/java /usr/bin/

# build elasticsearch from source
cd $WORKDIR
git clone https://github.com/elastic/elasticsearch.git
cd elasticsearch && git checkout v$ELASTICSEARCH_VERSION
# wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/elasticsearch/elasticsearch_7.8.0.patch
git apply /root/elasticsearch_7.8.0.patch
mkdir -p distribution/archives/linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-linux-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle
mkdir -p distribution/archives/oss-no-jdk-ppc64le-tar
echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-no-jdk-ppc64le-tar/build.gradle
# ./gradlew :distribution:archives:oss-linux-ppc64le-tar:assemble --parallel
./gradlew :distribution:archives:oss-no-jdk-ppc64le-tar:assemble --parallel

