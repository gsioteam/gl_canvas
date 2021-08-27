import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gl_canvas/gl_canvas.dart';
import 'package:gl_canvas/gl_context.dart';
import 'package:opengl_es_bindings/opengl_es_bindings.dart';
import 'package:ffi/ffi.dart';

void main() {
  runApp(MyApp());
}

class CanvasController extends GLCanvasController {
  bool _init = false;
  late Pointer<Float> vertices;
  LibOpenGLES gl = LibOpenGLES(
      Platform.isAndroid ?
      DynamicLibrary.open("libGLESv2.so"):
      DynamicLibrary.process()
  );

  @override
  Duration get frameDuration => const Duration(milliseconds: 16);


  int loadProgram(GLContext ctx, String vertex, String fragment) {
    int vertexShader = loadShader(ctx, GL_VERTEX_SHADER, vertex);
    if (vertexShader == 0)
      return 0;

    int fragmentShader = loadShader(ctx, GL_FRAGMENT_SHADER, fragment);
    if (fragmentShader == 0) {
      gl.glDeleteShader(vertexShader);
      return 0;
    }

    // Create the program object
    int programHandle = gl.glCreateProgram();
    if (programHandle == 0)
      return 0;

    gl.glAttachShader(programHandle, vertexShader);
    gl.glAttachShader(programHandle, fragmentShader);

    // Link the program
    gl.glLinkProgram(programHandle);

    gl.glDeleteShader(vertexShader);
    gl.glDeleteShader(fragmentShader);

    return programHandle;
  }

  int loadShader(GLContext ctx, int type, String shaderStr) {
    int shader = gl.glCreateShader(type);
    if (shader == 0) {
      print("Error: failed to create shader.");
      return 0;
    }

    var shaderPtr = shaderStr.toNativeUtf8();
    Pointer<Pointer<Int8>> thePtr = malloc.allocate(sizeOf<Pointer>());
    thePtr.value = shaderPtr.cast<Int8>();
    gl.glShaderSource(shader, 1, thePtr, Pointer.fromAddress(0));
    malloc.free(shaderPtr);
    malloc.free(thePtr);

    // Compile the shader
    gl.glCompileShader(shader);
    
    return shader;
  }

  late int _positionSlot;
  late int _programHandle;

  void init(GLContext ctx) {
    vertices = malloc.allocate(9 * sizeOf<Float>());
    vertices[0] = 0.0;
    vertices[1] = 0.5;
    vertices[2] = 0.0;
    vertices[3] = -0.5;
    vertices[4] = -0.5;
    vertices[5] = 0.0;
    vertices[6] = 0.5;
    vertices[7] = -0.5;
    vertices[8] = 0.0;

    _programHandle = loadProgram(
        ctx,
        """
attribute vec4 vPosition; 
 
void main(void)
{
    gl_Position = vPosition;
}
      """,
        """
precision mediump float;

void main()
{
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
      """
    );
    if (_programHandle == 0) {
      print(" >> Error: Failed to setup program.");
      return;
    }

    gl.glUseProgram(_programHandle);

    var ptr = "vPosition".toNativeUtf8();
    _positionSlot = gl.glGetAttribLocation(_programHandle, ptr.cast<Int8>());
    malloc.free(ptr);
  }

  @override
  bool shouldRender(GLContext ctx, int tick) {
    return false;
  }

  @override
  void onFrame(GLContext ctx, int tick) {
    if (!_init) {
      _init = true;
      init(ctx);
    }

    gl.glClearColor(0, 1.0, 0, 1.0);
    gl.glClear(GL_COLOR_BUFFER_BIT);

    gl.glViewport(0, 0, ctx.width.toInt(), ctx.height.toInt());

    gl.glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices.cast<Void>() );
    gl.glEnableVertexAttribArray(_positionSlot);

    gl.glDrawArrays(GL_TRIANGLES, 0, 3);

  }

  @override
  void dispose() {
    malloc.free(vertices);
  }
}

GLCanvasController _builder(ReceivePort receivePort) {
  return CanvasController();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool _display = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _display = true;
                    });
                  },
                  child: Text("On")
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _display = false;
                    });
                  },
                  child: Text("Off")
                )
              ],
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.blue,
                  child: Visibility(
                    child: GLCanvas(
                      builder: _builder,
                      width: 300,
                      height: 300,
                    ),
                    visible: _display,
                  ),
                ),
              )
            )
          ],
        ),
      ),
    );
  }
}
