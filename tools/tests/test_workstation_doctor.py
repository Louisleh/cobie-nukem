#!/usr/bin/env python3
"""Fail-closed prerequisite tests without launching editors or touching user data."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

SPEC = importlib.util.spec_from_file_location('doctor', Path(__file__).parents[1] / 'workstation_doctor.py')
assert SPEC is not None and SPEC.loader is not None
doctor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(doctor)


class DoctorTests(unittest.TestCase):
    def test_stable_version(self):
        self.assertEqual(doctor.template_version('4.7.1.stable.official.a13da4feb'), '4.7.1.stable')

    def test_reject_other_or_unstable_versions(self):
        for value in ('4.7.1.rc1.official', '4.7.1.stable.custom', '4.7.1.stableoops', '4.8.0.stable', 'error', ''):
            with self.subTest(value=value), self.assertRaises(ValueError):
                doctor.template_version(value)

    def test_disk_gates(self):
        self.assertEqual(doctor.space_status(5 * doctor.GIB, False), 'FAIL')
        self.assertEqual(doctor.space_status(6 * doctor.GIB, False), 'WARN')
        self.assertEqual(doctor.space_status(19 * doctor.GIB, True), 'FAIL')
        self.assertEqual(doctor.space_status(20 * doctor.GIB, True), 'PASS')

    def test_missing_templates_fail(self):
        with tempfile.TemporaryDirectory() as root:
            rows = doctor.template_checks(Path(root), '4.7.1.stable')
            self.assertTrue(all(row['status'] == 'FAIL' for row in rows))

    def test_valid_templates_then_corruption(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)
            (path / 'version.txt').write_text('4.7.1.stable\n')
            for name in doctor.REQUIRED_TEMPLATES:
                with zipfile.ZipFile(path / name, 'w') as archive:
                    archive.writestr('fixture', 'not a real engine; integrity fixture only')
            self.assertTrue(all(row['status'] == 'PASS' for row in doctor.template_checks(path, '4.7.1.stable')))
            (path / 'macos.zip').write_bytes(b'broken')
            self.assertEqual(doctor.template_checks(path, '4.7.1.stable')[-1]['status'], 'FAIL')

    def test_wrong_embedded_version_fails(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)
            (path / 'version.txt').write_text('4.7.0.stable')
            self.assertEqual(doctor.template_checks(path, '4.7.1.stable')[0]['status'], 'FAIL')

    def test_ios_is_explicit(self):
        with tempfile.TemporaryDirectory() as root:
            rows = doctor.template_checks(Path(root), '4.7.1.stable', True)
            self.assertEqual(rows[-1]['check'], 'ios.zip')
            self.assertEqual(rows[-1]['status'], 'FAIL')

    def test_empty_zip_fails(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)
            with zipfile.ZipFile(path / 'macos.zip', 'w'):
                pass
            self.assertEqual(doctor.template_checks(path, '4.7.1.stable')[-1]['status'], 'FAIL')

    def test_missing_command_fails_without_shell(self):
        code, detail = doctor.run(['/nonexistent/cobie-doctor-fixture'])
        self.assertNotEqual(code, 0)
        self.assertEqual(detail, 'FileNotFoundError')


if __name__ == '__main__':
    unittest.main()
