.PHONY: help sync dev test lint format clean lock generate render-rooms render-blocks

help:
	@echo "Available commands:"
	@echo "  make sync         - Sync dependencies with uv"
	@echo "  make dev          - Sync with development dependencies"
	@echo "  make test         - Run tests with pytest"
	@echo "  make lint         - Run linting with ruff"
	@echo "  make format       - Format code with ruff"
	@echo "  make lock         - Update uv.lock file"
	@echo "  make clean        - Clean build artifacts and cache"
	@echo ""
	@echo "Code generation:"
	@echo "  make generate     - Run all codegen scripts"
	@echo "  make render-rooms - Render all rooms to images"
	@echo "  make render-blocks- Render block examples"

sync:
	uv sync

dev:
	uv sync --all-extras

test:
	uv run pytest

lint:
	uv run ruff check python_scripts/src/

format:
	uv run ruff format python_scripts/src/

lock:
	uv lock

clean:
	rm -rf build dist *.egg-info .venv
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .ruff_cache -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# Code generation targets
generate:
	uv run python -m codegen.memory
	uv run python -m codegen.tiles
	uv run python -m codegen.sprites
	uv run python -m codegen.blocks
	uv run python -m codegen.rooms

render-rooms:
	uv run python -m tools.room_viewer

render-blocks:
	uv run python -m tools.block_viewer
