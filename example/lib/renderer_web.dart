
import 'dart:math';

import 'package:gl_canvas/gl_canvas.dart';

import 'main.dart';

class WebCanvasRenderer extends CanvasRenderer {

  int width;
  int height;
  GLCanvasController controller;
  var gl;

  WebCanvasRenderer(this.width, this.height, this.controller);

  dynamic loadShader(int type, String shaderStr) {
    var shader = gl.createShader(type);

    gl.shaderSource(shader, shaderStr);

    // Compile the shader
    gl.compileShader(shader);

    return shader;
  }

  dynamic loadProgram(String vertex, String fragment) {

    var vertexShader = loadShader(gl.VERTEX_SHADER, vertex);
    var fragmentShader = loadShader(gl.FRAGMENT_SHADER, fragment);

    // Create the program object
    var programHandle = gl.createProgram();

    gl.attachShader(programHandle, vertexShader);
    gl.attachShader(programHandle, fragmentShader);

    // Link the program
    gl.linkProgram(programHandle);

    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    return programHandle;
  }

  var _programHandle;
  var _positionSlot;
  List<double> vertices = List.filled(9, 0);

  void init() {
    gl = controller.value.gl;

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

    gl.useProgram(_programHandle);

    _positionSlot = gl.getAttribLocation(_programHandle, "vPosition");
  }

  Random random = Random();
  @override
  void render() {
    if (gl == null) {
      init();
    }

    gl.clearColor(random.nextDouble(), random.nextDouble(), random.nextDouble(), 1);
    gl.clear(gl.COLOR_BUFFER_BIT);

    gl.viewport(0, 0, width, height);

    gl.vertexAttrib3fv(_positionSlot, vertices );
    gl.glEnableVertexAttribArray(_positionSlot);

    gl.glDrawArrays(gl.TRIANGLES, 0, 3);
  }

  void dispose() {
    gl.deleteProgram(_programHandle);
  }
}

CanvasRenderer createRenderer(int width, int height, {GLCanvasController? controller}) {
  return WebCanvasRenderer(width, height, controller!);
}