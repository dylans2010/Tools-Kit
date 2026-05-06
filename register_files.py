import re
import os

# Configuration
core_sdk_group_id = "7C0A3202F90F4064B52AC392"
connectors_group_id = "F5E2482A753F4279B1D77597"
sdk_views_group_id = "89F7FA2CC5CC4B6A9B8697F0"
main_sources_phase_id = "C9111E28A299A9C316B4C75C"

sdk_core_files = [
    ("SK010000000000000000001001", "SK020000000000000000001001", "SDKAppRuntime.swift"),
    ("SK010000000000000000001002", "SK020000000000000000001002", "SDKModuleSystem.swift"),
    ("SK010000000000000000001003", "SK020000000000000000001003", "SDKUIBridge.swift"),
    ("SK010000000000000000001004", "SK020000000000000000001004", "SDKStateStore.swift"),
    ("SK010000000000000000001005", "SK020000000000000000001005", "SDKNavigationEngine.swift"),
    ("SK010000000000000000001006", "SK020000000000000000001006", "SDKToolDefinition.swift"),
    ("SK010000000000000000001007", "SK020000000000000000001007", "SDKAppManifest.swift"),
    ("SK010000000000000000001008", "SK020000000000000000001008", "SDKExecutionContext.swift"),
]

connector_files = [
    ("NW010000000000000000001001", "NW020000000000000000001001", "SDKConnectorRuntime.swift"),
    ("NW010000000000000000001002", "NW020000000000000000001002", "SDKAuthManager.swift"),
    ("NW010000000000000000001003", "NW020000000000000000001003", "SDKRequestBuilder.swift"),
    ("NW010000000000000000001004", "NW020000000000000000001004", "SDKResponseParser.swift"),
]

sdk_view_files = [
    ("PL010000000000000000001030", "PL020000000000000000001030", "SDKUIScreenEditorView.swift"),
    ("PL010000000000000000001031", "PL020000000000000000001031", "SDKLogicEditorView.swift"),
    ("PL010000000000000000001032", "PL020000000000000000001032", "SDKConnectorManagerView.swift"),
    ("PL010000000000000000001033", "PL020000000000000000001033", "SDKAppRuntimeView.swift"),
    ("PL010000000000000000001034", "PL020000000000000000001034", "SDKStateInspectorView.swift"),
    ("PL010000000000000000001035", "PL020000000000000000001035", "SDKDataFlowView.swift"),
]

all_new_files = sdk_core_files + connector_files + sdk_view_files

with open('Tools-Kit.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 1. PBXBuildFile
lines = []
for file_id, build_id, name in all_new_files:
    lines.append(f"\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};")
content = content.replace("/* Begin PBXBuildFile section */", "/* Begin PBXBuildFile section */\n" + "\n".join(lines))

# 2. PBXFileReference
lines = []
for file_id, _, name in all_new_files:
    lines.append(f"\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
content = content.replace("/* Begin PBXFileReference section */", "/* Begin PBXFileReference section */\n" + "\n".join(lines))

# 3. PBXGroup
def add_to_group(group_id, files):
    global content
    pattern = rf'({group_id} /\* .*? \*/ = \{{.*?children = \()(.+?)\);'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        existing = match.group(2)
        new_children = ""
        for file_id, _, name in files:
            new_children += f"\t\t\t\t{file_id} /* {name} */,\n"
        content = content.replace(match.group(0), match.group(1) + existing + new_children + "\t\t\t);")

add_to_group(core_sdk_group_id, sdk_core_files)
add_to_group(connectors_group_id, connector_files)
add_to_group(sdk_views_group_id, sdk_view_files)

# 4. PBXSourcesBuildPhase
pattern = rf'({main_sources_phase_id} /\* Sources \*/ = \{{.*?files = \()(.+?)\);'
match = re.search(pattern, content, re.DOTALL)
if match:
    existing = match.group(2)
    new_files = ""
    for _, build_id, name in all_new_files:
        new_files += f"\t\t\t\t{build_id} /* {name} in Sources */,\n"
    content = content.replace(match.group(0), match.group(1) + existing + new_files + "\t\t\t);")

with open('Tools-Kit.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)
