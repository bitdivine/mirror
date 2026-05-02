# Mirror

A cross-platform virtual mirror.

## Supported Targets

The feature target list is Unix, macOS, Windows, iPhone, and Android.

## Getting Started

Install and activate mise by following the official installation guide:

https://mise.jdx.dev/

From the repository root, trust the local mise configuration, install the project tooling declared in `mise.toml`, install Dart dependencies, and install Git hooks:

```sh
mise trust
mise install
mise run install
```

Flutter is also vendored at `vendor/flutter`. To use that vendored SDK as a
local mise install instead of downloading Flutter, initialise submodules and
link it before `mise install`:

```sh
git submodule update --init --recursive
mise run vendor:flutter:link
```

The install task configures this clone to use the committed hooks in `.githooks`.
The pre-push hook runs the test suite before Git allows a push.

On Debian-family systems, install the host development packages needed for
Linux app builds and Debian package builds from the Debian package metadata:

```sh
mise run install-apt-dev-deps
```

The apt development dependency list comes from `Build-Depends` in
`debian/control`.

Check that Flutter can see the required platform tooling:

```sh
flutter doctor
```

Then run the test suite:

```sh
mise run test
```

Launch the Linux app with verbose logs written to `log.txt`:

```sh
mise run linux
```

## Debian Package

Build the Debian package from the repository root:

```sh
mise run package-deb
```

The package is written to `dist/deb/` with a filename in the form
`mirror_<version>_<architecture>.deb`.

If platform directories have not been generated yet, run:

```sh
flutter create --platforms=android,ios,linux,macos,windows .
```
