package com.ero.gl_canvas;

import android.content.Context;

import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class GLCanvasViewFactory extends PlatformViewFactory {
    public GLCanvasViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new GLCanvasView(context, viewId, args);
    }
}
