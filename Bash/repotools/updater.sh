#!/bin/bash
dir=$(dirname "$(realpath "$0")")

grep_arch () {
  local arch=$1
  local version=$2
  url="https://github.com/MediaBrowser/Emby.Releases/releases/download"
  #grep=".*https://github.com/MediaBrowser/Emby.Releases/releases/download/.*emby-server-deb_$version.*_$arch.deb\"$"
  #echo $(curl -fsSl $url | grep "$grep" | cut -d: -f2,3 | head -1 | tr -d \" | xargs)
  echo "$url/$version/emby-server-deb_"$version"_"$arch".deb"
}

check_url () {
    local url=$1

    if wget --spider "$url" 2>&1 | grep -q 'Remote file exists'; then
        echo "$url"
    else
        echo "No Release binary found: ${url##*/}" >&2
        echo ""
    fi
}


stable_download () {
  stable=$(curl -s 'https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest' | jq -r '.tag_name')

  amd64=$(check_url $(grep_arch "amd64" "$stable"))
  arm64=$(check_url $(grep_arch "arm64" "$stable"))
  armhf=$(check_url $(grep_arch "armhf" "$stable"))

  if [[ -z "$amd64" ]] || [[ -f "$(echo $amd64 | awk -F'/opt/repo/ubuntu/pool/main/emby/stable' '{print $NF}')" ]]
    then
      echo "">/dev/null
  else
    wget -Nq $amd64 -P /opt/repo/ubuntu/pool/main/emby/stable
  fi
  if [[ -z "$arm64" ]] || [[ -f "$(echo $arm64 | awk -F'/opt/repo/ubuntu/pool/main/emby/stable' '{print $NF}')" ]]
    then
      echo "">/dev/null
  else
    wget -Nq $arm64 -P /opt/repo/ubuntu/pool/main/emby/stable
  fi
  if [[ -z "$armhf" ]] || [[ -f "$(echo $armhf | awk -F'/opt/repo/ubuntu/pool/main/emby/bestableta' '{print $NF}')" ]]
    then
      echo "">/dev/null
  else
    wget -Nq $armhf -P /opt/repo/ubuntu/pool/main/emby/stable
  fi

  repo_update
}

beta_download () {
#  beta=$(curl -fsSl https://api.github.com/repos/MediaBrowser/Emby.Releases/releases -s | jq -r .[].tag_name | grep '^[0-9]\.[0-9]*\.[0-9]\.[0-9]*$' | sort -nr | head -n1)
  beta=$(curl -s 'https://api.github.com/repos/MediaBrowser/Emby.Releases/releases' | jq -r '.[].tag_name' | sort -V | tail -n 1)
  amd64=$(check_url $(grep_arch "amd64" "$beta"))
  arm64=$(check_url $(grep_arch "arm64" "$beta"))
  armhf=$(check_url $(grep_arch "armhf" "$beta"))


  if [[ -z "$amd64" ]] || [[ -f "$(echo $amd64 | awk -F'/opt/repo/ubuntu/pool/main/emby/beta' '{print $NF}')" ]]
    then
      echo "">/dev/null
  else
    wget -Nq $amd64 -P /opt/repo/ubuntu/pool/main/emby/beta
  fi
  if [[ -z "$arm64" ]] || [[ -f "$(echo $arm64 | awk -F'/opt/repo/ubuntu/pool/main/emby/beta' '{print $NF}')" ]]
    then
      echo "">/dev/null
  else
    wget -Nq $arm64 -P /opt/repo/ubuntu/pool/main/emby/beta
  fi
  if [[ -z "$armhf" ]] || [[ -f "$(echo $armhf | awk -F'/opt/repo/ubuntu/pool/main/emby/beta' '{print $NF}')" ]]
    then
      echo "">/dev/null
  else
    wget -Nq $armhf -P /opt/repo/ubuntu/pool/main/emby/beta
  fi
    repo_update
}

repo_update () {
    cd /opt/repo/ubuntu/
    dpkg-scanpackages --multiversion --arch amd64 pool/main/emby/beta/ > /opt/repo/ubuntu/dists/beta/main/binary-amd64/Packages
    dpkg-scanpackages --multiversion --arch armhf pool/main/emby/beta/ > /opt/repo/ubuntu/dists/beta/main/binary-armhf/Packages
    dpkg-scanpackages --multiversion --arch arm64 pool/main/emby/beta/ > /opt/repo/ubuntu/dists/beta/main/binary-arm64/Packages

    dpkg-scanpackages --multiversion --arch amd64 pool/main/emby/stable/ > /opt/repo/ubuntu/dists/stable/main/binary-amd64/Packages
    dpkg-scanpackages --multiversion --arch armhf pool/main/emby/stable/ > /opt/repo/ubuntu/dists/stable/main/binary-armhf/Packages
    dpkg-scanpackages --multiversion --arch arm64 pool/main/emby/stable/ > /opt/repo/ubuntu/dists/stable/main/binary-arm64/Packages

    cat /opt/repo/ubuntu/dists/beta/main/binary-amd64/Packages | gzip -9 > /opt/repo/ubuntu/dists/beta/main/binary-amd64/Packages.gz
    cat /opt/repo/ubuntu/dists/beta/main/binary-armhf/Packages | gzip -9 > /opt/repo/ubuntu/dists/beta/main/binary-armhf/Packages.gz
    cat /opt/repo/ubuntu/dists/beta/main/binary-arm64/Packages | gzip -9 > /opt/repo/ubuntu/dists/beta/main/binary-arm64/Packages.gz

    cat /opt/repo/ubuntu/dists/stable/main/binary-amd64/Packages | gzip -9 > /opt/repo/ubuntu/dists/stable/main/binary-amd64/Packages.gz
    cat /opt/repo/ubuntu/dists/stable/main/binary-armhf/Packages | gzip -9 > /opt/repo/ubuntu/dists/stable/main/binary-armhf/Packages.gz
    cat /opt/repo/ubuntu/dists/stable/main/binary-arm64/Packages | gzip -9 > /opt/repo/ubuntu/dists/stable/main/binary-arm64/Packages.gz

    #cd /opt/repo/ubuntu/dists/stable
    $dir/generate-stable.sh > /opt/repo/ubuntu/dists/stable/Release
    #cd /opt/repo/ubuntu/dists/beta
    $dir/generate-beta.sh > /opt/repo/ubuntu/dists/beta/Release

    cat /opt/repo/ubuntu/dists/stable/Release | gpg --default-key amhosting -abs > /opt/repo/ubuntu/dists/stable/Release.gpg
    cat /opt/repo/ubuntu/dists/beta/Release | gpg --default-key amhosting -abs > /opt/repo/ubuntu/dists/beta/Release.gpg
    cat /opt/repo/ubuntu/dists/beta/Release | gpg --default-key amhosting -abs --clearsign > /opt/repo/ubuntu/dists/beta/InReleas
    cat /opt/repo/ubuntu/dists/stable/Release | gpg --default-key amhosting -abs --clearsign > /opt/repo/ubuntu/dists/stable/InReleas

    chown -R 33:33 /opt/repo
    exit 1
}


# Main script logic
case "$1" in
    checklatest)
        stable_download
        ;;
    checkbeta)
        beta_download
        ;;
    repo)
        repo_update
        ;;
    *)
        echo "Usage: $0 {checklatest|checkbeta}"
        exit 1
        ;;
esac

exit 0
