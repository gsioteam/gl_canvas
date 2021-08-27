
import 'dart:ffi';

import 'dart:io';

import 'package:ffi/ffi.dart';

typedef FGCanvasSetupFunc = Pointer Function(Int32 viewId);
typedef FGCanvasStepFunc = Void Function(Pointer canvas);
typedef FGCanvasGetInfoFunc = Pointer<OpenGLCanvasInfo> Function(Pointer canvas);

class OpenGLHandlers extends Struct {
  @Int32()
  int? i;
}

class OpenGLCanvasInfo extends Struct {
  @Double()
  double? width;
  @Double()
  double? height;
}

class Binder {
  final DynamicLibrary nativeGLib = Platform.isAndroid
      ? DynamicLibrary.open("libgl_canvas.so")
      : DynamicLibrary.process();

  late Pointer Function(int) glCanvasSetup;
  late void Function(Pointer) glCanvasStep;
  late FGCanvasGetInfoFunc glCanvasGetInfo;
  late void Function(Pointer) glCanvasRender;
  late void Function(Pointer) glCanvasStop;

  Binder._() {
    glCanvasSetup = nativeGLib
        .lookup<NativeFunction<FGCanvasSetupFunc>>("glCanvasSetup").asFunction();
    glCanvasStep = nativeGLib
        .lookup<NativeFunction<FGCanvasStepFunc>>("glCanvasStep").asFunction();
    glCanvasGetInfo = nativeGLib
        .lookup<NativeFunction<FGCanvasGetInfoFunc>>("glCanvasGetInfo").asFunction();
    glCanvasRender = nativeGLib
        .lookup<NativeFunction<Void Function(Pointer)>>("glCanvasRender").asFunction();
    glCanvasStop = nativeGLib
        .lookup<NativeFunction<Void Function(Pointer)>>("glCanvasStop").asFunction();
  }

  static Binder? _binder;
  factory Binder() {
    if (_binder == null) {
      _binder = Binder._();
    }
    return _binder!;
  }
}
