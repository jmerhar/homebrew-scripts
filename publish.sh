#!/bin/bash

# A script to create or update a Homebrew formula file and a Debian package.
# It lives in the root of the 'homebrew-scripts' repository and
# takes the relative path of the script to be published as its single argument.
# It automatically parses the README.md file for the script's description and dependencies.

# --- Configuration ---
# The parent directory containing both repositories.
PARENT_DIR="$( cd "$(dirname "$0")/.." >/dev/null 2>&1 ; pwd -P )"
# Your GitHub username and the name of your scripts repository.
GITHUB_USER="jmerhar"
SCRIPTS_REPO="scripts"
# The name of your Homebrew tap repository.
HOMEBREW_TAP_REPO="homebrew-scripts"
# The maintainer's name and email for Debian packages.
MAINTAINER_INFO="Jure Merhar <dev@merhar.si>"

# --- Script Functions ---

# Parses the script path to get the formula name and the README path.
# Globals: SCRIPT_PATH, README_PATH, FORMULA_NAME
function parse_script_info() {
  # The relative path to the script within the 'scripts' repository.
  SCRIPT_PATH="$1"

  if [ -z "${SCRIPT_PATH}" ]; then
    echo "Error: No script path provided."
    echo "Usage: $0 <path-to-script-in-repo>"
    echo "Example: $0 utility/unlock-pdf.sh"
    exit 1
  fi

  # Extract the base name to use for the formula file and command.
  FORMULA_NAME=$(basename "${SCRIPT_PATH}")
  FORMULA_NAME=${FORMULA_NAME%.*}

  # The path to the README file. Assumes the README is in the same directory as the script.
  README_PATH="${PARENT_DIR}/${SCRIPTS_REPO}/$(dirname "${SCRIPT_PATH}")/README.md"
}

# Fetches the latest release info from the GitHub API.
# Globals: TARBALL_URL, SHA256_CHECKSUM, VERSION
function fetch_release_info() {
  local api_url="https://api.github.com/repos/${GITHUB_USER}/${SCRIPTS_REPO}/releases/latest"
  echo "Fetching latest release information from GitHub..."

  local release_info=$(curl -s "${api_url}")
  if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch release information. Check your internet connection."
    exit 1
  fi

  # Use 'sed' to extract the tarball URL and version from the JSON response.
  TARBALL_URL=$(echo "${release_info}" | sed -nE 's/.*"tarball_url": "([^"]+)".*/\1/p')
  VERSION=$(echo "${release_info}" | sed -nE 's/.*"tag_name": "([^"]+)".*/\1/p')

  if [ -z "${TARBALL_URL}" ] || [ -z "${VERSION}" ]; then
    echo "Error: Could not find a release for the scripts repository."
    echo "Please create a release on GitHub first."
    exit 1
  fi

  echo "Found latest release: ${VERSION}"
  echo "Downloading tarball to calculate SHA256 checksum..."

  SHA256_CHECKSUM=$(curl -sSL "${TARBALL_URL}" | shasum -a 256 | awk '{print $1}')
  if [ -z "${SHA256_CHECKSUM}" ]; then
    echo "Error: Failed to calculate checksum. Check if the tarball URL is valid."
    exit 1
  fi
  echo "Checksum calculated: ${SHA256_CHECKSUM}"
}

# Parses the script's README for its description and dependencies.
# Globals: DESCRIPTION, DEPENDENCIES
function parse_readme() {
  echo "Parsing README.md for description and dependencies..."

  if [ ! -f "${README_PATH}" ]; then
    echo "Error: README.md not found at '${README_PATH}'"
    exit 1
  fi

  # Use awk to find the description text.
  DESCRIPTION=$(awk -v script_name="### \`*${FORMULA_NAME}.*\`*" '
      BEGIN {found_heading=0; description=""}
      $0 ~ script_name { found_heading=1; next }
      found_heading && !/^[[:space:]]*$/ && description=="" {
          description=$0
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", description)
      }
      END { print description }
  ' "${README_PATH}")

  if [ -z "${DESCRIPTION}" ]; then
    echo "Error: Could not find description for '${FORMULA_NAME}' in README.md."
    echo "Please ensure there is a markdown heading '### <script-name>' followed by a description."
    exit 1
  fi

  # Use `awk` to find and format dependencies by extracting the text between the first and second backticks on each line.
  # This version is compatible with the standard awk on macOS.
  DEPENDENCIES=$(awk '
      /^#### Dependencies/ { in_deps_section = 1; next }
      in_deps_section && /^-/ {
          if (match($0, /`[^`]+`/)) {
              # Use substr and the built-in RSTART and RLENGTH variables
              # to extract the content between the backticks.
              dep_name = substr($0, RSTART + 1, RLENGTH - 2)
              if (length(dep_name) > 0) {
                  printf "  depends_on \"%s\"\n", dep_name;
              }
          }
      }
      in_deps_section && !/^-/ {
          # Stop processing when the list ends (e.g., with an empty line or a new section).
          in_deps_section = 0;
      }
  ' "${README_PATH}")

  # Check if dependencies were parsed successfully.
  if [ -z "${DEPENDENCIES}" ]; then
    echo "Warning: Could not find any dependencies. Please ensure the format is correct."
  fi
}

# Generates the Homebrew formula file.
function generate_homebrew_formula() {
  local formula_file="${PARENT_DIR}/${HOMEBREW_TAP_REPO}/Formula/${FORMULA_NAME}.rb"

  # Use awk to convert hyphenated name to CamelCase.
  local class_name=$(echo "${FORMULA_NAME}" | awk -F'-' '{
    for (i=1; i<=NF; i++) {
        printf "%s", toupper(substr($i,1,1)) substr($i,2)
    }
    print ""
  }')

  echo "Creating or updating Homebrew formula file at 'Formula/${FORMULA_NAME}.rb'..."

  cat <<EOF > "${formula_file}"
# This file was generated by the publish.sh script.
class ${class_name} < Formula
  desc "${DESCRIPTION}"
  homepage "https://github.com/${GITHUB_USER}/${SCRIPTS_REPO}"
  url "${TARBALL_URL}"
  sha256 "${SHA256_CHECKSUM}"

$(echo "${DEPENDENCIES}")

  def install
    # This line installs the script into Homebrew's binary directory.
    # The script is installed from its relative path in the tarball.
    bin.install "${SCRIPT_PATH}" => "${FORMULA_NAME}"
  end
end
EOF

  echo "Homebrew formula file 'Formula/${FORMULA_NAME}.rb' has been updated successfully."
}

# Generates the Debian (.deb) package.
function generate_deb_package() {
  echo "Attempting to generate a Debian (.deb) package for Linux..."

  # Check if dpkg-deb is installed.
  if ! command -v dpkg-deb &> /dev/null; then
    echo "Warning: 'dpkg-deb' could not be found. Skipping .deb package generation."
    return 1
  fi

  local package_dir="${PARENT_DIR}/${SCRIPTS_REPO}/${FORMULA_NAME}-${VERSION}"
  local control_dir="${package_dir}/DEBIAN"
  local bin_dir="${package_dir}/usr/local/bin"
  local script_file="${PARENT_DIR}/${SCRIPTS_REPO}/${SCRIPT_PATH}"

  # Remove the 'v' prefix from the version number to comply with Debian standards.
  local deb_version=${VERSION#v}
  local deb_file="${PARENT_DIR}/${SCRIPTS_REPO}/${FORMULA_NAME}_${deb_version}_all.deb"

  # Clean up any previous build attempts.
  if [ -d "${package_dir}" ]; then
    rm -rf "${package_dir}"
  fi

  # Create the necessary directory structure for the package.
  mkdir -p "${control_dir}"
  mkdir -p "${bin_dir}"

  echo "Creating control file..."
  # Clean up the Homebrew format and join dependencies with commas for the control file.
  local deb_depends=$(echo "${DEPENDENCIES}" | sed 's/  depends_on "//g; s/"//g' | tr '\n' ',' | sed 's/,$//')

  cat <<EOF > "${control_dir}/control"
Package: ${FORMULA_NAME}
Version: ${deb_version}
Section: utils
Priority: optional
Architecture: all
Depends: ${deb_depends}
Maintainer: ${MAINTAINER_INFO}
Description: ${DESCRIPTION}
 This package installs the '${FORMULA_NAME}' script.
EOF

  # Copy the script into the correct location within the package directory.
  cp "${script_file}" "${bin_dir}/${FORMULA_NAME}"
  # Make the script executable.
  chmod +x "${bin_dir}/${FORMULA_NAME}"

  echo "Building the .deb package..."
  dpkg-deb --build "${package_dir}" "${deb_file}"

  echo "Cleaning up temporary build directory..."
  rm -rf "${package_dir}"

  if [ -f "${deb_file}" ]; then
    echo "Debian package '${FORMULA_NAME}_${deb_version}_all.deb' created successfully."
  else
    echo "Error: Failed to create the Debian package."
    return 1
  fi
}

# --- Main Logic ---
function main() {
  parse_script_info "$1"
  fetch_release_info
  parse_readme
  generate_homebrew_formula
  generate_deb_package
  echo "Publication process complete. Remember to commit and push the changes."
}

main "$@"
