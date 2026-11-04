#!/usr/bin/env bash
# Attach edgedriver_linux64.zip to the GitHub release of an archived Edge build.
#
# Microsoft keeps only one msedgedriver build per major version on
# msedgedriver.microsoft.com and removes the LATEST_RELEASE_<major>_LINUX
# pointer once a major is retired. docker-selenium's NodeEdge/Dockerfile falls
# back to <release>/<version>-1/edgedriver_linux64.zip from this repo, so the
# driver has to be stored while Microsoft still serves it.
#
# Usage: archive_edgedriver.sh <release-tag> [--strict]
#   <release-tag>  e.g. 156.0.4314.58-1 (release must already exist)
#   --strict       fail when no driver can be fetched (default: warn and exit 0,
#                  because old builds may already be pruned upstream)
# Needs: gh (GH_TOKEN), curl, unzip. GITHUB_REPOSITORY is optional with gh.
set -euo pipefail
export LC_ALL=C

TAG="${1:?usage: $0 <release-tag> [--strict]}"
STRICT="${2:-}"
ASSET="edgedriver_linux64.zip"
BASE_URL="https://msedgedriver.microsoft.com"

BROWSER_VERSION="${TAG%-*}"
MAJOR="${BROWSER_VERSION%%.*}"

if gh release view "${TAG}" --json assets --jq '.assets[].name' | grep -qx "${ASSET}"; then
  echo "${TAG}: ${ASSET} already archived, nothing to do"
  exit 0
fi

# Pointer files are not plain ASCII, keep digits and dots only.
POINTER="$(curl -fsSL "${BASE_URL}/LATEST_RELEASE_${MAJOR}_LINUX" 2>/dev/null | tr -cd '0-9.' || true)"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

fetched=""
# Exact browser build first; fall back to the newest driver of the same major.
for candidate in "${BROWSER_VERSION}" "${POINTER}"; do
  [ -n "${candidate}" ] || continue
  case "${candidate}" in "${MAJOR}".*) ;; *) continue ;; esac
  if curl -fsSL -o "${WORKDIR}/${ASSET}" "${BASE_URL}/${candidate}/${ASSET}" \
    && unzip -tq "${WORKDIR}/${ASSET}" >/dev/null 2>&1 \
    && unzip -l "${WORKDIR}/${ASSET}" | grep -q ' msedgedriver$'; then
    fetched="${candidate}"
    break
  fi
done

if [ -z "${fetched}" ]; then
  msg="${TAG}: no edgedriver available from ${BASE_URL} (tried ${BROWSER_VERSION} and pointer '${POINTER}')"
  if [ "${STRICT}" = "--strict" ]; then
    echo "::error::${msg}"
    exit 1
  fi
  echo "::warning::${msg}"
  exit 0
fi

if [ "${fetched}" != "${BROWSER_VERSION}" ]; then
  echo "::notice::${TAG}: exact driver ${BROWSER_VERSION} not served, archived same-major driver ${fetched}"
fi

gh release upload "${TAG}" "${WORKDIR}/${ASSET}" --clobber
echo "${TAG}: archived ${ASSET} (driver ${fetched})"
