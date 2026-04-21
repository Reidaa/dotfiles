#!/usr/bin/env python3

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import getpass


def download_file(url: str, destination: str) -> None:
    print(f"Downloading {url} to {destination}")
    username = input("Username: ")
    password = getpass.getpass("Password: ")

    if shutil.which("curl") is None:
        raise RuntimeError("curl is required but was not found in PATH")
    subprocess.run(
        [
            "curl",
            "--fail",
            "--location",
            "-u",
            f"{username}:{password}",
            "--output",
            destination,
            url,
        ],
        check=True,
    )


def extract_archive(archive_path: str, target_dir: str) -> None:
    print(f"Extracting archive into {target_dir}")
    os.makedirs(target_dir, exist_ok=True)
    subprocess.run(
        ["tar", "-xzf", archive_path, "-C", target_dir],
        check=True,
    )


def artidl(archive_url: str) -> None:
    url_parts = archive_url.split("/")
    target_dir = "/tmp/" + "/".join(url_parts[-3:])[:-len(".tar.gz")]

    os.makedirs(target_dir, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".tar.gz") as temp_file:
        temp_archive_path = temp_file.name
        download_file(archive_url, temp_archive_path)
        extract_archive(temp_archive_path, target_dir)
    print("Done")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Download and extract an archive from Artifactory"
    )
    parser.add_argument("archive_url", help="Archive URL to download")
    args = parser.parse_args()

    try:
        artidl(args.archive_url)
        return 0
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
