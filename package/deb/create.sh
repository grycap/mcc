#!/bin/bash
#
# MCC - My Container Cluster
# https://github.com/dealfonso/my_container_cluster
#
# Copyright (C) GRyCAP - I3M - UPV 
# Developed by Carlos A. caralla@upv.es
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SRCFOLDER=$1
if [ "$SRCFOLDER" == "" ]; then
  SRCFOLDER="."
fi

source "$SRCFOLDER/version"

if [ $? -ne 0 ]; then
  echo "could not find the version for the package"
  exit 1
fi
REVISION=${VERSION##*-}
VERSION=${VERSION%%-*}

if [ "$REVISION" == "$VERSION" ]; then
  REVISION=
fi

if [ "$REVISION" != "" ]; then
  REVISION="-${REVISION}"
fi

FNAME=build/mcc_${VERSION}${REVISION}
rm -rf "$FNAME"
mkdir -p "${FNAME}/DEBIAN"

${SRCFOLDER}/INSTALL.sh "${SRCFOLDER}" "${FNAME}"

cat > "${FNAME}/DEBIAN/control" << EOF
Package: mcc
Version: ${VERSION}${REVISION}
Section: base
Priority: optional
Architecture: all
Depends: bash, jq, libc-bin, coreutils, lxd (>=2.0), bsdmainutils, curl (>=7.45)
Maintainer: Carlos A. <calfonso@upv.es>
Description: MCC - My Container Cluster
 Easily create computing clusters made from LXC/LXD containers. MCC creates
 the front-end and the working nodes, and configure them to have passwordless
 ssh, access to devices such as GPU, shared home folder between the nodes, etc.
 It is very useful for cluster testing and prototyping.
EOF

cat > "${FNAME}/DEBIAN/postinst" <<\EOF
#!/bin/sh
lxc profile show mcc-default > /dev/null 2> /dev/null
if [ $? -ne 0 ]; then
  lxc profile create mcc-default
  if [ $? -ne 0 ]; then
    echo "could not create default profile in lxc" 2>&1
    exit 1
  fi
  lxc profile edit mcc-default <<\EOT
config:
  environment.http_proxy: ""
  user.network_mode: ""
description: default profile for mcc
devices:
  root:
    path: /
    pool: default
    type: disk
EOT
  if [ $? -ne 0 ]; then
    echo "failed to update the default profile in lxc" 2>&1
    lxc profile delete mcc-default
    exit 1
  fi
fi
exit 0
EOF

cat > "${FNAME}/DEBIAN/postrm" <<\EOF
#!/bin/sh
lxc profile show mcc-default > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
  lxc profile delete mcc-default
fi
exit 0
EOF

chmod +x "${FNAME}/DEBIAN/postinst"
chmod +x "${FNAME}/DEBIAN/postrm"

cat > "${FNAME}/DEBIAN/conffiles" <<\EOF
/etc/mcc/mcc.conf
EOF

cd "${FNAME}"
find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf "%P " | xargs md5sum > "DEBIAN/md5sums"
cd -

fakeroot dpkg-deb --build "${FNAME}"

mv ${FNAME}.deb .
rm -rf ${FNAME}