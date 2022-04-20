
import 'package:gl_canvas/gl_canvas.dart';

import 'main.dart';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:opengl_es_bindings/opengl_es_bindings.dart';
import 'package:ffi/ffi.dart';

class IOCanvasRenderer extends CanvasRenderer {
  bool _init = false;
  late Pointer<Float> vertices;
  LibOpenGLES gl = LibOpenGLES(
      Platform.isAndroid ?
      DynamicLibrary.open("libGLESv3.so"):
      DynamicLibrary.process()
  );

  @override
  Duration get frameDuration => const Duration(milliseconds: 16);

  int width;
  int height;

  IOCanvasRenderer(this.width, this.height);

  int loadProgram(String vertex, String fragment) {
    int vertexShader = loadShader(GL_VERTEX_SHADER, vertex);
    if (vertexShader == 0)
      return 0;

    int fragmentShader = loadShader(GL_FRAGMENT_SHADER, fragment);
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

  int loadShader(int type, String shaderStr) {
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

  void init() {
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

  Random random = Random();
  void render() {
    if (!_init) {
      _init = true;
      init();
    }

    gl.glClearColor(random.nextDouble(), random.nextDouble(), random.nextDouble(), 1);
    gl.glClear(GL_COLOR_BUFFER_BIT);

    gl.glViewport(0, 0, width, height);

    gl.glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices.cast<Void>() );
    gl.glEnableVertexAttribArray(_positionSlot);

    gl.glDrawArrays(GL_TRIANGLES, 0, 3);

  }

  void dispose() {
    malloc.free(vertices);
  }
}


CanvasRenderer createRenderer(int width, int height, {GLCanvasController? controller}) {
  return IOCanvasRenderer(width, height);
}