#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PYUCPP_DIR="$ROOT_DIR/pyucpp"
SETUP_ARGS=${SETUP_ARGS:-install --user}

cd "$ROOT_DIR"

command -v swig >/dev/null 2>&1 || {
    echo "error: swig is required" >&2
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "error: python3 is required" >&2
    exit 1
}

make libucpp.so
mkdir -p "$PYUCPP_DIR"

swig -python -outdir pyucpp ucpp.i
cp libucpp.so "$PYUCPP_DIR/libucpp.so"

cat > "$PYUCPP_DIR/setup.py" <<'PYEOF'
from pathlib import Path
from setuptools import Extension, setup
from setuptools.command.build_ext import build_ext

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


class BuildExt(build_ext):
    def run(self):
        super().run()
        for output in self.get_outputs():
            output_path = Path(output)
            if output_path.name.startswith("_ucpp"):
                self.copy_file(str(HERE / "libucpp.so"), str(output_path.parent / "libucpp.so"))


setup(
    name="pyucpp",
    version="0.1.0",
    description="Python bindings for ucpp generated with SWIG",
    py_modules=["ucpp"],
    ext_modules=[
        Extension(
            "_ucpp",
            sources=[str(ROOT / "ucpp_wrap.c")],
            include_dirs=[str(ROOT)],
            library_dirs=[str(HERE)],
            libraries=["ucpp"],
            runtime_library_dirs=["$ORIGIN"],
        )
    ],
    data_files=[("", ["libucpp.so"])],
    cmdclass={"build_ext": BuildExt},
    options={"egg_info": {"egg_base": "build"}},
)
PYEOF

cd "$PYUCPP_DIR"
python3 setup.py $SETUP_ARGS
