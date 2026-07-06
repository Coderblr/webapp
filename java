#!/usr/bin/env python3
"""
Framework Analyzer - single file tool
=====================================
1. Framework Indexer  - scans page / stepDefinitions / locator folders -> JSON index
2. Feature Parser     - reads a .feature file, extracts Transaction ID + steps
3. Step Scanner       - reads Java step definition files, extracts annotated steps
4. Comparator         - finds which feature steps are missing
5. Console Output     - prints a summary report

Usage:
    python main.py <path_to_feature_file> [framework_root]

Example:
    python main.py src/features/TXN_00400.feature .
"""

import json
import os
import re
import sys

# ----------------------------------------------------------------------------
# CONFIG  <<< EDIT THESE PATHS TO MATCH YOUR MACHINE >>>
# ----------------------------------------------------------------------------
FRAMEWORK_ROOT = r"D:\Automation\NBC_Suraj"                          # your framework folder
PAGE_DIR       = r"D:\Automation\NBC_Suraj\src\page"                 # page classes
STEPDEF_DIR    = r"D:\Automation\NBC_Suraj\src\stepDefinitions"      # step definition classes
LOCATOR_DIR    = r"D:\Automation\NBC_Suraj\src\locator"              # locators (change if elsewhere)

INDEX_FILE = "framework_index.json"
STEP_ANNOTATIONS = ("@Given", "@When", "@Then", "@And", "@But")


# ----------------------------------------------------------------------------
# 1. FRAMEWORK INDEXER
# ----------------------------------------------------------------------------
def build_index(root: str) -> dict:
    """Index files from the folders configured at the top of this script."""
    def list_files(folder):
        if not os.path.isdir(folder):
            return []
        return [os.path.join(folder, f) for f in os.listdir(folder)
                if f.endswith((".java", ".properties", ".json", ".xml"))]

    index = {
        "page": list_files(PAGE_DIR),
        "stepDefinitions": list_files(STEPDEF_DIR),
        "locator": list_files(LOCATOR_DIR),
    }

    with open(INDEX_FILE, "w", encoding="utf-8") as fh:
        json.dump(index, fh, indent=2)

    return index


# ----------------------------------------------------------------------------
# 2. FEATURE PARSER
# ----------------------------------------------------------------------------
def parse_feature(feature_path: str) -> dict:
    """Extract transaction id and Gherkin steps from a .feature file."""
    with open(feature_path, "r", encoding="utf-8") as fh:
        text = fh.read()

    # Transaction ID: look in tags, Feature/Scenario lines, then filename (e.g. 00400)
    txn = None
    m = re.search(r"@?(?:TXN[_\- ]?)?(\d{4,6})", text)
    if m:
        txn = m.group(1)
    if not txn:
        m = re.search(r"(\d{4,6})", os.path.basename(feature_path))
        txn = m.group(1) if m else "UNKNOWN"

    steps = []
    keyword_re = re.compile(r"^\s*(Given|When|Then|And|But)\s+(.*\S)\s*$")
    for line in text.splitlines():
        m = keyword_re.match(line)
        if m:
            steps.append({"keyword": m.group(1), "text": m.group(2)})

    return {"transaction": txn, "steps": steps, "file": feature_path}


# ----------------------------------------------------------------------------
# 3. STEP SCANNER
# ----------------------------------------------------------------------------
def scan_step_definitions(step_files: list) -> list:
    """Extract annotated step patterns from Java step definition files."""
    patterns = []
    ann_re = re.compile(
        r'@(?:Given|When|Then|And|But)\s*\(\s*"((?:\\.|[^"\\])*)"\s*\)'
    )
    for path in step_files:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
        except OSError:
            continue
        for m in ann_re.finditer(content):
            patterns.append({"pattern": m.group(1), "file": path})
    return patterns


# ----------------------------------------------------------------------------
# 4. COMPARATOR
# ----------------------------------------------------------------------------
def cucumber_pattern_to_regex(pattern: str) -> re.Pattern:
    """Convert a Cucumber expression / regex step pattern to a Python regex."""
    p = pattern

    # already an anchored regex? strip anchors, keep body
    is_regex = p.startswith("^") or p.endswith("$")
    if is_regex:
        p = p.lstrip("^").rstrip("$")
        # Java regex is close enough to Python regex for typical steps
        try:
            return re.compile("^" + p + "$")
        except re.error:
            pass  # fall through and treat as literal

    # Cucumber expressions -> regex
    p = re.escape(p)
    replacements = {
        r"\{string\}": r'"[^"]*"',
        r"\{int\}": r"-?\d+",
        r"\{float\}": r"-?\d+(?:\.\d+)?",
        r"\{word\}": r"\S+",
        r"\{\}": r".*",
    }
    for k, v in replacements.items():
        p = p.replace(k, v)
    # generic {param}
    p = re.sub(r"\\\{[^}]*\\\}", r".*", p)
    return re.compile("^" + p + "$")


def find_missing_steps(feature_steps: list, java_patterns: list) -> list:
    compiled = []
    for jp in java_patterns:
        try:
            compiled.append(cucumber_pattern_to_regex(jp["pattern"]))
        except re.error:
            continue

    missing = []
    for step in feature_steps:
        text = step["text"]
        if not any(rx.match(text) for rx in compiled):
            missing.append(step)
    return missing


# ----------------------------------------------------------------------------
# 5. CONSOLE OUTPUT
# ----------------------------------------------------------------------------
def yes_no(value) -> str:
    return "YES" if value else "NO"


def print_summary(txn, locator_found, page_found, step_file_found, missing):
    generate_required = bool(missing) or not step_file_found
    print()
    print(f"Transaction      : {txn}")
    print(f"Locator Found    : {yes_no(locator_found)}")
    print(f"Page Found       : {yes_no(page_found)}")
    print(f"Step File Found  : {yes_no(step_file_found)}")
    print(f"Missing Steps    : {len(missing)}")
    print(f"Generate Required: {yes_no(generate_required)}")
    if missing:
        print("\nMissing step details:")
        for s in missing:
            print(f"  - {s['keyword']} {s['text']}")
    print()


# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------
def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <feature_file> [framework_root]")
        sys.exit(1)

    feature_path = sys.argv[1]
    root = sys.argv[2] if len(sys.argv) > 2 else FRAMEWORK_ROOT

    if not os.path.isfile(feature_path):
        print(f"ERROR: feature file not found: {feature_path}")
        sys.exit(1)

    # 1. Index framework
    index = build_index(root)
    print(f"[Indexer] Index written to {INDEX_FILE}")
    print(f"[Indexer] page={len(index['page'])} "
          f"stepDefinitions={len(index['stepDefinitions'])} "
          f"locator={len(index['locator'])}")

    # 2. Parse feature
    feature = parse_feature(feature_path)
    txn = feature["transaction"]
    print(f"[Parser ] Transaction {txn}, {len(feature['steps'])} steps found")

    # 3. Scan Java step definitions
    java_patterns = scan_step_definitions(index["stepDefinitions"])
    print(f"[Scanner] {len(java_patterns)} annotated steps across "
          f"{len(index['stepDefinitions'])} files")

    # 4. Compare
    missing = find_missing_steps(feature["steps"], java_patterns)

    # Find files matching the naming convention: TXN_000400_Steps.java, TXN_000400_Page.java, etc.
    def find_txn_files(paths):
        if txn == "UNKNOWN":
            return []
        key = f"TXN_{txn}".lower()
        return [p for p in paths if key in os.path.basename(p).lower()]

    locator_files = find_txn_files(index["locator"])
    page_files = find_txn_files(index["page"])
    step_files = find_txn_files(index["stepDefinitions"])

    locator_found = bool(locator_files)
    page_found = bool(page_files)
    step_file_found = bool(step_files)

    # 5. Report
    print_summary(txn, locator_found, page_found, step_file_found, missing)
    for label, files in (("Page file", page_files),
                         ("Step file", step_files),
                         ("Locator file", locator_files)):
        for f in files:
            print(f"  {label}: {os.path.basename(f)}")


if __name__ == "__main__":
    main()
