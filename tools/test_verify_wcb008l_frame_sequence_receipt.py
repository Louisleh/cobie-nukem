#!/usr/bin/env python3
"""OX-WCB-008L-M1A standard-library unit tests for the receipt verifier.

Creates real minimal valid PNG fixtures using only the Python 3 standard
library and exercises a positive fixture plus the required negative fixtures.
"""

from __future__ import annotations

import hashlib
import json
import os
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import verify_wcb008l_frame_sequence_receipt as verifier  # noqa: E402

SOURCE_REVISION = "a" * 64
SCENE_HASH = "b" * 64
SCRIPT_HASH = "c" * 64
CLEAN_LOG = "Godot Engine v4.7.stable.official\nframe_post_draw captured\n"


def make_png(width: int = 4, height: int = 3, pixel: bytes = b"\x10\x20\x30") -> bytes:
    """Build a minimal valid 8-bit RGB PNG with the standard library only."""
    signature = b"\x89PNG\r\n\x1a\n"

    def chunk(ctype: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + ctype
            + data
            + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    row = b"\x00" + pixel * width
    raw = row * height
    idat = zlib.compress(raw)
    return (
        signature
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", idat)
        + chunk(b"IEND", b"")
    )


class Fixture:
    """One self-consistent capture fixture (receipt + frames + clean log)."""

    def __init__(self, tmp: str, width: int = 320, height: int = 180):
        self.dir = tempfile.mkdtemp(dir=tmp)
        self.frame_dir = os.path.join(self.dir, "frames")
        os.makedirs(self.frame_dir)
        self.width = width
        self.height = height
        png = make_png(width=width, height=height)
        self.png_bytes = png
        self.hashes = {}
        for i in range(60):
            name = "%06d.png" % i
            path = os.path.join(self.frame_dir, name)
            with open(path, "wb") as handle:
                handle.write(png)
            if i == 0:
                self.first_hash = hashlib.sha256(png).hexdigest()
            if i == 59:
                self.last_hash = hashlib.sha256(png).hexdigest()
            self.hashes[name] = hashlib.sha256(png).hexdigest()
        total = sum(
            os.path.getsize(os.path.join(self.frame_dir, "%06d.png" % i))
            for i in range(60)
        )
        self.output_bytes = total
        self.receipt = {
            "mode": "short_probe_non_evidence",
            "eligible_for_90s_evidence": False,
            "canonical_duration_completed": False,
            "captured_frame_count": 60,
            "projected_render_frames": 60,
            "physics_ticks": 120,
            "image_width": width,
            "image_height": height,
            "source_revision": SOURCE_REVISION,
            "scene_sha256": SCENE_HASH,
            "script_sha256": SCRIPT_HASH,
            "first_frame_sha256": self.first_hash,
            "last_frame_sha256": self.last_hash,
            "output_bytes": self.output_bytes,
            "completion_reason": "intentional_short_probe_cutoff",
        }
        self.receipt_path = os.path.join(self.dir, "receipt.json")
        self._write_receipt()
        self.log_path = os.path.join(self.dir, "run.log")
        with open(self.log_path, "w", encoding="utf-8") as handle:
            handle.write(CLEAN_LOG)

    def _write_receipt(self) -> None:
        with open(self.receipt_path, "w", encoding="utf-8") as handle:
            json.dump(self.receipt, handle)

    def write_receipt(self) -> None:
        self._write_receipt()

    def frame_path(self, name: str) -> str:
        return os.path.join(self.frame_dir, name)

    def verify_ok(self) -> bool:
        ok, _msg = verifier.verify(
            receipt_path=self.receipt_path,
            frame_dir=self.frame_dir,
            raw_log_path=self.log_path,
            expected_source_revision=SOURCE_REVISION,
            expected_scene_hash=SCENE_HASH,
            expected_script_hash=SCRIPT_HASH,
        )
        return ok

    def verify_message(self) -> str:
        ok, msg = verifier.verify(
            receipt_path=self.receipt_path,
            frame_dir=self.frame_dir,
            raw_log_path=self.log_path,
            expected_source_revision=SOURCE_REVISION,
            expected_scene_hash=SCENE_HASH,
            expected_script_hash=SCRIPT_HASH,
        )
        assert not ok, "expected failure but verification passed"
        return msg


class ReceiptVerifierTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="wcb008l_m1a_tests_")
        self.tmp = self._tmp.name

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def fixture(self) -> Fixture:
        return Fixture(self.tmp)

    # --- positive ---------------------------------------------------------

    def test_positive_fixture_passes_and_cli_prints_pass_sentinel(self) -> None:
        fx = self.fixture()
        self.assertTrue(fx.verify_ok())
        proc = subprocess.run(
            [
                sys.executable,
                verifier.__file__,
                "--receipt",
                fx.receipt_path,
                "--frame-dir",
                fx.frame_dir,
                "--raw-log",
                fx.log_path,
                "--source-revision",
                SOURCE_REVISION,
                "--scene-sha256",
                SCENE_HASH,
                "--script-sha256",
                SCRIPT_HASH,
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        pass_lines = [ln for ln in proc.stdout.splitlines() if ln.startswith("PASS")]
        self.assertEqual(len(pass_lines), 1)
        self.assertIn("PASS OX-WCB-008L-M1A", pass_lines[0])

    # --- JSON structure ---------------------------------------------------

    def test_malformed_json_fails(self) -> None:
        fx = self.fixture()
        with open(fx.receipt_path, "w", encoding="utf-8") as handle:
            handle.write('{"mode": "short_probe_non_evidence",')
        msg = fx.verify_message()
        self.assertIn("not valid JSON", msg)

    def test_non_object_json_fails(self) -> None:
        fx = self.fixture()
        with open(fx.receipt_path, "w", encoding="utf-8") as handle:
            handle.write("[1, 2, 3]")
        msg = fx.verify_message()
        self.assertIn("not an object", msg)

    def test_missing_required_field_fails(self) -> None:
        fx = self.fixture()
        del fx.receipt["captured_frame_count"]
        fx.write_receipt()
        self.assertIn("missing required field", fx.verify_message())

    # --- labels -----------------------------------------------------------

    def test_wrong_mode_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["mode"] = "canonical_90s_evidence"
        fx.write_receipt()
        self.assertIn("receipt mode must be", fx.verify_message())

    def test_relabel_eligibility_true_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["eligible_for_90s_evidence"] = True
        fx.write_receipt()
        self.assertIn("eligible_for_90s_evidence", fx.verify_message())

    def test_relabel_canonical_duration_completed_true_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["canonical_duration_completed"] = True
        fx.write_receipt()
        self.assertIn("canonical_duration_completed", fx.verify_message())

    def test_wrong_completion_reason_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["completion_reason"] = "canonical_run_finished"
        fx.write_receipt()
        self.assertIn("completion reason must be", fx.verify_message())

    # --- frame population -------------------------------------------------

    def test_captured_count_not_60_fails(self) -> None:
        for bad in (59, 61, 62, 0):
            fx = self.fixture()
            fx.receipt["captured_frame_count"] = bad
            fx.write_receipt()
            msg = fx.verify_message()
            self.assertTrue(
                "must be exactly 60" in msg or "does not match actual frames" in msg
            )

    def test_truncated_frame_directory_fails(self) -> None:
        fx = self.fixture()
        os.remove(fx.frame_path("000059.png"))
        msg = fx.verify_message()
        self.assertIn("missing/non-contiguous frames", msg)

    def test_gap_non_contiguous_frames_fail(self) -> None:
        fx = self.fixture()
        os.remove(fx.frame_path("000030.png"))
        msg = fx.verify_message()
        self.assertIn("missing/non-contiguous frames", msg)

    def test_extra_frame_fails(self) -> None:
        fx = self.fixture()
        with open(fx.frame_path("000060.png"), "wb") as handle:
            handle.write(fx.png_bytes)
        msg = fx.verify_message()
        self.assertIn("extra entries", msg)

    def test_duplicate_frame_manifests_as_extra_entry_fails(self) -> None:
        # A POSIX directory cannot hold two entries named 000000.png; a host
        # that "duplicates" a frame can only do so via another name, which is
        # rejected as an unexpected extra entry.
        fx = self.fixture()
        with open(fx.frame_path("000000 (copy).png"), "wb") as handle:
            handle.write(fx.png_bytes)
        self.assertIn("extra entries", fx.verify_message())

    def test_missing_frame_directory_fails(self) -> None:
        fx = self.fixture()
        ok, msg = verifier.verify(
            receipt_path=fx.receipt_path,
            frame_dir=os.path.join(fx.dir, "does_not_exist"),
            raw_log_path=fx.log_path,
            expected_source_revision=SOURCE_REVISION,
            expected_scene_hash=SCENE_HASH,
            expected_script_hash=SCRIPT_HASH,
        )
        self.assertFalse(ok)
        self.assertIn("does not exist", msg)

    # --- PNG integrity and telemetry ---------------------------------------

    def test_tampered_png_bytes_fail_structure(self) -> None:
        fx = self.fixture()
        path = fx.frame_path("000010.png")
        data = bytearray(open(path, "rb").read())
        data[-1] ^= 0xFF  # corrupt IEND CRC region
        with open(path, "wb") as handle:
            handle.write(bytes(data))
        msg = fx.verify_message()
        self.assertIn("invalid PNG structure", msg)

    def test_truncated_png_file_fails(self) -> None:
        fx = self.fixture()
        path = fx.frame_path("000020.png")
        data = open(path, "rb").read()
        with open(path, "wb") as handle:
            handle.write(data[: len(data) // 2])
        msg = fx.verify_message()
        self.assertIn("invalid PNG structure", msg)

    def test_dimension_inconsistency_with_receipt_fails(self) -> None:
        fx = self.fixture()
        wrong = make_png(width=fx.width + 16, height=fx.height)
        with open(fx.frame_path("000007.png"), "wb") as handle:
            handle.write(wrong)
        msg = fx.verify_message()
        self.assertIn("inconsistent with receipt", msg)

    def test_first_frame_hash_mismatch_fails(self) -> None:
        fx = self.fixture()
        other = make_png(pixel=b"\xAA\xBB\xCC")
        with open(fx.frame_path("000000.png"), "wb") as handle:
            handle.write(other)
        msg = fx.verify_message()
        self.assertIn("first frame SHA-256 mismatch", msg)

    def test_last_frame_hash_mismatch_fails(self) -> None:
        fx = self.fixture()
        other = make_png(pixel=b"\x01\x02\x03")
        with open(fx.frame_path("000059.png"), "wb") as handle:
            handle.write(other)
        msg = fx.verify_message()
        self.assertIn("last frame SHA-256 mismatch", msg)

    def test_projected_telemetry_as_actual_captures_fails(self) -> None:
        # Receipt claims projected render frames as captured while disk holds
        # fewer actual PNG files; count cross-check must fail closed.
        fx = self.fixture()
        os.remove(fx.frame_path("000041.png"))
        os.remove(fx.frame_path("000042.png"))
        msg = fx.verify_message()
        self.assertTrue(
            "projected render-frame telemetry" in msg
            or "missing/non-contiguous frames" in msg,
            "count/telemetry divergence must fail closed",
        )

    def test_projected_only_telemetry_divergence_fails(self) -> None:
        # Disk matches the frame set but the receipt relabels projected
        # canonical telemetry as actual captures; the exact-60 gate rejects it.
        fx = self.fixture()
        fx.receipt["projected_render_frames"] = 2700
        fx.receipt["captured_frame_count"] = 2700
        fx.write_receipt()
        msg = fx.verify_message()
        self.assertIn(
            "must be exactly 60",
            msg,
            "projected telemetry presented as actual captures must fail closed",
        )

    # --- source/hash binding ----------------------------------------------

    def test_source_revision_drift_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["source_revision"] = "9" * 64
        fx.write_receipt()
        self.assertIn("source_revision mismatch", fx.verify_message())

    def test_scene_hash_drift_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["scene_sha256"] = "d" * 64
        fx.write_receipt()
        self.assertIn("scene_sha256 mismatch", fx.verify_message())

    def test_script_hash_drift_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["script_sha256"] = "e" * 64
        fx.write_receipt()
        self.assertIn("script_sha256 mismatch", fx.verify_message())

    def test_expected_inputs_drift_fails_even_with_matching_receipt(self) -> None:
        fx = self.fixture()
        ok, msg = verifier.verify(
            receipt_path=fx.receipt_path,
            frame_dir=fx.frame_dir,
            raw_log_path=fx.log_path,
            expected_source_revision="f" * 64,
            expected_scene_hash=SCENE_HASH,
            expected_script_hash=SCRIPT_HASH,
        )
        self.assertFalse(ok)
        self.assertIn("source_revision mismatch", msg)

    def test_source_revision_accepts_40hex_git_revision(self) -> None:
        # Real WCB-008L source bindings are git revisions such as the M1R
        # blocker's 21b406f4... (40 hex), not SHA-256 strings; they must verify.
        fx = self.fixture()
        git_rev = "21b406f4a6f5c809396c30f435c5e2b1c9cc4525"
        fx.receipt["source_revision"] = git_rev
        fx.write_receipt()
        ok, msg = verifier.verify(
            receipt_path=fx.receipt_path,
            frame_dir=fx.frame_dir,
            raw_log_path=fx.log_path,
            expected_source_revision=git_rev,
            expected_scene_hash=SCENE_HASH,
            expected_script_hash=SCRIPT_HASH,
        )
        self.assertTrue(ok, msg)

    def test_non_hex_hash_field_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["script_sha256"] = "zz-not-a-hash"
        fx.write_receipt()
        msg = fx.verify_message()
        self.assertIn("lowercase hex SHA-256", msg)

    # --- byte accounting ----------------------------------------------------

    def test_output_byte_mismatch_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["output_bytes"] = fx.output_bytes + 1
        fx.write_receipt()
        self.assertIn("aggregate output-byte mismatch", fx.verify_message())

    def test_output_byte_ceiling_breach_in_receipt_fails(self) -> None:
        fx = self.fixture()
        fx.receipt["output_bytes"] = verifier.OUTPUT_BYTE_CEILING + 1
        fx.write_receipt()
        msg = fx.verify_message()
        self.assertIn("exceeds ceiling", msg)

    def test_actual_bytes_above_ceiling_fail(self) -> None:
        # Writing 64 MiB of fixtures would be wasteful; lower the ceiling so
        # the real aggregate-byte path above the limit is exercised.
        fx = self.fixture()
        original = verifier.OUTPUT_BYTE_CEILING
        verifier.OUTPUT_BYTE_CEILING = max(1, fx.output_bytes - 1)
        try:
            ok, msg = verifier.verify(
                receipt_path=fx.receipt_path,
                frame_dir=fx.frame_dir,
                raw_log_path=fx.log_path,
                expected_source_revision=SOURCE_REVISION,
                expected_scene_hash=SCENE_HASH,
                expected_script_hash=SCRIPT_HASH,
            )
        finally:
            verifier.OUTPUT_BYTE_CEILING = original
        self.assertFalse(ok)
        # Either the receipt-claim gate ("exceeds ceiling") or the aggregate
        # actual-byte gate ("exceed ceiling") may fire; both fail closed.
        self.assertTrue(
            "exceeds ceiling" in msg or "exceed ceiling" in msg,
            "bytes above the ceiling must fail closed",
        )

    # --- raw log -------------------------------------------------------------

    def _log_case(self, line: str) -> str:
        fx = self.fixture()
        with open(fx.log_path, "w", encoding="utf-8") as handle:
            handle.write(CLEAN_LOG + line + "\n")
        return fx.verify_message()

    def test_log_engine_error_fails(self) -> None:
        self.assertIn("engine_error", self._log_case('ERROR: Condition "!p_canvas" is true.'))

    def test_log_parser_error_fails(self) -> None:
        self.assertIn("parser_error", self._log_case("Parse Error: Unexpected identifier."))

    def test_log_script_error_fails(self) -> None:
        msg = self._log_case("SCRIPT ERROR: Invalid call.")
        self.assertTrue(
            "script_error" in msg or "engine_error" in msg,
            "SCRIPT ERROR must trip a forbidden diagnostic",
        )

    def test_log_objectdb_leak_fails(self) -> None:
        self.assertIn(
            "objectdb_leak",
            self._log_case("ObjectDB instances leaked at exit (4 instances)."),
        )

    def test_log_resource_leak_fails(self) -> None:
        self.assertIn(
            "resource_leak",
            self._log_case("Resources still in use at exit (2)."),
        )

    def test_log_particles_shader_gles3_not_freed_fails(self) -> None:
        self.assertIn(
            "particles_shader_gles3_not_freed",
            self._log_case("ParticlesShaderGLES3 not freed, allocations: 1."),
        )

    def test_log_shader_rid_leak_fails(self) -> None:
        self.assertIn(
            "shader_rid_leak",
            self._log_case("Shader RID allocation leaked (RID: 42)."),
        )

    def test_log_shader_cache_creation_failure_fails(self) -> None:
        self.assertIn(
            "shader_cache_failure",
            self._log_case("Failed to create shader cache directory."),
        )

    def test_missing_raw_log_fails(self) -> None:
        fx = self.fixture()
        ok, msg = verifier.verify(
            receipt_path=fx.receipt_path,
            frame_dir=fx.frame_dir,
            raw_log_path=os.path.join(fx.dir, "absent.log"),
            expected_source_revision=SOURCE_REVISION,
            expected_scene_hash=SCENE_HASH,
            expected_script_hash=SCRIPT_HASH,
        )
        self.assertFalse(ok)
        self.assertIn("raw log does not exist", msg)


def main() -> int:
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
