#!/usr/bin/env bash
set -euo pipefail

package="${PACKAGE:?PACKAGE is required}"
version="${APP_VERSION:?APP_VERSION is required}"
case "${CHANNEL:?CHANNEL is required}" in
    release) main=pollen-bin; aliases=(pollen pollen-mc pollen-stable pollen-stable-bin) ;;
    commit) main=pollen-commit-bin; aliases=(pollen-commit) ;;
    nightly) main=pollen-nightly-bin; aliases=(pollen-nightly) ;;
    *) exit 1 ;;
esac
[[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo 'Invalid package version' >&2; exit 1; }
if [[ "$package" != "$main" && ! " ${aliases[*]} " == *" $package "* ]]; then
    echo 'Package does not belong to channel' >&2
    exit 1
fi

conflicts=''
for other in pollen-bin pollen-commit-bin pollen-nightly-bin pollen pollen-mc pollen-stable pollen-stable-bin pollen-commit pollen-nightly; do
    [[ "$other" != "$package" && "$other" != "$main" ]] || continue
    # A main package must coexist with its own alias dependency wrappers.
    if [[ "$package" == "$main" && " ${aliases[*]} " == *" $other "* ]]; then
        continue
    fi
    conflicts+="'$other' "
done

template=.github/.packaging/aur
mkdir -p dist/aur
if [[ "$package" != "$main" ]]; then
    sed -e "s|@PACKAGE@|$package|g" -e "s|@VERSION@|$version|g" \
        -e "s|@MAIN_PACKAGE@|$main|g" -e "s|@CONFLICTS@|$conflicts|g" \
        "$template/PKGBUILD.alias.in" > dist/aur/PKGBUILD
    exit 0
fi

url="https://github.com/${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}/releases/download/${TAG:?TAG is required}/Pollen.linux.x64.AppImage"
sha=SKIP
cp assets/icon-pattern-128.png dist/aur/pollen.png
cp .github/.packaging/linux/pollen.desktop dist/aur/
cp LICENSE dist/aur/
if [[ "$CHANNEL" == release ]]; then
    curl -fL --retry 3 -o dist/Pollen.AppImage "$url"
    sha=$(sha256sum dist/Pollen.AppImage | cut -d' ' -f1)
fi
sed -e "s|@PACKAGE@|$package|g" -e "s|@VERSION@|$version|g" \
    -e "s|@URL@|$url|g" -e "s|@CONFLICTS@|$conflicts|g" \
    -e "s|@SHA@|$sha|g" "$template/PKGBUILD.in" > dist/aur/PKGBUILD
