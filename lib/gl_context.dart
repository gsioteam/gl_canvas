
import 'dart:ffi';

import 'gl_ffi.dart';

class GLContext {
  Pointer ptr;
  double _width = 0;
  double _height = 0;

  double get width => _width;
  double get height => _height;

  GLContext(this.ptr);

  void updateInfo() {
    var res = Binder().glCanvasGetInfo(ptr);
    _width = res.ref.width!;
    _height = res.ref.height!;
  }

}