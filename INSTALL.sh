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

SRCFOLDER="${1:-.}"
PREFIX="${2:-/}"

INSTALLDIR="/usr/share/mcc"

mkdir -p "${PREFIX}/usr/bin"
mkdir -p "${PREFIX}/$INSTALLDIR"
mkdir -p "${PREFIX}/etc/mcc"

APPFILES="includes lib operations platform README.md version LICENSE context/mcc"
for i in $APPFILES; do
  D="${PREFIX}/$INSTALLDIR/$(dirname $i)"
  mkdir -p "$D"
  cp -r "$SRCFOLDER/$i" "$D"
done

for i in mcc; do
  cp -r "$SRCFOLDER/$i" "${PREFIX}/usr/bin"
done

for i in etc/mcc/mcc.conf etc/bash_completion.d etc/mcc/context/front-end etc/mcc/context/working-node; do
  D="${PREFIX}/$(dirname $i)"
  mkdir -p "$D"
  cp -r "$SRCFOLDER/$i" "$D"
done

cat >> "${PREFIX}/etc/mcc/mcc.conf" << EOF

MCC_FOLDER="$INSTALLDIR"
EOF

chmod 755 ${PREFIX}/usr/bin/*
chmod 755 ${PREFIX}/etc
chmod 755 $(find ${PREFIX}/etc/ -type d)
chmod 644 $(find ${PREFIX}/etc/ ! -type d)
chmod 755 ${PREFIX}/$INSTALLDIR
chmod 755 $(find ${PREFIX}/$INSTALLDIR/ -type d)
chmod 644 $(find ${PREFIX}/$INSTALLDIR/ ! -type d)

# Adjust permissions for execution
chmod 755 $(find ${PREFIX}/etc/mcc/context -type f)
chmod 755 $(find ${PREFIX}/$INSTALLDIR/context -type f)