
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

class GLCanvasController extends ValueNotifier<GLValue> {
  static const MethodChannel _channel = const MethodChannel('gl_canvas');

  late Future<void> _ready;

  Future<void> get ready => _ready;

  GLCanvasController({
    double width = 512,
    double height = 512,
  }) : super(GLValue._()) {
    _ready = _setup(width, height);
  }

  Future<void> _setup(double width, double height) async {
    value = value._copy(
      textureId: await _channel.invokeMethod<int>("init", {
        "width": width,
        "height": height,
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

class GLCanvas extends StatefulWidget {

  final GLCanvasController? controller;

  GLCanvas({
    Key? key,
    this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => GLCanvasState();
}

typedef QueueAction<T> = Future<T> Function();

class GLCanvasState extends State<GLCanvas> {

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
  void didUpdateWidget(covariant GLCanvas oldWidget) {
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
