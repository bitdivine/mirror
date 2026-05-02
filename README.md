# mirror

Minimal Flutter implementation of the cross-platform app feature.

The app renders visible placeholder content:

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

From the repository root, trust the local mise configuration, install the project tooling declared in `mise.toml`, and install Dart dependencies:

```sh
mise trust
mise install
mise run install
```

On Debian-family systems, install the host development packages needed for
Linux app builds and Debian package builds:

```sh
sudo apt install clang cmake desktop-file-utils dpkg-dev libgtk-3-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev ninja-build pkg-config
```

Check that Flutter can see the required platform tooling:

```sh
flutter doctor
```

Then run the test suite:

```sh
flutter test
```

Launch the app on an available Flutter target:

```sh
flutter run
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
