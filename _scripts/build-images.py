#!/usr/bin/env python3

import os
import subprocess
import sys

from pathlib import Path
from traceback import format_exc


REPO_DIR = Path(__file__).resolve().parent.parent

SEMAPHORE_IMAGE = {
    "repo": os.getenv("SEMAPHORE_IMAGE_REPO", "example/semaphore"),
    "dir": "_docker/semaphore",
    "tags": {
        "2.8.89-alpine": {
            "dockerfile": "Dockerfile.alpine",
            "args": [
                "semaphore_version=2.8.89",
            ]
        },
        "2.8.89-debian": {
            "dockerfile": "Dockerfile.debian",
            "args": [
                "semaphore_version=2.8.89",
            ]
        },
    }
}

HOUSEKEEPER_IMAGE = {
    "repo": os.getenv("HOUSEKEEPER_IMAGE_REPO", "example/semaphore-housekeeper"),
    "dir": "_docker/semaphore-housekeeper",
    "tags": {
        "0.1.0": {
            "args": [
                "go_crond_version=23.2.0",
            ]
        },
    }
}

BUILD_PLATFORMS = [
    "linux/amd64",
    "linux/arm64",
]


def msg(message: str) -> None:
    print(f"--> {message}", file=sys.stderr)


def build_image(image_tag: str, image_dir: str, attrs: dict) -> None:
    msg(f"Building image {image_tag}")

    dockerfile = attrs.get("dockerfile", "Dockerfile")

    cmd = [
        "docker", "buildx", "build",
        "--platform", ",".join(BUILD_PLATFORMS),
        "--pull",
        "--tag", image_tag,
        "-f", f"{image_dir}/{dockerfile}",
        "--push",
        "."
    ]

    [cmd.extend(["--build-arg", arg]) for arg in attrs.get("args", [])]

    msg("Running: {}".format(" ".join(cmd)))
    msg(f"cwd: {REPO_DIR}")

    subprocess.run(cmd, check=True, cwd=REPO_DIR)


def build_images(target_image: str) -> None:
    if target_image == "semaphore":
        spec = SEMAPHORE_IMAGE
    elif target_image == "housekeeper":
        spec = HOUSEKEEPER_IMAGE

    image_repo = spec.get("repo")
    image_dir = spec.get("dir")

    for tag, attrs in spec.get("tags").items():
        build_image(f"{image_repo}:{tag}", image_dir, attrs)


def show_usage() -> None:
    msg(f"Usage: {sys.argv[0]} <semaphore|housekeeper>")
    sys.exit(2)


def main() -> int:
    target_image = None

    if len(sys.argv) == 1:
        show_usage()

    try:
        if sys.argv[1] in ["semaphore", "housekeeper"]:
            target_image = sys.argv[1]
        else:
            show_usage()
    except IndexError:
        show_usage()

    try:
        build_images(target_image)
    except Exception:
        msg("Error: could not build images. See traceback below:")
        print(format_exc(), file=sys.stderr)
        return 1

    msg("Done!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
