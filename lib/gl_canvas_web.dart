
import 'dart:html';
import 'dart:js';

import 'package:flutter/foundation.dart';

import 'ui/shims/dart_ui.dart' as ui;
import 'package:flutter/widgets.dart';

import 'gl_canvas.dart';

int _idCounter = 0;

class GLValue {
  String? viewId;
  dynamic gl;

  GLValue._();

  GLValue _copy({
    String? viewId,
    dynamic gl,
  }) {
    GLValue value = GLValue._();
    value.viewId = viewId ?? this.viewId;
    value.gl = gl ?? this.gl;
    return value;
  }
}

class WebGLCanvasController extends GLCanvasController {

  int _viewId = _idCounter++;
  late CanvasElement _canvasElement;

  GLValue get value => super.value;

  final Future<void> ready = SynchronousFuture(null);

  WebGLCanvasController({
    double width = 512,
    double height = 512,
    GLESVersion version = GLESVersion.GLES_20,
  }) : super.inherit(GLValue._()) {
    _canvasElement = CanvasElement(
      width: width.toInt(),
      height: height.toInt(),
    );
    String viewId = "gl-canvas-$_viewId";
    dynamic gl;
    switch (version) {
      case GLESVersion.GLES_10:
        throw Exception("gles 1.0 is not supported.");
      case GLESVersion.GLES_20:
        gl = _canvasElement.getContext("webgl");
        break;
      case GLESVersion.GLES_30:
        gl = _canvasElement.getContext("webgl2");
        break;
    }
    value = value._copy(
      viewId: viewId,
      gl: gl,
    );
    _canvasElement.id = viewId;

    ui.platformViewRegistry.registerViewFactory(viewId, (viewId) => _canvasElement);
  }

  @override
  void beginDraw() {
  }

  @override
  void endDraw() {

  }

  Object? get context => value.gl;
}

class WebGLCanvas extends GLCanvas {
  WebGLCanvas({
    Key? key,
    GLCanvasController? controller,
  }) : super.inherit(key: key, controller: controller);

  @override
  State<StatefulWidget> createState() => WebGLCanvasState();
}

class WebGLCanvasState extends State<WebGLCanvas> {
  @override
  Widget build(BuildContext context) {
    if (widget.controller?.value.viewId != null) {
      return HtmlElementView(
        viewType: widget.controller?.value.viewId,
      );
    } else {
      return Container();
    }
  }
}

GLCanvas createCanvasImp({
  Key? key,
  required GLCanvasController? controller,
}) {
  return WebGLCanvas(
    key: key,
    controller: controller,
  );
}

GLCanvasController createControllerImp({
  double width = 512,
  double height = 512,
  GLESVersion version = GLESVersion.GLES_20,
}) {
  return WebGLCanvasController(
    width: width,
    height: height,
    version: version,
  );
}