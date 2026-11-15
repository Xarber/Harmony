#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
"""Validate repository compliance declarations and their evidence references."""

import json
import sys
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError, ValidationError

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def check_reference(reference):
    if reference.startswith("https://"):
        if not urlsplit(reference).hostname:
            raise ValueError(f"Invalid evidence URL: {reference}")
        return
    path = (ROOT / reference).resolve()
    if ROOT not in path.parents or not path.is_file():
        raise ValueError(f"Missing or invalid repository reference: {reference}")


def indexed(rows):
    result = {row["id"]: row for row in rows}
    if len(result) != len(rows):
        raise ValueError("Duplicate requirement or exception ID")
    return result


def validate():
    schema = read("Config/uads-schema.json")
    Draft202012Validator.check_schema(schema)
    manifest = read("uads.json")
    Draft202012Validator(
        schema, format_checker=Draft202012Validator.FORMAT_CHECKER
    ).validate(manifest)

    registry = indexed(read("Config/uads-requirements.json"))
    requirements = indexed(manifest["requirements"])
    exceptions = indexed(manifest["exceptions"])
    if registry.keys() != requirements.keys():
        raise ValueError("The registry and manifest must declare the same requirement IDs")
    if {section for row in registry.values() for section in row["sections"]} != set(range(1, 53)):
        raise ValueError("Missing UADS source section in registry")
    waived = {key for key, row in requirements.items() if row["status"] == "waived"}
    if waived != exceptions.keys():
        raise ValueError("Waived requirements must have exactly one exception record")

    for row in registry.values():
        for reference in row["evidence"]:
            check_reference(reference)
        if set(row["dependencies"]) - registry.keys():
            raise ValueError(f"Unknown dependency for {row['id']}")
    for key, row in requirements.items():
        if (row["applicability"] == "approved-exception") != (key in waived):
            raise ValueError(f"Inconsistent exception classification for {key}")
        if row["status"] == "not-applicable" and row["applicability"] not in {"conditional", "not-applicable"}:
            raise ValueError(f"Inconsistent applicability for {key}")
        if row["status"] == "passed" and not row["evidence"]:
            raise ValueError(f"Passed requirement has no verification evidence: {key}")
        for evidence in row["evidence"]:
            check_reference(evidence["location"])
    for row in exceptions.values():
        today = date.today()
        if not date.fromisoformat(row["approvedOn"]) <= today < date.fromisoformat(row["reviewOn"]):
            raise ValueError(f"Exception is expired or not yet approved: {row['id']}")
        if not set(row["platforms"]) <= set(manifest["project"]["platforms"]):
            raise ValueError(f"Exception lists unsupported platforms: {row['id']}")
    for reference in manifest["quality"].values():
        if isinstance(reference, str):
            check_reference(reference)
    print(f"UADS structure validated for {len(requirements)} tracked requirements")


if __name__ == "__main__":
    try:
        validate()
    except (OSError, ValueError, KeyError, TypeError, ValidationError, SchemaError) as error:
        print(f"UADS validation failed: {error}", file=sys.stderr)
        sys.exit(1)
