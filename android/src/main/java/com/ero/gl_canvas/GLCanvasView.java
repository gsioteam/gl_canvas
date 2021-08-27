package com.ero.gl_canvas;

import android.content.Context;
import android.view.View;

import java.util.Map;

import io.flutter.plugin.platform.PlatformView;

public class GLCanvasView implements PlatformView {

    private  GLSurfaceView surfaceView;

    GLCanvasView(Context context, int viewId, Object args) {
        Map map = (Map)args;
        int id = (int)map.get("id");
        double width = (double)map.get("width");
        double height = (double)map.get("height");
        surfaceView = new GLSurfaceView(context, id, width, height);
    }

    @Override
    public View getView() {
        return surfaceView;
    }

    @Override
    public void dispose() {
        surfaceView.destroy();
    }
}
