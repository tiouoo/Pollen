#!/usr/bin/env bash

set -eu

mirror_dir="$(mktemp -d)"
trap 'rm -rf "$mirror_dir"' EXIT

git clone --mirror https://github.com/tiouoo/Portal.git "$mirror_dir/repository.git"
git -C "$mirror_dir/repository.git" remote add cnb "${CNB_REPO_URL_HTTPS:-https://cnb.cool/tiouo/portal.git}"
printf '%s:%s' "${CNB_TOKEN_USER_NAME:-cnb}" "$CNB_TOKEN" > "$mirror_dir/auth"
auth="$(base64 "$mirror_dir/auth")"
git -C "$mirror_dir/repository.git" -c "http.extraHeader=Authorization: Basic $auth" \
  push --force cnb 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'