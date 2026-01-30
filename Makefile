.PHONY: help sync dev test lint format clean lock

help:
	@echo "Available commands:"
	@echo "  make sync       - Sync dependencies with uv"
	@echo "  make dev        - Sync with development dependencies"
	@echo "  make test       - Run tests with pytest"
	@echo "  make lint       - Run linting with ruff"
	@echo "  make format     - Format code with ruff"
	@echo "  make lock       - Update uv.lock file"
	@echo "  make clean      - Clean build artifacts and cache"

sync:
	uv sync

dev:
	uv sync --all-extras

test:
	uv run pytest

lint:
	uv run ruff check src/

format:
	uv run ruff format src/

lock:
	uv lock

clean:
	rm -rf build dist *.egg-info .venv
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .ruff_cache -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
