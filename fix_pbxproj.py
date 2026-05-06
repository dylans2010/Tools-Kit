import re
import sys

def fix_pbxproj(content):
    # 1. Identify all sections
    sections = re.findall(r'/\* Begin (\w+) section \*/\n(.*?)\n/\* End \1 section \*/', content, re.DOTALL)

    section_map = {}
    for name, body in sections:
        if name not in section_map:
            section_map[name] = []
        section_map[name].append(body)

    # 2. Merge bodies of same-named sections
    merged_sections = {}
    for name, bodies in section_map.items():
        merged_sections[name] = "\n".join(bodies)

    # 3. Reconstruct the file
    # We need to keep the header and footer (objects = { ... } and such)
    header_match = re.search(r'^(.*?)objects = \{', content, re.DOTALL)
    footer_match = re.search(r'\}\s*;\n\s*rootObject = .*?$', content, re.DOTALL)

    if not header_match or not footer_match:
        return content # Fail safe

    new_content = header_match.group(1) + "objects = {\n\n"

    # Sort section names for consistency
    for name in sorted(merged_sections.keys()):
        new_content += f"/* Begin {name} section */\n"
        new_content += merged_sections[name] + "\n"
        new_content += f"/* End {name} section */\n\n"

    new_content += "};\n"
    new_content += re.search(r'rootObject = .*?$', content, re.DOTALL).group(0)

    return new_content

if __name__ == "__main__":
    with open('Tools-Kit.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()

    fixed = fix_pbxproj(content)

    # Check for duplicate UUIDs in definitions
    uuid_pattern = re.compile(r'^\s*([A-F0-9]{24})\s*=', re.MULTILINE)
    uuids = uuid_pattern.findall(fixed)
    seen = set()
    duplicates = set()
    for u in uuids:
        if u in seen:
            duplicates.add(u)
        seen.add(u)

    if duplicates:
        print(f"Warning: Duplicate UUIDs found: {duplicates}")

    with open('Tools-Kit.xcodeproj/project.pbxproj', 'w') as f:
        f.write(fixed)
