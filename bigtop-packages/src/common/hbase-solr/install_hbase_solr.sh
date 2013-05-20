#!/bin/sh
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

usage() {
  echo "
usage: $0 <options>
  Required not-so-options:
     --build-dir=DIR             path to flumedist.dir
     --prefix=PREFIX             path to install into

  Optional options:
     --doc-dir=DIR               path to install docs into [/usr/share/doc/flume]
     --flume-dir=DIR             path to install flume home [/usr/lib/flume]
     --installed-lib-dir=DIR     path where lib-dir will end up on target system
     ... [ see source for more similar options ]
  "
  exit 1
}

OPTS=$(getopt \
  -n $0 \
  -o '' \
  -l 'prefix:' \
  -l 'doc-dir:' \
  -l 'doc-dir-prefix:' \
  -l 'flume-dir:' \
  -l 'installed-lib-dir:' \
  -l 'build-dir:' -- "$@")

if [ $? != 0 ] ; then
    usage
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        --prefix)
        PREFIX=$2 ; shift 2
        ;;
        --build-dir)
        BUILD_DIR=$2 ; shift 2
        ;;
        --doc-dir)
        DOC_DIR=$2 ; shift 2
        ;;
        --doc-dir-prefix)
        DOC_DIR_PREFIX=$2 ; shift 2
        ;;
        --flume-dir)
        FLUME_DIR=$2 ; shift 2
        ;;
        --installed-lib-dir)
        INSTALLED_LIB_DIR=$2 ; shift 2
        ;;
        --)
        shift ; break
        ;;
        *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

for var in PREFIX BUILD_DIR ; do
  if [ -z "$(eval "echo \$$var")" ]; then
    echo Missing param: $var
    usage
  fi
done

LIB_DIR=${LIB_DIR:-/usr/lib/hbase-solr}
BIN_DIR=${BIN_DIR:-/usr/bin}
MAN_DIR=${MAN_DIR:-/usr/share/man/man1}
DOC_DIR=${DOC_DIR:-/usr/share/doc/hbase-solr}
DOC_DIR_PREFIX=${DOC_DIR_PREFIX:-$PREFIX}
CONF_DIR=${CONF_DIR:-/etc/hbase-solr/}

# Create the search package
install -d -m 0755 ${PREFIX}/${LIB_DIR}
tar -C ${PREFIX}/${LIB_DIR} --strip-components=1 -xzf ${PWD}/target/hbase-indexer*.tar.gz

# Conf dir
install -d -m 0755 ${PREFIX}/${CONF_DIR}
mv ${PREFIX}/${LIB_DIR}/conf ${PREFIX}/${CONF_DIR}/conf.dist
mv ${PREFIX}/${LIB_DIR}/bin/hbase-indexer-config.sh ${PREFIX}/${CONF_DIR}/conf.dist
ln -s ${CONF_DIR}/conf.dist ${PREFIX}/${LIB_DIR}/conf

# Demo files
install -d -m 0755 ${PREFIX}/${DOC_DIR}
mv ${PREFIX}/${LIB_DIR}/demo ${PREFIX}/${DOC_DIR}/demo
mv ${PREFIX}/${LIB_DIR}/{LICENSE.txt,README.md} ${PREFIX}/${DOC_DIR}

# User visible files
install -d -m 0755 $PREFIX/${BIN_DIR}
cat > $PREFIX/${BIN_DIR}/hbase-indexer <<__EOT__
#!/bin/bash

# Autodetect JAVA_HOME if not defined
if [ -e /usr/libexec/bigtop-detect-javahome ]; then
  . /usr/libexec/bigtop-detect-javahome
elif [ -e /usr/lib/bigtop-utils/bigtop-detect-javahome ]; then
  . /usr/lib/bigtop-utils/bigtop-detect-javahome
fi

exec ${LIB_DIR}/bin/hbase-indexer
__EOT__
chmod 755 $PREFIX/${BIN_DIR}/hbase-indexer

# Initialize a few /var locations
install -d -m 0755 $PREFIX/var/{run,log}/hbase-solr
