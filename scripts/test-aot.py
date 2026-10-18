"""Run the published desktop application's Native AOT regression checks."""

import os
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    # Windows CI may default to cp1252; reports and diagnostics can contain Chinese.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

    executable = Path(sys.argv[1]).resolve(strict=True)
    results = Path("test-results/aot").resolve()
    results.mkdir(parents=True, exist_ok=True)
    report = results / "smoke-test.txt"
    report.unlink(missing_ok=True)

    if any(path.suffix.lower() == ".pdb" for path in executable.parent.rglob("*")):
        print("FAIL: publish directory contains PDB files.", file=sys.stderr)
        return 1
    windows = sys.platform == "win32"
    if windows and list(executable.parent.iterdir()) != [executable]:
        print("FAIL: Windows publish must contain only the executable.", file=sys.stderr)
        return 1

    if list(executable.parent.glob("*.runtimeconfig.json")) or (executable.parent / "Pollen.Desktop.dll").exists():
        message = "FAIL: expected a Native AOT publish directory, found a managed application."
        report.write_text(message, encoding="utf-8")
        print(message, file=sys.stderr)
        return 1

    # Build metadata must survive trimming; do not let runtime variables supply it.
    environment = {
        key: value for key, value in os.environ.items()
        if not key.startswith("POLLEN_BUILD_") and key != "POLLEN_PACKAGE_TYPE"
    }
    with tempfile.TemporaryDirectory(prefix="native-cache-", dir=results) as temporary:
        environment["DOTNET_BUNDLE_EXTRACT_BASE_DIR"] = temporary
        cache = Path(temporary)
        snapshot = None
        phases = ("cold", "warm", "repaired") if windows else ("smoke",)
        for phase in phases:
            if phase == "repaired":
                next(cache.rglob("*.dll")).write_bytes(b"corrupted cache regression check")
            if run_application(executable, environment, results, report, phase) != 0:
                return 1
            if windows:
                files = {str(path.relative_to(cache)): hashlib.sha256(path.read_bytes()).hexdigest()
                         for path in cache.rglob("*.dll")}
                if not files or (snapshot is not None and files != snapshot):
                    print("FAIL: native DLL cache is missing or has incorrect contents.", file=sys.stderr)
                    return 1
                snapshot = files
                if list(executable.parent.iterdir()) != [executable]:
                    print("FAIL: startup wrote extra files beside the executable.", file=sys.stderr)
                    return 1
    return 0


def run_application(executable, environment, results, report, phase):
    report.unlink(missing_ok=True)
    try:
        process = subprocess.run(
            [str(executable), "--aot-smoke-test", str(report)],
            cwd=executable.parent,
            env=environment,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=60,
        )
    except subprocess.TimeoutExpired as error:
        (results / f"timeout-{phase}.txt").write_text(str(error), encoding="utf-8")
        print("FAIL: application did not finish within 60 seconds.", file=sys.stderr)
        return 1

    (results / f"stdout-{phase}.txt").write_text(process.stdout, encoding="utf-8")
    (results / f"stderr-{phase}.txt").write_text(process.stderr, encoding="utf-8")
    output = report.read_text(encoding="utf-8") if report.exists() else "Missing smoke-test report."
    (results / f"smoke-test-{phase}.txt").write_text(output, encoding="utf-8")
    print(f"=== {phase} ===")
    print(output)
    if process.returncode != 0 or "AOT_SMOKE_TEST_PASSED" not in output.splitlines():
        print(process.stderr, file=sys.stderr)
        print(f"FAIL: application exited with code {process.returncode}.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
