# gl_canvas

A OpenGL context canvas in flutter.

## Usage

```dart
// New a GLCanvas require a builder
GLCanvas(
    builder: _builder,
)
```

The builder should return a `GLCanvasController`. and the 
builder must be a top level function or a static function.

```dart
class CanvasController extends GLCanvasController {
    LibOpenGLES gl = LibOpenGLES(
      Platform.isAndroid ?
      DynamicLibrary.open("libGLESv2.so"):
      DynamicLibrary.process()
  );


    @override
    bool shouldRender(GLContext ctx, int tick) => false;

    void onFrame(GLContext ctx, int tick) {
        gl.glClearColor(0, 1.0, 0, 1.0);
        gl.glClear(GL_COLOR_BUFFER_BIT);
        //...
    }

    @override
    void dispose() {}
}
```

GLCanvasController is running on a isolate, in this isolate you 
can derect using the OpenGLES API. In my example I using 
[opengl_es_bindings](https://pub.dev/packages/opengl_es_bindings)
to call the OpenGLES.