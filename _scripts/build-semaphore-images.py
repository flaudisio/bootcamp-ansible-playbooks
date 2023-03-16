#!/usr/bin/env python3

import os
import subprocess
import sys

from pathlib import Path
from traceback import format_exc


REPO_DIR = Path(__file__).resolve().parent.parent

SEMAPHORE_IMAGE_DIR = "_docker/semaphore"
SEMAPHORE_IMAGE_REPO = os.getenv("SEMAPHORE_IMAGE_REPO", "example/semaphore")

SEMAPHORE_IMAGE_TAGS = {
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

BUILD_PLATFORMS = [
    "linux/amd64",
    "linux/arm64",
]


def msg(message: str) -> None:
    print(f"--> {message}", file=sys.stderr)


def build_image(image_tag: str, spec: dict) -> None:
    msg(f"Building image {image_tag}")

    dockerfile = spec.get("dockerfile", "Dockerfile")

    cmd = [
        "docker", "buildx", "build",
        "--platform", ",".join(BUILD_PLATFORMS),
        "--pull",
        "--tag", image_tag,
        "-f", f"{SEMAPHORE_IMAGE_DIR}/{dockerfile}",
        "--push",
        "."
    ]

    [cmd.extend(["--build-arg", arg]) for arg in spec.get("args", [])]

    msg("Running: {}".format(" ".join(cmd)))
    msg(f"cwd: {REPO_DIR}")

    subprocess.run(cmd, check=True, cwd=REPO_DIR)


def build_images() -> None:
    for tag, spec in SEMAPHORE_IMAGE_TAGS.items():
        build_image(f"{SEMAPHORE_IMAGE_REPO}:{tag}", spec)


def main() -> int:
    try:
        build_images()
    except Exception:
        msg("Error: could not build images. See traceback below:")
        print(format_exc())
        return 1

    msg("Done!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
