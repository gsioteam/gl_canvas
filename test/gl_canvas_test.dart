import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gl_canvas/gl_canvas.dart';

void main() {
  const MethodChannel channel = MethodChannel('gl_canvas');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
