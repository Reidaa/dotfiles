#!/usr/bin/env python3
"""Download a tar.gz from Artifactory and extract it under /tmp."""

import argparse
import base64
import getpass
import sys
import tarfile
import tempfile
import urllib.request


def artidl(archive_url: str) -> None:
    # Mirror the source layout: /tmp/<second-to-last>/<last-but-one> path segments.
    target_dir = "/tmp/" + "/".join(archive_url.split("/")[-3:-1])

    credentials = f"{input('Username: ')}:{getpass.getpass('Password: ')}"
    request = urllib.request.Request(
        archive_url,
        headers={
            "Authorization": "Basic " + base64.b64encode(credentials.encode()).decode()
        },
    )

    print(f"Downloading {archive_url}")
    with (
        urllib.request.urlopen(request) as response,
        tempfile.TemporaryFile() as archive,
    ):
        while chunk := response.read(1 << 20):
            archive.write(chunk)
        archive.seek(0)
        print(f"Extracting into {target_dir}")
        with tarfile.open(fileobj=archive, mode="r:gz") as tar:
            tar.extractall(target_dir, filter="data")
    print("Done")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive_url", help="Archive URL to download")
    try:
        artidl(parser.parse_args().archive_url)
        return 0
    except (OSError, tarfile.TarError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
