import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

/// Give each test isolate its own GetStorage files. Flutter runs test files in
/// parallel, so a shared working-directory box fails with a file-lock error.
Future<Directory> initTestStorage() async {
  final directory = await Directory.systemTemp.createTemp('accountant-test-');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => directory.path,
  );
  await GetStorage.init();
  return directory;
}

Future<void> disposeTestStorage(Directory directory) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    null,
  );
  await directory.delete(recursive: true);
}
