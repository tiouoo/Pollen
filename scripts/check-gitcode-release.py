"""Only update existing GitCode releases: mirror repositories can reject creation."""

import json
import os
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen


def main():
    token = os.environ.get("GITCODE_TOKEN", "")
    tag = os.environ["GITCODE_TAG"]
    exists = False
    if token:
        repository = quote(os.environ["GITCODE_REPO"], safe="/")
        url = f"https://gitcode.com/api/v5/repos/{repository}/releases/tags/{quote(tag, safe='')}"
        request = Request(url, headers={"Authorization": f"Bearer {token}"})
        try:
            with urlopen(request, timeout=30) as response:
                release = json.load(response)
            if release.get("tag_name") != tag:
                raise RuntimeError("GitCode returned an unexpected release response.")
            exists = True
        except HTTPError as error:
            if error.code != 404:
                raise
        if not exists:
            print(f"::notice::GitCode release {tag} does not exist; skipping creation for the mirror repository.")
    else:
        print("::notice::GITCODE_TOKEN is not configured; skipping GitCode synchronization.")
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"exists={str(exists).lower()}\n")


if __name__ == "__main__":
    main()
