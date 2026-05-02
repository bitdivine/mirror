import 'dart:ffi';
import 'dart:io';

String get operatingSystemName => Platform.operatingSystem;

String get processorArchitecture => Abi.current().toString();
