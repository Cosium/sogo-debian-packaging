#!/usr/bin/env bash

set -e

echo "BASE_DIR=\"$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )\""
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Path to config file
echo "CONFIG_FILE=\"${BASE_DIR}/.env\""
CONFIG_FILE="${BASE_DIR}/.env"

if [ ! -f "$CONFIG_FILE" ] && [ -z ${CI+x} ]; then
    echo "Error: You need to create a .env file. See .env.example for reference."
    exit 1
fi

set -a
. "$CONFIG_FILE"
set +a

echo "REPOSITORY_SOGO=\"https://github.com/Alinto/sogo.git\""
REPOSITORY_SOGO="https://github.com/Alinto/sogo.git"
echo "REPOSITORY_SOPE=\"https://github.com/Alinto/sope.git\""
REPOSITORY_SOPE="https://github.com/Alinto/sope.git"
echo "SOGO_GIT_TAG=\"SOGo-${VERSION_TO_BUILD}\""
SOGO_GIT_TAG="SOGo-${VERSION_TO_BUILD}"
echo "SOPE_GIT_TAG=\"SOPE-${VERSION_TO_BUILD}\""
SOPE_GIT_TAG="SOPE-${VERSION_TO_BUILD}"

echo "PACKAGES_DIR=\"${BASE_DIR}/vendor\""
PACKAGES_DIR="${BASE_DIR}/vendor"
echo "PACKAGES_TO_INSTALL=\"python-is-python3 build-essential git zip wget make debhelper gnustep-make libssl-dev libgnustep-base-dev libldap2-dev libytnef0-dev zlib1g-dev libpq-dev libmariadbclient-dev-compat libmemcached-dev liblasso3-dev libcurl4-gnutls-dev devscripts libexpat1-dev libpopt-dev libsbjson-dev libsbjson2.3 libcurl4 liboath-dev libsodium-dev libzip-dev\""
PACKAGES_TO_INSTALL="python-is-python3 build-essential git zip wget make debhelper gnustep-make libssl-dev libgnustep-base-dev libldap2-dev libytnef0-dev zlib1g-dev libpq-dev libmariadbclient-dev-compat libmemcached-dev liblasso3-dev libcurl4-gnutls-dev devscripts libexpat1-dev libpopt-dev libsbjson-dev libsbjson2.3 libcurl4 liboath-dev libsodium-dev libzip-dev"

echo "export DEBIAN_FRONTEND=noninteractive"
export DEBIAN_FRONTEND=noninteractive

echo "cd $PACKAGES_DIR"
cd "$PACKAGES_DIR"

# Do not install recommended or suggested packages
echo "'APT::Get::Install-Recommends \"false\";' >> /etc/apt/apt.conf"
echo 'APT::Get::Install-Recommends "false";' >> /etc/apt/apt.conf
echo "'APT::Get::Install-Suggests \"false\";' >> /etc/apt/apt.conf"
echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf

# Install required packages
echo "apt update && apt install -y $PACKAGES_TO_INSTALL"
apt update && apt install -y $PACKAGES_TO_INSTALL

# Download and install libwbxml2 and libwbxml2-dev
wget -c https://packages.sogo.nu/nightly/5/debian/pool/bullseye/w/wbxml2/libwbxml2-dev_0.11.8-1_amd64.deb
wget -c https://packages.sogo.nu/nightly/5/debian/pool/bullseye/w/wbxml2/libwbxml2-0_0.11.8-1_amd64.deb

dpkg -i libwbxml2-0_0.11.8-1_amd64.deb libwbxml2-dev_0.11.8-1_amd64.deb

# Install any missing packages
echo "apt -f install -y"
apt -f install -y

# Checkout the SOPE repository with the given tag
echo "rm -rf sope"
rm -rf sope
echo "clone --depth 1 --branch ${SOPE_GIT_TAG} $REPOSITORY_SOPE"
git clone --depth 1 --branch "${SOPE_GIT_TAG}" $REPOSITORY_SOPE

echo "cd sope"
cd sope

echo "cp -a packaging/debian debian"
cp -a packaging/debian debian

echo "dch --newversion \"4.9.r1664.$VERSION_TO_BUILD\" \"Automated build for version 4.9.r1664.$VERSION_TO_BUILD\""
dch --newversion "$VERSION_TO_BUILD" "Automated build for version $VERSION_TO_BUILD"

echo "./debian/rules"
./debian/rules

echo "dpkg-checkbuilddeps && dpkg-buildpackage"
dpkg-checkbuilddeps && dpkg-buildpackage

echo "cd $PACKAGES_DIR"
cd "$PACKAGES_DIR"

# Install the built packages
echo "dpkg -i libsope*.deb"
dpkg -i libsope*.deb

# Checkout the SOGo repository with the given tag
echo "rm -rf sogo"
rm -rf sogo
echo "git clone --depth 1 --branch ${SOGO_GIT_TAG} $REPOSITORY_SOGO"
git clone --depth 1 --branch "${SOGO_GIT_TAG}" $REPOSITORY_SOGO
echo "cd sogo"
cd sogo

echo "cp -a packaging/debian debian"
cp -a packaging/debian debian

echo "dch --newversion \"$VERSION_TO_BUILD\" \"Automated build for version $VERSION_TO_BUILD\""
dch --newversion "$VERSION_TO_BUILD" "Automated build for version $VERSION_TO_BUILD"

echo "./debian/rules"
./debian/rules

echo "dpkg-checkbuilddeps && dpkg-buildpackage -b"
dpkg-checkbuilddeps && dpkg-buildpackage -b

echo "cd $PACKAGES_DIR"
cd "$PACKAGES_DIR"

# Install the built packages
echo "dpkg -i \"sope4.9-appserver_${VERSION_TO_BUILD}_amd64.deb\""
dpkg -i "sope4.9-appserver_${VERSION_TO_BUILD}_amd64.deb"
echo "dpkg -i \"sope4.9-gdl1-${SOGO_DATABASE_ENGINE}_${VERSION_TO_BUILD}_amd64.deb\""
dpkg -i "sope4.9-gdl1-${SOGO_DATABASE_ENGINE}_${VERSION_TO_BUILD}_amd64.deb"
echo "dpkg -i \"sope4.9-libxmlsaxdriver_${VERSION_TO_BUILD}_amd64.deb\""
dpkg -i "sope4.9-libxmlsaxdriver_${VERSION_TO_BUILD}_amd64.deb"
echo "dpkg -i \"sope4.9-stxsaxdriver_${VERSION_TO_BUILD}_amd64.deb\""
dpkg -i "sope4.9-stxsaxdriver_${VERSION_TO_BUILD}_amd64.deb"
echo "dpkg -i \"sogo_${VERSION_TO_BUILD}_amd64.deb\""
dpkg -i "sogo_${VERSION_TO_BUILD}_amd64.deb"
echo "dpkg -i \"sogo-activesync_${VERSION_TO_BUILD}_amd64.deb\""
dpkg -i "sogo-activesync_${VERSION_TO_BUILD}_amd64.deb"
