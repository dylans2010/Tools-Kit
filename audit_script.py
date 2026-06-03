import os
import re

directory = 'Sources/Views/Workspace/Developer'
files = [f for f in os.listdir(directory) if f.endswith('.swift')]

report = []

for file in files:
    path = os.path.join(directory, file)
    with open(path, 'r') as f:
        content = f.read()

    category = "Utility"
    if "struct" in content and "View" in content:
        if "ViewModel" in file: category = "ViewModel"
        elif "View" in file: category = "System View" # Most are system views
        else: category = "Supporting View"
    elif "class" in content and "Service" in file:
        category = "Service"
    elif "struct" in content or "enum" in content:
        category = "Model"

    # Quick checks
    has_mock = bool(re.search(r'\[.*"example\.com".*\]|\[.*"test".*\]|0\.\.<[0-9]+', content))
    has_noop = "/* logic */" in content or "/* resubmit */" in content or "/* reset */" in content or "/* group creation logic */" in content

    report.append({
        "file": file,
        "category": category,
        "mock": has_mock,
        "noop": has_noop,
        "incomplete": has_noop or has_mock
    })

for item in sorted(report, key=lambda x: x['file']):
    status = "INCOMPLETE" if item['incomplete'] else "OK"
    print(f"| {item['file']} | {item['category']} | {status} | {'Mock' if item['mock'] else ''} {'No-op' if item['noop'] else ''} |")
