.PHONY: help install dev test lint format clean

help:
	@echo "Available commands:"
	@echo "  make install    - Install the package in editable mode"
	@echo "  make dev        - Install with development dependencies"
	@echo "  make test       - Run tests with pytest"
	@echo "  make lint       - Run linting with ruff"
	@echo "  make format     - Format code with ruff"
	@echo "  make clean      - Clean build artifacts and cache"

install:
	.venv/bin/pip install -e .

dev:
	.venv/bin/pip install -e ".[dev]"

test:
	.venv/bin/pytest

lint:
	.venv/bin/ruff check src/

format:
	.venv/bin/ruff format src/

clean:
	rm -rf build dist *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .ruff_cache -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete