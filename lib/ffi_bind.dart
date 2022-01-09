
import 'dart:ffi';

import 'dart:io';

final DynamicLibrary nativeGLib = Platform.isAndroid
    ? DynamicLibrary.open("libgl_canvas.so")
    : DynamicLibrary.process();

void Function(int) init = nativeGLib
    .lookup<NativeFunction<Void Function(Int64)>>("gl_init")
    .asFunction();

void Function(int) prepare = nativeGLib
    .lookup<NativeFunction<Void Function(Int64)>>("gl_prepare")
    .asFunction();

void Function(int) render = nativeGLib
    .lookup<NativeFunction<Void Function(Int64)>>("gl_render")
    .asFunction();