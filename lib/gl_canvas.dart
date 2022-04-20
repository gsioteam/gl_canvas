
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'factory_stub.dart'
if (dart.library.io) 'gl_canvas_io.dart'
if (dart.library.html) 'gl_canvas_web.dart';

enum GLESVersion {
  GLES_10,
  GLES_20,
  GLES_30,
}

abstract class GLCanvasController extends ValueNotifier {
  Future<void> get ready;

  GLCanvasController.inherit(value) : super(value);

  factory GLCanvasController({
    double width = 512,
    double height = 512,
    GLESVersion version = GLESVersion.GLES_20,
  }) {
    return createControllerImp(
      width: width,
      height: height,
      version: version,
    );
  }

  void beginDraw();
  void endDraw();

  Object? get context => null;
}

typedef QueueAction<T> = Future<T> Function();

abstract class GLCanvas extends StatefulWidget {
  final GLCanvasController? controller;

  GLCanvas.inherit({
    Key? key,
    this.controller
  }) : super(key: key);

  factory GLCanvas({
    Key? key,
    GLCanvasController? controller,
  }) {
    return createCanvasImp(
      key: key,
      controller: controller,
    );
  }
}
