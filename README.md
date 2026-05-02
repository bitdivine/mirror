# Mirror

Complete Flutter implementation of the Mirror spec.

The current app renders visible placeholder content:

```text
Hello world
```

## Supported Targets

The feature target list is Unix, macOS, Windows, iPhone, and Android. In Flutter build terms:

- Unix is represented by the Linux desktop target.
- macOS is represented by the Flutter macOS desktop target.
- Windows is represented by the Flutter Windows desktop target.
- iPhone is represented by the Flutter iOS target.
- Android is represented by the Flutter Android target.

## Getting Started

Install and activate mise by following the official installation guide:

https://mise.jdx.dev/

From the repository root, trust the local mise configuration, install the project tooling declared in `mise.toml`, install Dart dependencies, and install Git hooks:

```sh
mise trust
mise install
mise run install
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
