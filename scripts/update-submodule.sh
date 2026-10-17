#!/bin/bash
set -e

repository_root="$(cd "$(dirname "$0")/.." && pwd)"
git -C "$repository_root" submodule update --init --recursive

git -C "$repository_root" config -f .gitmodules --get-regexp '^submodule\..*\.branch$' |
while read -r branch_key branch; do
    path_key="${branch_key%.branch}.path"
    path="$(git -C "$repository_root" config -f .gitmodules --get "$path_key")"
    submodule="$repository_root/$path"

    git -C "$submodule" fetch origin "$branch"
    if git -C "$submodule" show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$submodule" checkout "$branch"
    else
        git -C "$submodule" checkout -b "$branch" --track "origin/$branch"
    fi
    git -C "$submodule" pull --ff-only origin "$branch"
done

read -p "press enter to quit"