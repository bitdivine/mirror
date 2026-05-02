import 'dart:async';

import 'package:flutter/material.dart';

import 'platform/platform_services.dart';

void main() {
  const platformServices = DefaultPlatformServices();
  runZonedGuarded(
    () {
      platformServices.logStartupPhase('before-run-app');
      runApp(const MirrorApp());
    },
    platformServices.logStartupError,
  );
}

class MirrorApp extends StatelessWidget {
  const MirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Mirror',
      home: MirrorHome(),
    );
  }
}

class MirrorHome extends StatelessWidget {
  const MirrorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hello world'),
      ),
    );
  }
}
