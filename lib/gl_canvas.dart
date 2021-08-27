
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'gl_context.dart';
import 'gl_ffi.dart';


abstract class GLCanvasController {
  Duration get frameDuration;

  bool shouldRender(GLContext ctx, int tick);
  void onFrame(GLContext ctx, int tick);

  void dispose();
}

typedef GLCanvasBuilder = GLCanvasController Function(ReceivePort receivePort);

class GLCanvas extends StatefulWidget {

  final GLCanvasBuilder builder;
  final double? width;
  final double? height;

  GLCanvas({
    required this.builder,
    this.width,
    this.height,
  });

  @override
  State<StatefulWidget> createState() => _GLCanvasState();
}

class _SendInfo {
  int viewId;
  int methodHandler;
  SendPort sendPort;

  _SendInfo({
    required this.viewId,
    required this.sendPort,
    required this.methodHandler,
  });
}

class _GLCanvasState extends State<GLCanvas> {
  static const MethodChannel _channel =
    const MethodChannel('gl_canvas');
  static int _idCounter = 0x10002;

  int viewId = _idCounter++;
  late ReceivePort receivePort;
  SendPort? sendPort;
  late Isolate isolate;
  bool disposed = false;

  @override
  void initState() {
    super.initState();

    newIsolate(viewId);
  }

  @override
  void dispose() {
    super.dispose();

    sendPort?.send("gl.stop");
    disposed = true;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: "gl_canvas_view",
        creationParams: {
          "id": viewId,
          "width": widget.width ?? 0,
          "height": widget.height ?? 0
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: "gl_canvas_view",
        creationParams: {
          "id": viewId,
          "width": widget.width ?? 0,
          "height": widget.height ?? 0
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      throw Exception("The platform not supported");
    }
  }

  static void setup(_SendInfo port) async {
    GLCanvasBuilder builder = PluginUtilities
        .getCallbackFromHandle(
        CallbackHandle.fromRawHandle(port.methodHandler)
    ) as GLCanvasBuilder;

    ReceivePort receivePort = ReceivePort();
    port.sendPort.send(receivePort.sendPort);

    int runState = 0;

    ReceivePort otherPort = ReceivePort();

    void run() async {
      runState = 1;
      var ptr = Binder().glCanvasSetup(port.viewId);
      if (ptr.address != 0) {
        GLContext ctx = GLContext(ptr);
        GLCanvasController controller = builder(otherPort);
        bool firstTime = true;

        Timer timer;
        timer = Timer.periodic(controller.frameDuration, (timer) {
          if (runState != 1) {
            timer.cancel();
            controller.dispose();
            Binder().glCanvasStop(ptr);
            Isolate.current.kill(priority: Isolate.immediate);
            return;
          }
          ctx.updateInfo();
          bool ready = ctx.width > 0 && ctx.height > 0;
          if (ready) {
            if (firstTime || controller.shouldRender(ctx, timer.tick)) {
              firstTime = false;
              Binder().glCanvasStep(ptr);
              controller.onFrame(ctx, timer.tick);
              Binder().glCanvasRender(ptr);
            }
          }
        });
      }
    }
    receivePort.listen((message) {
      switch(message) {
        case 'gl.run': {
          run();
          break;
        }
        case 'gl.stop': {
          if (runState == 0) {
            Isolate.current.kill(priority: Isolate.immediate);
          } else {
            runState = 2;
          }
          break;
        }
        default: {
          otherPort.sendPort.send(message);
          break;
        }
      }
    });

  }

  void newIsolate(int viewId) async {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn(setup, _SendInfo(
        viewId: viewId,
        sendPort: receivePort.sendPort,
        methodHandler: PluginUtilities.getCallbackHandle(widget.builder)!.toRawHandle()
    ));
    sendPort = await receivePort.firstWhere((element) => element is SendPort);
    if (disposed) {
      sendPort!.send("gl.stop");
    } else {
      sendPort!.send("gl.run");
    }
  }
}
