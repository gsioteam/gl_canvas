package com.ero.gl_canvas;

import android.content.Context;
import android.graphics.PixelFormat;
import android.opengl.EGL14;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import androidx.annotation.NonNull;

public class GLSurfaceView extends SurfaceView implements SurfaceHolder.Callback {

    static  {
        System.loadLibrary("gl_canvas");
    }

    float scale;
    int viewId;
    double width;
    double height;
    long ptr;

    public GLSurfaceView(Context context, int viewId, double width, double height) {
        super(context);

        this.viewId = viewId;
        this.width = width;
        this.height = height;
        getHolder().addCallback(this);
        scale = getContext().getResources().getDisplayMetrics().density;
        ptr = init(viewId);
    }

    @Override
    public void surfaceCreated(@NonNull SurfaceHolder holder) {
        holder.setFormat(PixelFormat.TRANSPARENT);
        surfaceReady(ptr, holder.getSurface(), width, height, scale);
    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
        if (width != this.width || height != this.height) {
            this.width = width;
            this.height = height;
            resize(ptr, width, height);
        }
    }

    @Override
    public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
        surfaceDestroy(ptr);
    }

    public void destroy() {
        dispose(ptr);
    }

    private native void dispose(long ptr);
    
    native void surfaceReady(long ptr, Surface surface, double width, double height, float scale);
    native void surfaceDestroy(long ptr);
    native void resize(long ptr, double width, double height);

    native long init(int viewId);

}
