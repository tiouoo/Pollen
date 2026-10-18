"""Run the published desktop application's Native AOT regression checks."""

import os
from pathlib import Path
import subprocess
import sys


def main():
    executable = Path(sys.argv[1]).resolve(strict=True)
    results = Path("test-results/aot").resolve()
    results.mkdir(parents=True, exist_ok=True)
    report = results / "smoke-test.txt"
    report.unlink(missing_ok=True)

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
        (results / "timeout.txt").write_text(str(error), encoding="utf-8")
        print("FAIL: application did not finish within 60 seconds.", file=sys.stderr)
        return 1

    (results / "stdout.txt").write_text(process.stdout, encoding="utf-8")
    (results / "stderr.txt").write_text(process.stderr, encoding="utf-8")
    output = report.read_text(encoding="utf-8") if report.exists() else "Missing smoke-test report."
    print(output)
    if process.returncode != 0 or "AOT_SMOKE_TEST_PASSED" not in output.splitlines():
        print(process.stderr, file=sys.stderr)
        print(f"FAIL: application exited with code {process.returncode}.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
