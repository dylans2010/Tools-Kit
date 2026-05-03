# TASK: Repair corrupted `project.pbxproj` by deduplicating UUID keys

## Problem
`Tools-Kit.xcodeproj/project.pbxproj` fails to parse (e.g. “missing semicolon in dictionary …”).

Root cause: duplicate top-level UUID keys inside the `objects = { ... }` dictionary. Old-style plist dictionaries cannot contain duplicate keys.

## Scope / constraints
- Modify **only** `Tools-Kit.xcodeproj/project.pbxproj`.
- Do **not** change Swift source files.
- Do **not** add/remove Swift Package dependencies.
- Do **not** change build settings.
- Preserve existing formatting and section ordering as much as possible.

## Required workflow

### 1) Load and analyze the full file
Read `Tools-Kit.xcodeproj/project.pbxproj` completely.

### 2) Build duplicate inventory
Inside `objects = { ... }`, find every top-level keyed entry matching:
`<UUID> /* ... */ = { ... };`

Identify UUIDs that occur more than once. For each duplicate UUID, capture:
- section name (`PBXBuildFile`, `PBXFileReference`, `PBXGroup`, `PBXSourcesBuildPhase`, etc.)
- line ranges of each occurrence
- full entry content for each occurrence

### 3) Resolve duplicates by type
For each duplicate UUID, keep exactly one authoritative entry:

- **PBXBuildFile**: keep the occurrence whose `fileRef` points to an existing `PBXFileReference` UUID.
- **PBXFileReference**: keep the occurrence with the canonical `path` (prefer filename-only path over accidental full directory path).
- **PBXGroup**: keep one occurrence and merge `children` arrays from all duplicates; deduplicate children while preserving order.
- **PBXSourcesBuildPhase**: keep one occurrence and merge `files` arrays from all duplicates; deduplicate while preserving order.
- **Any other section**: keep first occurrence, remove subsequent duplicates.

### 4) Repair cross-references
After deduplication, enforce consistency:
- Every `PBXBuildFile.fileRef` points to an existing `PBXFileReference`.
- Every `PBXGroup.children` UUID points to an existing `PBXFileReference` or `PBXGroup`.
- Every `PBXSourcesBuildPhase.files` UUID points to an existing `PBXBuildFile`.
- Remove dangling references.

### 5) Structural validation
Ensure:
- No duplicate top-level UUID keys remain in `objects`.
- Each `/* Begin X section */` has matching `/* End X section */`.
- Braces are balanced.
- Each entry terminates with `};`.
- File starts with `// !$*UTF8*$!` and ends with final `}`.

## Output requirements
Return:
1. Count of duplicate UUIDs found and resolved.
2. Summary of removals/merges by section.
3. Validation results for cross-reference checks.
4. Confirmation that file parses successfully.
