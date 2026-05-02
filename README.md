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

Install Flutter by following the official installation guide:

https://docs.flutter.dev/get-started/install

From the repository root, check that Flutter can see the required platform tooling:

```sh
flutter doctor
```

Then fetch dependencies and run the test suite:

```sh
flutter pub get
flutter test
```

Launch the app on an available Flutter target:

```sh
flutter run
```

If platform directories have not been generated yet, run:

```sh
flutter create --platforms=android,ios,linux,macos,windows .
```
