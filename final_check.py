import os
import re

def check():
    results = []

    # Check file count
    root = "Sources/Views/Workspace/OpenClaw/Alternatives"
    count = 0
    for r, d, fs in os.walk(root):
        for f in fs:
            if f.endswith(".swift"):
                count += 1
    results.append(f"Total swift files: {count}")

    # Check pbxproj
    with open('Tools-Kit.xcodeproj/project.pbxproj', 'r') as f:
        pbx = f.read()

    alt_view_in_pbx = "OpenClawAltView.swift" in pbx
    results.append(f"OpenClawAltView.swift in pbxproj: {alt_view_in_pbx}")

    # Check for invalid UUIDs (non-hex)
    # Our UUIDs start with FR, BF, group_, so they ARE NOT valid hex if I used those.
    # Wait, my register_final.py used uuid.uuid5().hex.upper()[:24]
    # Let's check if all 24-char strings that look like IDs are hex.
    # IDs in pbxproj are usually 24 chars.
    ids = re.findall(r'([0-9A-Z]{24})', pbx)
    invalid_ids = [i for i in ids if not re.match(r'^[0-9A-F]{24}$', i)]
    results.append(f"Invalid (non-hex) IDs found: {len(invalid_ids)}")
    if invalid_ids:
        results.append(f"Sample invalid IDs: {invalid_ids[:5]}")

    # Check for force unwraps
    force_unwraps = []
    for r, d, fs in os.walk(root):
        for f in fs:
            if f.endswith(".swift"):
                path = os.path.join(r, f)
                with open(path, 'r') as file:
                    for i, line in enumerate(file):
                        if "!" in line and "//" not in line and '"' not in line:
                            # Basic check for force unwrap, might have false positives
                            force_unwraps.append(f"{path}:{i+1} {line.strip()}")
    results.append(f"Potential force unwraps: {len(force_unwraps)}")

    # Check for architecture comments
    arch_comments = 0
    for r, d, fs in os.walk(root):
        for f in fs:
            if "Models.swift" in f:
                with open(os.path.join(r, f), 'r') as file:
                    if "ARCHITECTURE" in file.read():
                        arch_comments += 1
    results.append(f"Files with ARCHITECTURE comments: {arch_comments}")

    with open('check_results.txt', 'w') as f:
        f.write("\n".join(results))

check()
