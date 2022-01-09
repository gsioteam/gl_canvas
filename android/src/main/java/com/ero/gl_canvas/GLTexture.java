package com.ero.gl_canvas;

import android.graphics.SurfaceTexture;
import android.opengl.GLES20;
import android.view.Surface;

import io.flutter.view.TextureRegistry;

public class GLTexture {

    static {
        System.loadLibrary("gl_canvas");
    }

    TextureRegistry.SurfaceTextureEntry textureEntry;
    Surface surface;
    private long ptr;

    GLTexture(TextureRegistry textureRegistry, int width, int height) {
        textureEntry = textureRegistry.createSurfaceTexture();

        SurfaceTexture surfaceTexture = textureEntry.surfaceTexture();
        surface = new Surface(surfaceTexture);
        surfaceTexture.setDefaultBufferSize(width, height);
        ptr = init(getTextureId());

        surfaceReady(ptr, surface, width, height, 1);
    }

    public void destroy() {
        surfaceDestroy(ptr);
        surface.release();
        textureEntry.release();
        dispose(ptr);
    }

    public long getTextureId() {
        return textureEntry.id();
    }

    private native long init(long textureId);
    private native void dispose(long ptr);
    private native void surfaceReady(long ptr, Surface surface, double width, double height, float scale);
    private native void surfaceDestroy(long ptr);
    private native void resize(long ptr, double width, double height);
}
