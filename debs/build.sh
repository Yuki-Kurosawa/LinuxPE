# !/bin/bash

(
  mkdir -p dists/noble/main/binary-amd64
) && (
  find . -name "Contents-amd64.*" -or -name "Packages" -or -name "Packages.*" -delete
) && (
  apt-ftparchive generate -c=aptftp.conf aptgenerate.conf
) && (
  apt-ftparchive release -c=aptftp.conf dists/noble >dists/noble/Release
) && (
  rm -f dists/noble/Release.gpg dists/noble/InRelease
) && (
  gpg --clearsign -o dists/noble/InRelease dists/noble/Release
) && (
  gpg -abs -o dists/noble/Release.gpg dists/noble/Release
) && (
  echo OK
)
