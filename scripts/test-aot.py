"""Run the dedicated test executable's Native AOT regression checks."""

from concurrent.futures import ThreadPoolExecutor
import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    # Windows CI may default to cp1252; reports and diagnostics can contain Chinese.
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable")
    parser.add_argument("--installer", action="store_true", help="Check Windows EXE with native DLL sidecars")
    args = parser.parse_args()
    executable = Path(args.executable).resolve(strict=True)
    results = Path(".temp/test-results/aot/installer" if args.installer else ".temp/test-results/aot").resolve()
    results.mkdir(parents=True, exist_ok=True)
    report = results / "smoke-test.txt"
    report.unlink(missing_ok=True)

    if any(path.suffix.lower() == ".pdb" for path in executable.parent.rglob("*")):
        print("FAIL: publish directory contains PDB files.", file=sys.stderr)
        return 1
    windows = sys.platform == "win32"
    bundled = windows and not args.installer
    if args.installer and (not windows or not list(executable.parent.glob("*.dll"))):
        print("FAIL: Windows installer publish must contain native DLLs.", file=sys.stderr)
        return 1
    if bundled and list(executable.parent.iterdir()) != [executable]:
        print("FAIL: Windows publish must contain only the executable.", file=sys.stderr)
        return 1

    if list(executable.parent.glob("*.runtimeconfig.json")) or (executable.parent / (executable.stem + ".dll")).exists():
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
        phases = ("cold", "warm", "repaired") if bundled else ("smoke",)
        for phase in phases:
            if phase == "repaired":
                next(cache.rglob("*.dll")).write_bytes(b"corrupted cache regression check")
            if phase == "cold":
                # All three processes start with the same empty cache to exercise atomic extraction.
                with ThreadPoolExecutor(max_workers=3) as pool:
                    runs = [pool.submit(run_application, executable, environment, results,
                                        results / f"smoke-test-cold-{index}.txt", f"cold-{index}")
                            for index in range(3)]
                    exit_codes = [run.result() for run in runs]
                if any(exit_codes):
                    return 1
            elif run_application(executable, environment, results, report, phase) != 0:
                return 1
            if args.installer and list(cache.iterdir()):
                print("FAIL: installer application unexpectedly extracted native dependencies.", file=sys.stderr)
                return 1
            if bundled:
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
            [str(executable), str(report)],
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
