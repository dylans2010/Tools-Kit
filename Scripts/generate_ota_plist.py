#!/usr/bin/env python3

import plistlib
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 6:
        print(
            "usage: generate_ota_plist.py <output> <bundle_id> <version> <title> <ipa_url>",
            file=sys.stderr,
        )
        return 2

    output_path = Path(sys.argv[1])
    bundle_id = sys.argv[2]
    version = sys.argv[3]
    title = sys.argv[4]
    ipa_url = sys.argv[5]

    payload = {
        "items": [
            {
                "assets": [
                    {
                        "kind": "software-package",
                        "url": ipa_url,
                    }
                ],
                "metadata": {
                    "bundle-identifier": bundle_id,
                    "bundle-version": version,
                    "kind": "software",
                    "title": title,
                },
            }
        ]
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as handle:
        plistlib.dump(payload, handle, fmt=plistlib.FMT_XML)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())