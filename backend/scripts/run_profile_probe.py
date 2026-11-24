"""Verificar cliente Dart, HTTP real y SQLite en un proceso y datos aislados."""

import argparse
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
from tempfile import TemporaryDirectory
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Elige una ruta nueva; no se sobrescribe evidencia")
    result = {"status": "failed"}
    with TemporaryDirectory(prefix="scaa-cu01-") as directory:
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        env = {**os.environ, "SCAA_ENV": "test", "SCAA_DATA_ROOT": directory}
        with (Path(directory) / "server.log").open("w+") as log:
            server = subprocess.Popen([sys.executable, "-m", "uvicorn", "scaa_backend.main:app",
                                       "--app-dir", str(ROOT / "backend"), "--host", "127.0.0.1",
                                       "--port", str(port)], env=env, stdout=log, stderr=log)
            try:
                base = f"http://127.0.0.1:{port}"
                for attempt in range(40):
                    if server.poll() is not None:
                        raise RuntimeError("El backend de prueba no inició")
                    try:
                        with urllib.request.urlopen(base + "/api/v1/health", timeout=1) as response:
                            if json.load(response).get("environment") == "test":
                                break
                    except OSError:
                        pass
                    time.sleep(0.1)
                else:
                    raise RuntimeError("El backend de prueba no respondió")
                probe = subprocess.run(["dart", "run", "tool/check_profile.dart", base],
                                       cwd=ROOT / "frontend", capture_output=True, text=True, timeout=60)
                result = json.loads(probe.stdout.strip())
                result["exit_code"] = probe.returncode
                result["isolation"] = "Proceso local y directorio temporal; perfil real dev/demo sin modificar"
                result["scope"] = "Cliente Dart real → API FastAPI → SQLite; interfaz visual separada"
            except Exception as error:
                result = {"status": "failed", "error": str(error)}
            finally:
                if server.poll() is None:
                    server.send_signal(signal.SIGINT)
                    try:
                        server.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        server.kill()
                        server.wait()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x") as out:
        json.dump(result, out, indent=2, ensure_ascii=False)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if result["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
