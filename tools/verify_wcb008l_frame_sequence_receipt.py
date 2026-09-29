#!/usr/bin/env python3
"""OX-WCB-008L-M1A fail-closed receipt verifier.

Verifies one short-probe frame-sequence capture receipt produced by the future
non-Movie-Maker WCB-008L capture host (see
``docs/work_packets/ox_alpha/wcb008l_m1s_frame_sequence_spike.md``).

This tool is deliberately dependency-free (Python 3 standard library only),
fail-closed, and never promotes evidence: the short probe is explicitly
ineligible for 90-second evidence. It prints one concise PASS sentinel only
after every check succeeds and returns nonzero otherwise.

Usage:
    python3 tools/verify_wcb008l_frame_sequence_receipt.py \
        --receipt receipt.json \
        --frame-dir /abs/path/to/frames \
        --raw-log run.log \
        --source-revision 89c8e72... \
        --scene-sha256 <sha256> \
        --script-sha256 <sha256>
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import sys
import zlib
from typing import List, Optional, Sequence, Tuple

EXPECTED_MODE = "short_probe_non_evidence"
EXPECTED_ELIGIBLE_FOR_90S_EVIDENCE = False
EXPECTED_CANONICAL_DURATION_COMPLETED = False
EXPECTED_COMPLETION_REASON = "intentional_short_probe_cutoff"

EXPECTED_FRAME_COUNT = 60
FIRST_FRAME_NAME = "000000.png"
LAST_FRAME_NAME = "000059.png"
OUTPUT_BYTE_CEILING = 64 * 1024 * 1024  # 64 MiB

FIELD_MODE = "mode"
FIELD_ELIGIBLE = "eligible_for_90s_evidence"
FIELD_CANONICAL_DONE = "canonical_duration_completed"
FIELD_CAPTURED_COUNT = "captured_frame_count"
FIELD_PROJECTED_FRAMES = "projected_render_frames"
FIELD_PHYSICS_TICKS = "physics_ticks"
FIELD_IMAGE_WIDTH = "image_width"
FIELD_IMAGE_HEIGHT = "image_height"
FIELD_SOURCE_REVISION = "source_revision"
FIELD_SCENE_SHA256 = "scene_sha256"
FIELD_SCRIPT_SHA256 = "script_sha256"
FIELD_FIRST_FRAME_SHA256 = "first_frame_sha256"
FIELD_LAST_FRAME_SHA256 = "last_frame_sha256"
FIELD_OUTPUT_BYTES = "output_bytes"
FIELD_COMPLETION_REASON = "completion_reason"

REQUIRED_FIELDS = (
    FIELD_MODE,
    FIELD_ELIGIBLE,
    FIELD_CANONICAL_DONE,
    FIELD_CAPTURED_COUNT,
    FIELD_PROJECTED_FRAMES,
    FIELD_PHYSICS_TICKS,
    FIELD_IMAGE_WIDTH,
    FIELD_IMAGE_HEIGHT,
    FIELD_SOURCE_REVISION,
    FIELD_SCENE_SHA256,
    FIELD_SCRIPT_SHA256,
    FIELD_FIRST_FRAME_SHA256,
    FIELD_LAST_FRAME_SHA256,
    FIELD_OUTPUT_BYTES,
    FIELD_COMPLETION_REASON,
)

SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

# Forbidden raw-log diagnostics (WCB-008L M1R_CAPTURE_BLOCKER.md gate).
FORBIDDEN_LOG_PATTERNS: Tuple[Tuple[str, "re.Pattern[str]"], ...] = (
    ("engine_error", re.compile(r"ERROR:")),
    ("script_error", re.compile(r"SCRIPT ERROR:", re.IGNORECASE)),
    ("parser_error", re.compile(r"\bparse error\b", re.IGNORECASE)),
    (
        "objectdb_leak",
        re.compile(
            r"ObjectDB instances leaked|leaked instances|ObjectDB[^\n]*\bleak",
            re.IGNORECASE,
        ),
    ),
    ("resource_leak", re.compile(r"resources still in use|Resource[^\n]*\bleak", re.IGNORECASE)),
    ("particles_shader_gles3_not_freed", re.compile(r"ParticlesShaderGLES3")),
    (
        "shader_rid_leak",
        re.compile(r"RID allocation leaked|\bRID\b[^\n]*\bleak", re.IGNORECASE),
    ),
    (
        "shader_cache_failure",
        re.compile(
            r"shader[^\n]{0,40}cache[^\n]{0,80}(?:fail|error)"
            r"|failed[^\n]{0,40}shader[^\n]{0,40}cache",
            re.IGNORECASE,
        ),
    ),
)


def _fail(message: str) -> Tuple[bool, str]:
    return (False, message)


def _require_int(payload: dict, field: str) -> Tuple[int, str]:
    """Return (value, "") or (0, error). Booleans are rejected as integers."""
    value = payload.get(field)
    if isinstance(value, bool) or not isinstance(value, int):
        return (0, "%s must be an integer" % field)
    return (int(value), "")


def verify_receipt_json(receipt_text: str) -> Tuple[bool, str]:
    """Receipt must be well-formed JSON and a JSON object."""
    try:
        payload = json.loads(receipt_text)
    except ValueError as exc:
        return _fail("receipt is not valid JSON: %s" % exc)
    if not isinstance(payload, dict):
        return _fail("receipt JSON is not an object")
    return (True, "")


def verify_receipt_labels(payload: dict) -> Tuple[bool, str]:
    """Mode, eligibility, canonical-duration, and completion labels must be exact."""
    if payload.get(FIELD_MODE) != EXPECTED_MODE:
        return _fail(
            "receipt mode must be %r, got %r" % (EXPECTED_MODE, payload.get(FIELD_MODE))
        )
    if payload.get(FIELD_ELIGIBLE) is not EXPECTED_ELIGIBLE_FOR_90S_EVIDENCE:
        return _fail("%s must be exactly false for a short probe" % FIELD_ELIGIBLE)
    if payload.get(FIELD_CANONICAL_DONE) is not EXPECTED_CANONICAL_DURATION_COMPLETED:
        return _fail("%s must be exactly false for a short probe" % FIELD_CANONICAL_DONE)
    if payload.get(FIELD_COMPLETION_REASON) != EXPECTED_COMPLETION_REASON:
        return _fail(
            "completion reason must be %r, got %r"
            % (EXPECTED_COMPLETION_REASON, payload.get(FIELD_COMPLETION_REASON))
        )
    return (True, "")


def scan_frame_directory(frame_dir: str) -> Tuple[List[str], str]:
    """Return the sorted expected frame list, or an error string.

    The directory must contain exactly ``000000.png``..``000059.png``: nothing
    missing, nothing extra, no gaps. POSIX directories cannot hold duplicate
    names, so a duplicated frame can only manifest as an unexpected extra entry,
    which is rejected here.
    """
    if not os.path.isdir(frame_dir):
        return ([], "frame directory does not exist: %s" % frame_dir)
    try:
        entries = sorted(os.listdir(frame_dir))
    except OSError as exc:
        return ([], "cannot read frame directory %s: %s" % (frame_dir, exc))
    expected = ["%06d.png" % i for i in range(EXPECTED_FRAME_COUNT)]
    expected_set = set(expected)
    extras = [name for name in entries if name not in expected_set]
    if extras:
        return (
            [],
            "unexpected extra entries in frame directory (duplicates or junk): %s"
            % ", ".join(extras[:5]),
        )
    missing = [name for name in expected if name not in set(entries)]
    if missing:
        # Contiguity check: report the first gap explicitly.
        return ([], "missing/non-contiguous frames (first few): %s" % ", ".join(missing[:5]))
    for name in expected:
        path = os.path.join(frame_dir, name)
        if os.path.islink(path):
            return ([], "frame entry must not be a symlink: %s" % name)
        if not os.path.isfile(path):
            return ([], "frame entry is not a regular file: %s" % name)
    return (expected, "")


def verify_frame_counts(payload: dict, frame_names: List[str]) -> Tuple[bool, str]:
    """Actual captured count must be exactly 60 and match disk; projected telemetry never stands in."""
    captured, err = _require_int(payload, FIELD_CAPTURED_COUNT)
    if err:
        return _fail(err)
    projected, err = _require_int(payload, FIELD_PROJECTED_FRAMES)
    if err:
        return _fail(err)
    ticks, err = _require_int(payload, FIELD_PHYSICS_TICKS)
    if err:
        return _fail(err)
    if captured != EXPECTED_FRAME_COUNT:
        return _fail(
            "captured_frame_count must be exactly %d, got %d"
            % (EXPECTED_FRAME_COUNT, captured)
        )
    if ticks <= 0:
        return _fail("physics_ticks telemetry must be positive")
    if projected < 0:
        return _fail("projected_render_frames telemetry must be non-negative")
    if captured != len(frame_names):
        return _fail(
            "captured_frame_count (%d) does not match actual frames on disk (%d); "
            "projected render-frame telemetry must never be presented as captures "
            "(projected=%d)"
            % (captured, len(frame_names), projected)
        )
    return (True, "")


def read_file_bytes(path: str) -> bytes:
    with open(path, "rb") as handle:
        return handle.read()


def parse_png_dimensions(data: bytes) -> Tuple[bool, int, int, str]:
    """Validate minimal PNG structure; return (ok, width, height, error).

    Checks signature, chunk framing and CRCs, IHDR placement, presence of IDAT
    and trailing IEND. Truncated or tampered files fail closed.
    """
    signature = b"\x89PNG\r\n\x1a\n"
    if len(data) < len(signature) + 12:
        return (False, 0, 0, "PNG data too short")
    if data[:8] != signature:
        return (False, 0, 0, "bad PNG signature")
    offset = 8
    width = -1
    height = -1
    seen_ihdr = False
    seen_idat = False
    seen_iend = False
    while offset < len(data):
        if offset + 8 > len(data):
            return (False, 0, 0, "truncated PNG chunk header")
        (length,) = struct.unpack(">I", data[offset : offset + 4])
        chunk_type = data[offset + 4 : offset + 8]
        if len(chunk_type) != 4 or not all(65 <= b <= 122 for b in chunk_type):
            return (False, 0, 0, "invalid PNG chunk type")
        chunk_start = offset + 8
        chunk_end = chunk_start + length
        if chunk_end + 4 > len(data):
            return (False, 0, 0, "truncated PNG chunk body")
        (stored_crc,) = struct.unpack(">I", data[chunk_end : chunk_end + 4])
        computed_crc = zlib.crc32(chunk_type + data[chunk_start:chunk_end]) & 0xFFFFFFFF
        if stored_crc != computed_crc:
            return (
                False,
                0,
                0,
                "PNG chunk CRC mismatch in %r" % chunk_type.decode("latin-1"),
            )
        if not seen_ihdr:
            if chunk_type != b"IHDR":
                return (False, 0, 0, "first PNG chunk is not IHDR")
            if length != 13:
                return (False, 0, 0, "IHDR chunk must be 13 bytes")
            width, height = struct.unpack(">II", data[chunk_start : chunk_start + 8])
            seen_ihdr = True
        elif chunk_type == b"IHDR":
            return (False, 0, 0, "duplicate IHDR chunk")
        elif chunk_type == b"IDAT":
            seen_idat = True
        elif chunk_type == b"IEND":
            seen_iend = True
            if chunk_end + 4 != len(data):
                return (False, 0, 0, "trailing bytes after PNG IEND")
        offset = chunk_end + 4
    if not seen_ihdr:
        return (False, 0, 0, "PNG has no IHDR chunk")
    if not seen_idat:
        return (False, 0, 0, "PNG has no IDAT chunk")
    if not seen_iend:
        return (False, 0, 0, "PNG has no IEND chunk (truncated)")
    return (True, int(width), int(height), "")


def sha256_file(path: str) -> Tuple[str, str]:
    digest = hashlib.sha256()
    try:
        with open(path, "rb") as handle:
            for block in iter(lambda: handle.read(65536), b""):
                digest.update(block)
    except OSError as exc:
        return ("", "cannot read %s: %s" % (path, exc))
    return (digest.hexdigest(), "")


def _norm_hash(value: str) -> str:
    return value.strip().lower()


def verify_hashes_and_bytes(
    payload: dict,
    frame_dir: str,
    frame_names: List[str],
    expected_source_revision: str,
    expected_scene_hash: str,
    expected_script_hash: str,
) -> Tuple[bool, str]:
    """Source binding, endpoint hashes, dimensions, and byte accounting."""
    # The source revision is supplied by the capture wrapper and is a VCS
    # revision (e.g. a 40-hex git commit), not necessarily a SHA-256. Enforce
    # presence and exact equality; do not impose a 64-hex format here.
    actual_revision = payload.get(FIELD_SOURCE_REVISION)
    if (
        not isinstance(actual_revision, str)
        or not _norm_hash(actual_revision)
        or not expected_source_revision.strip()
    ):
        return _fail("source_revision must be a non-empty revision string")
    if _norm_hash(actual_revision) != _norm_hash(expected_source_revision):
        return _fail("source_revision mismatch (source/hash drift)")

    for field, expected in (
        (FIELD_SCENE_SHA256, expected_scene_hash),
        (FIELD_SCRIPT_SHA256, expected_script_hash),
    ):
        actual = payload.get(field)
        if not isinstance(actual, str) or not SHA256_RE.match(_norm_hash(actual)):
            return _fail("%s must be a lowercase hex SHA-256 string" % field)
        if _norm_hash(actual) != _norm_hash(expected):
            return _fail("%s mismatch (source/hash drift)" % field)

    width, err = _require_int(payload, FIELD_IMAGE_WIDTH)
    if err:
        return _fail(err)
    height, err = _require_int(payload, FIELD_IMAGE_HEIGHT)
    if err:
        return _fail(err)
    if width <= 0 or height <= 0:
        return _fail("image dimensions must be positive")

    output_bytes, err = _require_int(payload, FIELD_OUTPUT_BYTES)
    if err:
        return _fail(err)
    if output_bytes > OUTPUT_BYTE_CEILING:
        return _fail(
            "receipt output_bytes %d exceeds ceiling %d" % (output_bytes, OUTPUT_BYTE_CEILING)
        )

    # Preflight the whole frame set before hashing or reading file contents.
    # A dishonest small receipt value must not make the verifier read an
    # unbounded frame into memory before discovering the real byte total.
    actual_total_bytes = 0
    for name in frame_names:
        path = os.path.join(frame_dir, name)
        try:
            actual_total_bytes += os.path.getsize(path)
        except OSError as exc:
            return _fail("cannot stat frame %s: %s" % (name, exc))
        if actual_total_bytes > OUTPUT_BYTE_CEILING:
            return _fail(
                "actual frame bytes %d exceed ceiling %d"
                % (actual_total_bytes, OUTPUT_BYTE_CEILING)
            )

    if frame_names[0] != FIRST_FRAME_NAME or frame_names[-1] != LAST_FRAME_NAME:
        return _fail(
            "frame span must run %s..%s, got %s..%s"
            % (FIRST_FRAME_NAME, LAST_FRAME_NAME, frame_names[0], frame_names[-1])
        )

    endpoint_hashes = {}
    for label, name in (("first", FIRST_FRAME_NAME), ("last", LAST_FRAME_NAME)):
        digest, err = sha256_file(os.path.join(frame_dir, name))
        if err:
            return _fail(err)
        endpoint_hashes[label] = digest

    if payload.get(FIELD_FIRST_FRAME_SHA256) != endpoint_hashes["first"]:
        return _fail("first frame SHA-256 mismatch")
    if payload.get(FIELD_LAST_FRAME_SHA256) != endpoint_hashes["last"]:
        return _fail("last frame SHA-256 mismatch")

    for name in frame_names:
        path = os.path.join(frame_dir, name)
        try:
            data = read_file_bytes(path)
        except OSError as exc:
            return _fail("cannot read frame %s: %s" % (name, exc))
        ok, png_w, png_h, png_err = parse_png_dimensions(data)
        if not ok:
            return _fail("invalid PNG structure in %s: %s" % (name, png_err))
        if (png_w, png_h) != (width, height):
            return _fail(
                "PNG %s dimensions %dx%d inconsistent with receipt %dx%d"
                % (name, png_w, png_h, width, height)
            )
    if output_bytes != actual_total_bytes:
        return _fail(
            "aggregate output-byte mismatch: receipt claims %d, actual PNG bytes %d"
            % (output_bytes, actual_total_bytes)
        )
    return (True, "")


def scan_raw_log(raw_log_path: str) -> Tuple[bool, str]:
    """Raw engine logs must be free of parser/script errors, leaks, and any ERROR line."""
    if not os.path.isfile(raw_log_path):
        return _fail("raw log does not exist: %s" % raw_log_path)
    try:
        with open(raw_log_path, "r", encoding="utf-8", errors="replace") as handle:
            lines = handle.readlines()
    except OSError as exc:
        return _fail("cannot read raw log %s: %s" % (raw_log_path, exc))
    for line_number, line in enumerate(lines, start=1):
        for label, pattern in FORBIDDEN_LOG_PATTERNS:
            if pattern.search(line):
                return _fail(
                    "raw log line %d contains forbidden diagnostic (%s): %s"
                    % (line_number, label, line.strip()[:200])
                )
    return (True, "")


def verify(
    receipt_path: str,
    frame_dir: str,
    raw_log_path: str,
    expected_source_revision: str,
    expected_scene_hash: str,
    expected_script_hash: str,
) -> Tuple[bool, str]:
    """Run every fail-closed check; return (ok, message)."""
    if not receipt_path:
        return _fail("missing required receipt input")
    if not frame_dir:
        return _fail("missing required frame-directory input")
    if not raw_log_path:
        return _fail("missing required raw-log input")
    if not expected_source_revision.strip():
        return _fail("missing required expected source revision")
    if not SHA256_RE.match(_norm_hash(expected_scene_hash)):
        return _fail("expected scene hash must be a SHA-256")
    if not SHA256_RE.match(_norm_hash(expected_script_hash)):
        return _fail("expected script hash must be a SHA-256")

    try:
        with open(receipt_path, "r", encoding="utf-8") as handle:
            receipt_text = handle.read()
    except OSError as exc:
        return _fail("cannot read receipt %s: %s" % (receipt_path, exc))

    ok, msg = verify_receipt_json(receipt_text)
    if not ok:
        return (ok, msg)
    payload = json.loads(receipt_text)

    for field in REQUIRED_FIELDS:
        if field not in payload:
            return _fail("receipt is missing required field %s" % field)

    ok, msg = verify_receipt_labels(payload)
    if not ok:
        return (ok, msg)

    frame_names, err = scan_frame_directory(frame_dir)
    if err:
        return _fail(err)

    ok, msg = verify_frame_counts(payload, frame_names)
    if not ok:
        return (ok, msg)

    ok, msg = verify_hashes_and_bytes(
        payload,
        frame_dir,
        frame_names,
        expected_source_revision,
        expected_scene_hash,
        expected_script_hash,
    )
    if not ok:
        return (ok, msg)

    ok, msg = scan_raw_log(raw_log_path)
    if not ok:
        return (ok, msg)

    return (True, "all checks passed")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Fail-closed verifier for WCB-008L non-Movie-Maker short-probe "
            "frame-sequence receipts."
        )
    )
    parser.add_argument("--receipt", required=True, help="Path to the JSON receipt")
    parser.add_argument("--frame-dir", required=True, help="Directory holding 000000.png..000059.png")
    parser.add_argument("--raw-log", required=True, help="Path to the raw engine log")
    parser.add_argument("--source-revision", required=True, help="Expected source revision")
    parser.add_argument("--scene-sha256", required=True, help="Expected scene SHA-256")
    parser.add_argument("--script-sha256", required=True, help="Expected script SHA-256")
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    ok, message = verify(
        receipt_path=args.receipt,
        frame_dir=args.frame_dir,
        raw_log_path=args.raw_log,
        expected_source_revision=args.source_revision,
        expected_scene_hash=args.scene_sha256,
        expected_script_hash=args.script_sha256,
    )
    if ok:
        print("PASS OX-WCB-008L-M1A short-probe receipt verified (frames=60 non_evidence=true)")
        return 0
    print("FAIL OX-WCB-008L-M1A receipt verification: %s" % message, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
