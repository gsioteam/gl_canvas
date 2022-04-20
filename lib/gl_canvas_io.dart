
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gl_canvas/gl_canvas.dart';

import 'ffi_bind.dart' as bind;

class GLValue {
  int? textureId;

  GLValue._();

  GLValue _copy({
    int? textureId,
  }) {
    GLValue value = GLValue._();
    value.textureId = textureId;
    return value;
  }
}

class IOGLCanvasController extends GLCanvasController {
  static const MethodChannel _channel = const MethodChannel('gl_canvas');

  late Future<void> _ready;

  Future<void> get ready => _ready;

  IOGLCanvasController({
    double width = 512,
    double height = 512,
    GLESVersion version = GLESVersion.GLES_20,
  }) : super.inherit(GLValue._()) {
    _ready = _setup(width, height, version);
  }

  Future<void> _setup(double width, double height, GLESVersion version) async {
    value = value._copy(
      textureId: await _channel.invokeMethod<int>("init", {
        "width": width,
        "height": height,
        "version": version.index + 1,
      }),
    );
    if (value.textureId != null) {
      bind.init(value.textureId!);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (value.textureId != null) {
      _channel.invokeMethod("destroy", {
        "id": value.textureId,
      });
    }
  }

  void beginDraw() {
    if (value.textureId == null) {
      throw Exception("textureId is null");
    }
    bind.prepare(value.textureId!);
  }

  void endDraw() {
    if (value.textureId == null) {
      throw Exception("textureId is null");
    }
    bind.render(value.textureId!);
  }
}

class IOGLCanvas extends GLCanvas {

  IOGLCanvas({
    Key? key,
    GLCanvasController? controller,
  }) : super.inherit(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => IOGLCanvasState();
}

class IOGLCanvasState extends State<IOGLCanvas> {

  @override
  Widget build(BuildContext context) {
    var textureId = widget.controller?.value.textureId;
    if (textureId != null) {
      if (Platform.isIOS) {
        return Transform(
          transform: Matrix4.diagonal3Values(1, -1, 1),
          alignment: Alignment.center,
          child: Texture(
            textureId: textureId,
          ),
        );
      } else {
        return Texture(
          textureId: textureId,
        );
      }
    } else {
      return Container();
    }
  }

  @override
  void initState() {
    super.initState();

    widget.controller?.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller?.removeListener(_update);
  }

  @override
  void didUpdateWidget(covariant IOGLCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_update);
      widget.controller?.addListener(_update);
    }
  }

  void _update() {
    setState(() {});
  }
}

GLCanvas createCanvasImp({
  Key? key,
  required GLCanvasController? controller,
}) {
  return IOGLCanvas(
    key: key,
    controller: controller,
  );
}

GLCanvasController createControllerImp({
  double width = 512,
  double height = 512,
  GLESVersion version = GLESVersion.GLES_20,
}) {
  return IOGLCanvasController(
    width: width,
    height: height,
    version: version,
  );
}