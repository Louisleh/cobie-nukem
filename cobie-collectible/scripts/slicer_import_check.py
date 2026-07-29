#!/usr/bin/env python3
"""Phase 3 independent gate: prove every canonical STL imports in PrusaSlicer.

This deliberately does not select a printer or generate supports.  Those
choices belong to the eventual resin vendor.  It verifies the portable part of
the gate: exact inventory, successful third-party parsing, positive dimensions,
non-empty facets, manifold geometry, and one connected object per part.
"""

from __future__ import annotations

import math
import platform
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    BUILD_REPORT,
    EXPORTS,
    PART_NAMES,
    SLICER_TESTS,
    Failure,
    check_build_receipt,
    portable_path,
    report,
    sha256_file,
    write_json,
)


def find_prusaslicer() -> Path | None:
    candidates = [
        shutil.which("prusa-slicer"),
        shutil.which("PrusaSlicer"),
        "/Applications/PrusaSlicer.app/Contents/MacOS/PrusaSlicer",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return Path(candidate).resolve()
    return None


def parse_info_output(output: str) -> dict[str, str]:
    """Parse the stable ``--info`` key/value format without guessing types."""
    parsed: dict[str, str] = {}
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("[") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        parsed[key.strip()] = value.strip()
    return parsed


def validate_info(name: str, values: dict[str, str]) -> list[Failure]:
    failures: list[Failure] = []
    required = ("size_x", "size_y", "size_z", "number_of_facets", "manifold", "number_of_parts")
    missing = [key for key in required if key not in values]
    if missing:
        return [Failure("slicer_info", name, f"PrusaSlicer omitted: {', '.join(missing)}")]

    for axis in ("size_x", "size_y", "size_z"):
        try:
            number = float(values[axis])
            positive = math.isfinite(number) and number > 0
        except ValueError:
            positive = False
        if not positive:
            failures.append(Failure("slicer_dimensions", name, f"{axis} is {values[axis]}"))
    try:
        positive_facets = int(values["number_of_facets"]) > 0
    except ValueError:
        positive_facets = False
    if not positive_facets:
        failures.append(Failure("slicer_facets", name, f"facet count is {values['number_of_facets']}"))
    if values["manifold"].lower() != "yes":
        failures.append(Failure("slicer_manifold", name, f"reported {values['manifold']}"))
    try:
        one_part = int(values["number_of_parts"]) == 1
    except ValueError:
        one_part = False
    if not one_part:
        failures.append(
            Failure("slicer_parts", name, f"reported {values['number_of_parts']} disconnected parts")
        )
    return failures


def _run() -> int:
    stl_paths = sorted(
        (
            path
            for path in EXPORTS.iterdir()
            if path.is_file() and path.suffix.lower() == ".stl"
        ),
        key=lambda path: path.name,
    ) if EXPORTS.is_dir() else []
    expected = {f"{name}.stl" for name in PART_NAMES}
    observed = {path.name for path in stl_paths}
    receipt_failures, build_receipt = check_build_receipt()
    failures: list[Failure] = list(receipt_failures)
    for filename in sorted(expected - observed):
        failures.append(Failure("missing_part", filename, "required STL is missing"))
    for filename in sorted(observed - expected):
        failures.append(Failure("unexpected_part", filename, "unexpected or stale STL is present"))
    for path in stl_paths:
        if path.is_symlink():
            failures.append(
                Failure("non_regular_export", path.name, "STL exports must not be symbolic links")
            )

    executable = find_prusaslicer()
    results: dict[str, dict[str, str]] = {}
    version_text: list[str] = []
    if executable is None:
        failures.append(
            Failure("slicer_missing", "PrusaSlicer", "install PrusaSlicer and rerun")
        )
    else:
        for name in PART_NAMES:
            path = EXPORTS / f"{name}.stl"
            if not path.is_file() or path.is_symlink():
                continue
            try:
                completed = subprocess.run(
                    [str(executable), "--info", str(path)],
                    capture_output=True,
                    check=False,
                    text=True,
                    timeout=60,
                )
            except subprocess.TimeoutExpired:
                failures.append(
                    Failure("slicer_timeout", path.name, "PrusaSlicer --info exceeded 60 seconds")
                )
                continue
            except OSError as exc:
                failures.append(Failure("slicer_import", path.name, str(exc)))
                continue
            if completed.returncode != 0:
                detail = (completed.stderr or completed.stdout).strip() or f"exit {completed.returncode}"
                failures.append(Failure("slicer_import", path.name, detail))
                continue
            values = parse_info_output(completed.stdout)
            results[path.name] = values
            failures.extend(validate_info(path.name, values))

        try:
            version_run = subprocess.run(
                [str(executable), "--help"],
                capture_output=True,
                check=False,
                text=True,
                timeout=15,
            )
            version_text = (version_run.stdout or version_run.stderr).splitlines()
        except (subprocess.TimeoutExpired, OSError):
            version_text = []

    if set(results) != expected and executable is not None:
        missing_results = sorted(expected - set(results))
        if missing_results:
            failures.append(
                Failure(
                    "slicer_result_inventory",
                    "PrusaSlicer",
                    f"no successful import result for {missing_results}",
                )
            )
    payload = {
        "environment": {
            "platform": platform.platform(),
            "slicer_executable": portable_path(executable) if executable else None,
            "slicer_version": version_text[0] if version_text else "unknown",
        },
        "expected_stl_files": sorted(expected),
        "observed_stl_files": sorted(observed),
        "build_receipt": {
            "path": portable_path(BUILD_REPORT),
            "sha256": sha256_file(BUILD_REPORT) if BUILD_REPORT.is_file() else None,
            "status": build_receipt.get("status"),
            "pipeline_version": build_receipt.get("pipeline_version"),
            "source_blend_sha256": build_receipt.get("source_blend_sha256"),
        },
        "export_hashes": {path.name: sha256_file(path) for path in stl_paths},
        "parts": results,
        "failures": [failure.as_dict() for failure in failures],
    }
    write_json(SLICER_TESTS / "prusaslicer_import_report.json", payload)

    for filename, values in results.items():
        print(
            f"  {filename}: {values.get('number_of_facets', '?')} facets, "
            f"manifold={values.get('manifold', '?')}, parts={values.get('number_of_parts', '?')}"
        )
    return report("COBIE_FIGURINE_SLICER_IMPORT", failures)


def main() -> int:
    output = SLICER_TESTS / "prusaslicer_import_report.json"
    incomplete = Failure(
        "validation_incomplete",
        str(output),
        "slicer validation started but has not completed",
    )
    write_json(
        output,
        {
            "expected_stl_files": [f"{name}.stl" for name in PART_NAMES],
            "observed_stl_files": [],
            "export_hashes": {},
            "parts": {},
            "failures": [incomplete.as_dict()],
        },
    )
    try:
        return _run()
    except Exception as exc:
        failure = Failure("validation_exception", str(output), f"{type(exc).__name__}: {exc}")
        write_json(output, {"parts": {}, "failures": [failure.as_dict()]})
        return report("COBIE_FIGURINE_SLICER_IMPORT", [failure])


if __name__ == "__main__":
    raise SystemExit(main())
