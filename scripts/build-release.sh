#!/bin/bash

set -e

BOSHV="$(bosh --version)"
if echo "$BOSHV" | grep -q "BOSH 1."; then
 echo "bosh is in version 1"
 BOSHVERSION=1
else
 echo "bosh is in version 2 or more."
 BOSHVERSION=2
fi


if [ "$0" != "./scripts/build-release.sh" ]; then
    echo "'build-release.sh' should be run from repository root"
    exit 1
fi

function usage(){
  >&2 echo "
 Usage:
    $0 [version]
 Ex:
    $0 0+dev.1
"
  exit 1
}

if [ "$1" == "-h" ] || [ "$1" == "--help"  ] || [ "$1" == "help"  ]; then
    usage
fi


if [ "$#" -gt 0 ]; then
    if [ -e "$1" ]; then
        export version=`cat $1`
    else
        export version=$1
    fi
fi

echo '################################################################################'
echo "Building sonarqube-boshrelese ${version}"
echo '################################################################################'
echo ''

echo '################################################################################'
echo 'Cleaning up blobs'
echo '################################################################################'
echo ''

rm -rf .blobs/* blobs/*
echo "--- {} " > config/blobs.yml

echo '################################################################################'
echo 'Downloading binaries'
echo '################################################################################'
echo ''

if [ ! -d './tmp' ]; then
  mkdir -p ./tmp/completed
fi

cd ./tmp

if [ -e './completed/jdk-8u131-linux-x64.tar.gz' ]; then
  echo 'httpd package already exists, skipping'
else
  echo 'Downloading file jdk-8u131-linux-x64.tar.gz'
   wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
  mv jdk-8u131-linux-x64.tar.gz completed/
fi

if [ -e './completed/sonarqube-6.5.zip' ]; then
  echo 'httpd package already exists, skipping'
else
  echo 'Downloading file sonarqube-6.5.zip'
  wget https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.5.zip
  mv sonarqube-6.5.zip completed/
fi

if [ -e './completed/sonar-findbugs-plugin.jar' ]; then
  echo 'httpd package already exists, skipping'
else
  echo 'Downloading file sonar-findbugs-plugin.jar'
  wget https://github.com/SonarQubeCommunity/sonar-findbugs/releases/download/3.5.0/sonar-findbugs-plugin.jar
  mv sonar-findbugs-plugin.jar completed/
fi

if [ -e './completed/sonar-dependency-check-plugin-1.0.3.jar' ]; then
  echo 'httpd package already exists, skipping'
else
  echo 'Downloading file sonar-dependency-check-plugin-1.0.3.jar'
  wget https://bintray.com/stevespringett/owasp/download_file?file_path=org%2Fsonarsource%2Fowasp%2Fsonar-dependency-check-plugin%2F1.0.3%2Fsonar-dependency-check-plugin-1.0.3.jar
  mv download_file?file_path=org%2Fsonarsource%2Fowasp%2Fsonar-dependency-check-plugin%2F1.0.3%2Fsonar-dependency-check-plugin-1.0.3.jar completed/sonar-dependency-check-plugin-1.0.3.jar
fi

if [ -e './completed/sonar-typescript-plugin-1.0.0.340.jar' ]; then
  echo 'httpd package already exists, skipping'
else
  echo 'Downloading file sonar-typescript-plugin-1.0.0.340.jar'
  wget https://sonarsource.bintray.com/Distribution/sonar-typescript-plugin/sonar-typescript-plugin-1.0.0.340.jar
  mv sonar-typescript-plugin-1.0.0.340.jar completed/
fi

cd -

echo ''
echo '################################################################################'
echo 'Adding blobs'
echo '################################################################################'
echo $BOSHVERSION 


echo ''

echo 'Adding blob java/jdk-8u131-linux-x64.tar.gz'
if [ "$BOSHVERSION" = "1" ]; then
 bosh add blob ./tmp/completed/jdk-8u131-linux-x64.tar.gz java
else
 bosh add-blob ./tmp/completed/jdk-8u131-linux-x64.tar.gz java/jdk-8u131-linux-x64.tar.gz
fi
echo 'Adding blob java/sonarqube-6.5.zip'
if [ "$BOSHVERSION" = "1" ]; then
 bosh add blob ./tmp/completed/sonarqube-6.5.zip sonarqube
else
 bosh add-blob ./tmp/completed/sonarqube-6.5.zip sonarqube/sonarqube-6.5.zip
fi


echo 'Adding blobs plugins'
if [ "$BOSHVERSION" = "1" ]; then
 bosh add blob ./tmp/completed/sonar-findbugs-plugin.jar plugins
 bosh add blob ./tmp/completed/sonar-dependency-check-plugin-1.0.3.jar plugins
 bosh add blob ./tmp/completed/sonar-typescript-plugin-1.0.0.340.jar plugins
else
 bosh add-blob ./tmp/completed/sonar-findbugs-plugin.jar plugins/sonar-findbugs-plugin.jar
 bosh add-blob ./tmp/completed/sonar-dependency-check-plugin-1.0.3.jar plugins/sonar-dependency-check-plugin-1.0.3.jar
 bosh add-blob ./tmp/completed/sonar-typescript-plugin-1.0.0.340.jar plugins/sonar-typescript-plugin-1.0.0.340.jar
fi


echo ''
echo '################################################################################'
echo 'Creating release'
echo '################################################################################'

echo ''

echo "Creating release"
if [ "$BOSHVERSION" = "1" ]; then
 create_cmd="bosh create release --name sonarqube --with-tarball --force"
else
 create_cmd="bosh create-release --name sonarqube --force"
fi

if [ -n "$version" ]; then
    create_cmd+=" --version "${version}""
fi

eval ${create_cmd}
