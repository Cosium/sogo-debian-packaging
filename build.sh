#!/usr/bin/env bash

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
CONFIG_FILE="${BASE_DIR}/.env"

if [ ! -f "$CONFIG_FILE" ] && [ -z ${CI+x} ]; then
    echo "Error: You need to create a .env file. See .env.example for reference."
    exit 1
fi

set -a
. "$CONFIG_FILE"
set +a

REPOSITORY_SOGO="https://github.com/Alinto/sogo.git"
REPOSITORY_SOPE="https://github.com/Alinto/sope.git"
SOGO_GIT_TAG="SOGo-${VERSION_TO_BUILD}"
SOPE_GIT_TAG="SOPE-${VERSION_TO_BUILD}"
PACKAGES_DIR="${BASE_DIR}/vendor"
PACKAGES_TO_INSTALL="python-is-python3 build-essential git zip wget make debhelper gnustep-make libssl-dev libgnustep-base-dev libldap2-dev libytnef0-dev zlib1g-dev libpq-dev libmariadbclient-dev-compat libmemcached-dev liblasso3-dev libcurl4-gnutls-dev devscripts libexpat1-dev libpopt-dev libsbjson-dev libsbjson2.3 libcurl4 liboath-dev libsodium-dev libzip-dev"
export DEBIAN_FRONTEND=noninteractive

echo "==========="
echo "cd $PACKAGES_DIR"
echo "==========="
cd "$PACKAGES_DIR"

# Do not install recommended or suggested packages
echo "==========="
echo "'APT::Get::Install-Recommends \"false\";' >> /etc/apt/apt.conf"
echo "==========="
echo 'APT::Get::Install-Recommends "false";' >> /etc/apt/apt.conf

echo "==========="
echo "'APT::Get::Install-Suggests \"false\";' >> /etc/apt/apt.conf"
echo "==========="
echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf

# Install required packages
echo "==========="
echo "apt update && apt install -y $PACKAGES_TO_INSTALL"
echo "==========="
apt update && apt install -y $PACKAGES_TO_INSTALL

# Download and install libwbxml2 and libwbxml2-dev
echo "==========="
echo "wget -c https://packages.sogo.nu/nightly/5/debian/pool/bookworm/w/wbxml2/libwbxml2-dev_0.11.8-1_amd64.deb"
echo "==========="
wget -c https://packages.sogo.nu/nightly/5/debian/pool/bookworm/w/wbxml2/libwbxml2-dev_0.11.8-1_amd64.deb

echo "==========="
echo "wget -c https://packages.sogo.nu/nightly/5/debian/pool/bookworm/w/wbxml2/libwbxml2-0_0.11.8-1_amd64.deb"
echo "==========="
wget -c https://packages.sogo.nu/nightly/5/debian/pool/bookworm/w/wbxml2/libwbxml2-0_0.11.8-1_amd64.deb

echo "==========="
echo "dpkg -i libwbxml2-0_0.11.8-1_amd64.deb libwbxml2-dev_0.11.8-1_amd64.deb"
echo "==========="
dpkg -i libwbxml2-0_0.11.8-1_amd64.deb libwbxml2-dev_0.11.8-1_amd64.deb

# Install any missing packages
echo "==========="
echo "apt -f install -y"
echo "==========="
apt -f install -y

# Checkout the SOPE repository with the given tag
echo "==========="
echo "rm -rf sope"
echo "==========="
rm -rf sope

echo "==========="
echo "clone --depth 1 --branch ${SOPE_GIT_TAG} $REPOSITORY_SOPE"
echo "==========="
git clone --depth 1 --branch "${SOPE_GIT_TAG}" $REPOSITORY_SOPE

echo "==========="
echo "cd sope"
echo "==========="
cd sope

echo "==========="
echo "cp -a packaging/debian debian"
echo "==========="
cp -a packaging/debian debian

echo "==========="
echo "dch --newversion \"$VERSION_TO_BUILD\" \"Automated build for version $VERSION_TO_BUILD\""
echo "==========="
dch --newversion "$VERSION_TO_BUILD" "Automated build for version $VERSION_TO_BUILD"

echo "==========="
echo "./debian/rules"
echo "==========="
./debian/rules

echo "==========="
echo "dpkg-checkbuilddeps && dpkg-buildpackage"
echo "==========="
dpkg-checkbuilddeps && dpkg-buildpackage

echo "==========="
echo "cd $PACKAGES_DIR"
echo "==========="
cd "$PACKAGES_DIR"

# Install the built packages
echo "==========="
echo "dpkg -i libsope*.deb"
echo "==========="
dpkg -i libsope*.deb

# Checkout the SOGo repository with the given tag
echo "==========="
echo "rm -rf sogo"
echo "==========="
rm -rf sogo

echo "==========="
echo "git clone --depth 1 --branch ${SOGO_GIT_TAG} $REPOSITORY_SOGO"
echo "==========="
git clone --depth 1 --branch "${SOGO_GIT_TAG}" $REPOSITORY_SOGO

echo "==========="
echo "cd sogo"
echo "==========="
cd sogo

echo "==========="
echo "cp -a packaging/debian debian"
echo "==========="
cp -a packaging/debian debian

echo "==========="
echo "dch --newversion \"$VERSION_TO_BUILD\" \"Automated build for version $VERSION_TO_BUILD\""
echo "==========="
dch --newversion "$VERSION_TO_BUILD" "Automated build for version $VERSION_TO_BUILD"

echo "==========="
echo "./debian/rules"
echo "==========="
./debian/rules

echo "==========="
echo "dpkg-checkbuilddeps && dpkg-buildpackage -b"
echo "==========="
dpkg-checkbuilddeps && dpkg-buildpackage -b

echo "==========="
echo "cd $PACKAGES_DIR"
echo "==========="
cd "$PACKAGES_DIR"

# Install the built packages
echo "==========="
echo "dpkg -i \"sope4.9-appserver_${VERSION_TO_BUILD}_amd64.deb\""
echo "==========="
dpkg -i "sope4.9-appserver_${VERSION_TO_BUILD}_amd64.deb"

echo "==========="
echo "dpkg -i \"sope4.9-gdl1-${SOGO_DATABASE_ENGINE}_${VERSION_TO_BUILD}_amd64.deb\""
echo "==========="
dpkg -i "sope4.9-gdl1-${SOGO_DATABASE_ENGINE}_${VERSION_TO_BUILD}_amd64.deb"

echo "==========="
echo "dpkg -i \"sope4.9-libxmlsaxdriver_${VERSION_TO_BUILD}_amd64.deb\""
echo "==========="
dpkg -i "sope4.9-libxmlsaxdriver_${VERSION_TO_BUILD}_amd64.deb"

echo "==========="
echo "dpkg -i \"sope4.9-stxsaxdriver_${VERSION_TO_BUILD}_amd64.deb\""
echo "==========="
dpkg -i "sope4.9-stxsaxdriver_${VERSION_TO_BUILD}_amd64.deb"

echo "==========="
echo "dpkg -i \"sogo_${VERSION_TO_BUILD}_amd64.deb\""
echo "==========="
dpkg -i "sogo_${VERSION_TO_BUILD}_amd64.deb"

echo "==========="
echo "dpkg -i \"sogo-activesync_${VERSION_TO_BUILD}_amd64.deb\""
echo "==========="
dpkg -i "sogo-activesync_${VERSION_TO_BUILD}_amd64.deb"
