

#include <jni.h>
#include <android/native_window_jni.h>
#include <android/log.h>
#include <EGL/egl.h> // requires ndk r5 or newer
#include <GLES2/gl2.h>
#include <map>
#include <mutex>

#define  LOG_TAG  "egl"
#define LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG, __VA_ARGS__)
#define LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG, __VA_ARGS__)

using namespace std;

class CacheInfo;

map<int32_t, CacheInfo *> _cache;
JavaVM *_vm;

mutex global_mutex;

typedef struct {
    double width = 0;
    double height = 0;
} OpenGLCanvasInfo;

class CacheInfo {
    jobject object = nullptr;
    bool _init = false;
    int viewId;

    int retainCount = 1;

    ANativeWindow *window = nullptr;
    EGLDisplay _display = EGL_NO_DISPLAY;
    EGLSurface _surface;
    EGLContext _context;
    EGLint format;
    GLint _framebufferWidth;
    GLint _framebufferHeight;

    void destroy() {
        LOGI("Destroying context");
        eglMakeCurrent(_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(_display, _context);
        eglDestroySurface(_display, _surface);
        eglTerminate(_display);

        _display = EGL_NO_DISPLAY;
        _surface = EGL_NO_SURFACE;
        _context = EGL_NO_CONTEXT;
    }

    void initialize() {
        JNIEnv *env = this->env();
        window = ANativeWindow_fromSurface(env, surface);

        EGLDisplay eglDisplay;
        EGLConfig config;
        EGLint numberConfig;

        EGLSurface surface;
        EGLContext context;

        const EGLint configAttribs[] = {
                EGL_BUFFER_SIZE, 32,
                EGL_ALPHA_SIZE, 8,
                EGL_BLUE_SIZE, 8,
                EGL_GREEN_SIZE, 8,
                EGL_RED_SIZE, 8,
                EGL_STENCIL_SIZE, 8,
                EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
                EGL_SURFACE_TYPE, EGL_WINDOW_BIT | EGL_SWAP_BEHAVIOR_PRESERVED_BIT,
                EGL_SAMPLE_BUFFERS, 1,
                EGL_SAMPLES, 2,
                EGL_NONE
        };

        LOGE("initializing context");
        if ((eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY)) == EGL_NO_DISPLAY) {
            LOGE("eglGetDisplay() returned error %d", eglGetError());
            return ;
        }
        if (!eglInitialize(eglDisplay, 0, 0)) {
            LOGE("eglInitialize() returned error %d", eglGetError());
            return ;
        }
        if (!eglChooseConfig(eglDisplay, configAttribs, &config, 1, &numberConfig)) {
            LOGE("eglChooseConfig() returned error %d", eglGetError());
            destroy();
            return ;
        }
        if (!eglGetConfigAttrib(eglDisplay, config, EGL_NATIVE_VISUAL_ID, &format)) {
            LOGE("eglGetConfigAttrib() returned error %d", eglGetError());
            destroy();
            return ;
        }


        int contextAttribs[] = {
                EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL_NONE
        };

        if (!(context = eglCreateContext(eglDisplay, config, 0, contextAttribs))) {
            LOGE("eglCreateContext() returned error %d", eglGetError());
            destroy();
            return ;
        };

        ANativeWindow_setBuffersGeometry(window, 0, 0, format);

        if (!(surface = eglCreateWindowSurface(eglDisplay, config, window, 0))) {
            LOGE("eglCreateWindowSurface() returned error %d", eglGetError());
            destroy();
            return ;
        }

        if (!eglSurfaceAttrib(eglDisplay, surface, EGL_SWAP_BEHAVIOR, EGL_BUFFER_PRESERVED)) {
            LOGE("eglSurfaceAttrib() returned error %d", eglGetError());
            destroy();
            return ;
        };

        if (!eglMakeCurrent(eglDisplay, surface, surface, context)) {
            LOGE("eglMakeCurrent() returned error %d", eglGetError());
            destroy();
            return ;
        }
        if (!eglQuerySurface(eglDisplay, surface, EGL_WIDTH, &_framebufferWidth) ||
            !eglQuerySurface(eglDisplay, surface, EGL_HEIGHT, &_framebufferHeight)) {
            LOGE("eglQuerySurface() returned error%d", eglGetError());
            destroy();
            return ;
        }


        _display = eglDisplay;
        _surface = surface;
        _context = context;
        LOGE("EGL INIT SUCCESS");
    }
    float scale = 0;
    jobject surface = nullptr;

    JNIEnv *env() {
        if (_vm) {
            int status;
            JNIEnv *env;

            status = _vm->GetEnv((void **) &env, JNI_VERSION_1_6);
            if (status < 0) {
                status = _vm->AttachCurrentThread(&env, NULL);
                if (status < 0) {
                    return nullptr;
                }
            }
            return env;
        }
        return nullptr;
    }

public:
    OpenGLCanvasInfo information;

    CacheInfo(JNIEnv *env, jobject target, int viewId) : viewId(viewId) {
        lock_guard<mutex> lock(global_mutex);
        object = env->NewGlobalRef(target);
        _cache[viewId] = this;
    }

    ~CacheInfo() {
        destroy();
        JNIEnv *env = this->env();
        env->DeleteGlobalRef(object);
        env->DeleteGlobalRef(surface);
        if (window)
            ANativeWindow_release(window);
    }

    void surfaceReady(JNIEnv *env, double width, double height, float scale, jobject surface) {
        this->scale = scale;
        this->information.width = width;
        this->information.height = height;
        this->surface = env->NewGlobalRef(surface);
    }

    void surfaceDestroy() {
        _display = EGL_NO_DISPLAY;
    }

    void step() {
        if (!_init) {
            initialize();
            _init = true;
        }
    }

    void render() {
        if (_display) {
            if (!eglSwapBuffers(_display, _surface)) {
//                LOGE("eglSwapBuffers() returned error %d", eglGetError());
            }
        }
    }

    void retain() {
        retainCount++;
    }

    static void release(CacheInfo *info) {
        if (--info->retainCount == 0) {
            lock_guard<mutex> lock(global_mutex);
            _cache.erase(info->viewId);
            delete info;
        }
    }
};

extern "C" {

void* glCanvasSetup(int viewId) {
    lock_guard<mutex> lock(global_mutex);
    auto it = _cache.find(viewId);
    if (it != _cache.end()) {
        CacheInfo *info = it->second;
        info->retain();
        return info;
    } else {
        return nullptr;
    }
}

int glCanvasStep(void *ptr) {
    CacheInfo* info = (CacheInfo *)ptr;
    info->step();
    return 1;
}

OpenGLCanvasInfo *glCanvasGetInfo(void *ptr) {
    CacheInfo* info = (CacheInfo *)ptr;
    return &info->information;
}

void glCanvasRender(void *ptr) {
    CacheInfo* info = (CacheInfo *)ptr;
    info->render();
}

void glCanvasStop(void *ptr) {
    CacheInfo* info = (CacheInfo *)ptr;
    CacheInfo::release(info);
}

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    _vm = vm;
    return JNI_VERSION_1_6;
}


JNIEXPORT void JNICALL
        Java_com_ero_gl_1canvas_GLSurfaceView_dispose(JNIEnv *env, jobject thiz, jlong ptr) {
    CacheInfo *info = (CacheInfo*)ptr;
    CacheInfo::release(info);
}

JNIEXPORT jlong JNICALL
Java_com_ero_gl_1canvas_GLSurfaceView_init(JNIEnv *env, jobject thiz, jint view_id) {
    return (jlong)new CacheInfo(env, thiz, view_id);
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLSurfaceView_surfaceReady(JNIEnv *env, jobject thiz, jlong ptr,
                                            jobject surface, jdouble width, jdouble height,
                                            jfloat scale) {
    CacheInfo *info = (CacheInfo*)ptr;
    info->surfaceReady(env, width, height, scale, surface);
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLSurfaceView_surfaceDestroy(JNIEnv *env, jobject thiz, jlong ptr) {
    CacheInfo *info = (CacheInfo*)ptr;
//    info->surfaceDestroy();
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLSurfaceView_resize(JNIEnv *env, jobject thiz, jlong ptr, jdouble width,
                                             jdouble height) {
    CacheInfo *info = (CacheInfo*)ptr;
    info->information.width = width;
    info->information.height = height;
}

}
