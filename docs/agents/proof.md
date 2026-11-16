# Proof

Run these checks in order from the repository root. Every command must exit zero.

| Check | Command |
| --- | --- |
| import | `godot --headless --path . --import` |
| test | `godot --headless --path . --script res://tests/run_tests.gd` |
| export-pack | `mkdir -p build && godot --headless --path . --export-pack Linux build/star-basket.pck` |
| uv-sync | `uv --cache-dir .cache sync --locked` |
| gdformat | `.venv/bin/gdformat --check scripts tests` |
| gdlint | `.venv/bin/gdlint scripts tests` |

## Requirements

- Godot 4.7.2 (standard build, not .NET) on `PATH` as `godot`. `project.godot` records only the 4.7 feature tag; 4.7.2 comes from the README. No export templates are needed for `export-pack`.
- Python 3.12 or newer and uv for `uv-sync`, which installs the locked gdtoolkit 4.5.0 into `.venv` for `gdformat` and `gdlint`.

## Coverage

- `export-pack`: `export_presets.cfg`
- `export-pack`: `main.tscn`
- `export-pack`: `project.godot`
- `export-pack`: `scripts/**`
- `gdformat`: `pyproject.toml`
- `gdformat`: `scripts/*.gd`
- `gdformat`: `tests/*.gd`
- `gdformat`: `uv.lock`
- `gdlint`: `pyproject.toml`
- `gdlint`: `scripts/*.gd`
- `gdlint`: `tests/*.gd`
- `gdlint`: `uv.lock`
- `import`: `export_presets.cfg`
- `import`: `main.tscn`
- `import`: `project.godot`
- `import`: `scripts/**`
- `import`: `tests/**`
- `test`: `main.tscn`
- `test`: `project.godot`
- `test`: `scripts/**`
- `test`: `tests/**`
- `uv-sync`: `pyproject.toml`
- `uv-sync`: `uv.lock`
- Review-only: `.github/workflows/proof.yml`
- Review-only: `.gitignore`
- Review-only: `AGENTS.md`
- Review-only: `CLAUDE.md`
- Review-only: `LICENSE`
- Review-only: `README.md`
- Review-only: `docs/agents/*.md`
