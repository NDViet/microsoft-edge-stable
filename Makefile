install_dependencies:
	python3 -m pip install -r ./scripts/requirements.txt

extract_version:
	python3 scripts/extract_versions.py
