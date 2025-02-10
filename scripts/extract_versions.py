import requests
from bs4 import BeautifulSoup
import re
import yaml

# URL of the directory containing .deb files
url = "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/"

# Fetch the HTML content of the directory
response = requests.get(url)
soup = BeautifulSoup(response.text, 'html.parser')

# Find all .deb files
deb_files = [a['href'] for a in soup.find_all('a', href=True) if a['href'].endswith('.deb')]

# Dictionary to store the latest minor version for each major version
latest_versions = {}

# Regular expression to extract version numbers
version_pattern = re.compile(r'microsoft-edge-stable_(\d+\.\d+\.\d+\.\d+)-(\d+)_amd64\.deb')

for deb_file in deb_files:
    match = version_pattern.search(deb_file)
    if match:
        full_version = match.group(1)  # Full version (e.g., 114.0.1823.51)
        revision = match.group(2)  # Revision number (e.g., 1)
        major_version = full_version.split('.')[0]  # Extract major version (e.g., 114)
        package_version = f"{full_version}-{revision}"  # Full package version (e.g., 114.0.1823.51-1)

        # Update the latest version for the major version
        if major_version not in latest_versions or package_version > latest_versions[major_version]:
            latest_versions[major_version] = package_version

# Function to write results to a YAML file
def write_to_yaml(latest_versions, filename="browser-matrix.yml"):
    # Prepare the data structure for YAML
    yaml_data = {
        "matrix": {
            "browser": {
                major_version: {
                    "EDGE_VERSION": f"microsoft-edge-stable={package_version}",
                    "EDGE_PACKAGE_VERSION": f"{package_version}"
                }
                for major_version, package_version in sorted(latest_versions.items(), key=lambda item: int(item[0]), reverse=True)
            }
        }
    }

    # Write to YAML file
    with open(filename, "w") as file:
        yaml.dump(yaml_data, file, default_flow_style=False, sort_keys=False)

    print(f"Results written to {filename}")

# Print the latest minor version for each major version
for major_version, latest_minor_version in sorted(latest_versions.items(), key=lambda item: int(item[0]), reverse=True):
    print(f"Latest version for {major_version}: {latest_minor_version}")

# Write results to YAML file
write_to_yaml(latest_versions)