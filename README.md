# Introduction

Archive old .deb packages from https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/ as GitHub
releases.

[browser-matrix.yml](browser-matrix.yml) is the list of latest package version belong to each major version.

CI will run daily to check for new package version and create a new release if there is a new version.

[![Releases downloads](https://img.shields.io/github/downloads/NDViet/microsoft-edge-stable-deb/total.svg)](https://github.com/NDViet/microsoft-edge-stable-deb/releases)

## Edge driver archive

Microsoft removes old `msedgedriver` builds (and the `LATEST_RELEASE_<major>_LINUX` pointer) from
`msedgedriver.microsoft.com`, so each release also carries `edgedriver_linux64.zip`.
[scripts/archive_edgedriver.sh](scripts/archive_edgedriver.sh) downloads the driver that matches the release's
browser build (or, if that exact build is no longer served, the latest driver of the same major) and attaches it.
It runs after every archive in `fetch-latest.yml` and `archive-build.yml`, including for releases that already exist, so
`archive-build.yml` can be dispatched with a list of versions to backfill drivers while Microsoft still serves them.

docker-selenium's `NodeEdge/Dockerfile` reads `<release>/<version>-1/edgedriver_linux64.zip` from here when the driver is
no longer available from Microsoft.
