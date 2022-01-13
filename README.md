# gl_canvas

A OpenGLES context canvas in flutter.

## Usage

```dart
// define a controller
CanvasController controler;
//...
GLCanvas(
    controler: controler,
);
//...

controller.beginDraw();
// Run your GL code.
renderer.render();
controller.endDraw();
```