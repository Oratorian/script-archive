#!/bin/sh
cd /opt/repo/ubuntu/dists/stable
set -e

do_hash() {
    HASH_NAME=$1
    HASH_CMD=$2
    echo "${HASH_NAME}:"
    for f in $(find -type f); do
        f=$(echo $f | cut -c3-) # remove ./ prefix
        if [ "$f" = "Release" ]; then
            continue
        fi
        echo " $(${HASH_CMD} ${f}  | cut -d" " -f1) $(wc -c $f)"
    done
}

cat << EOF
Origin: Emby-Repo by amhosting.de
Label: Emby-Repo by amhosting.de
Suite: stable
Codename: stable
Version: 1.0
Architectures: amd64 arm64 armhf i386
Components: main
Description: Emby-Repo by amhosting.de
Date: $(date -Ru)
EOF
do_hash "MD5Sum" "md5sum"
do_hash "SHA1" "sha1sum"
do_hash "SHA256" "sha256sum"

