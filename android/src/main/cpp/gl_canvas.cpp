

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

JavaVM *_vm;

typedef struct {
    double width = 0;
    double height = 0;
} OpenGLCanvasInfo;

map<long, CacheInfo*> _dataIndex;
class CacheInfo {
    jobject object = nullptr;

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


    float scale = 0;
    int version = 2;
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

    long textureId;

public:
    OpenGLCanvasInfo information;

    CacheInfo(JNIEnv *env, jobject target, long textureId) {
        object = env->NewGlobalRef(target);
        _dataIndex[textureId] = this;
        this->textureId = textureId;
    }

    ~CacheInfo() {
        _dataIndex.erase(textureId);
        destroy();
        JNIEnv *env = this->env();
        env->DeleteGlobalRef(object);
        env->DeleteGlobalRef(surface);
        if (window)
            ANativeWindow_release(window);
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
                EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
//                EGL_SAMPLE_BUFFERS, 1,
//                EGL_SAMPLES, 2,
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
                EGL_CONTEXT_CLIENT_VERSION, version,
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

//        if (!eglSurfaceAttrib(eglDisplay, surface, EGL_SWAP_BEHAVIOR, EGL_BUFFER_PRESERVED)) {
//            LOGE("eglSurfaceAttrib() returned error %d", eglGetError());
//            destroy();
//            return ;
//        }

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

        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        render();
    }

    void surfaceReady(JNIEnv *env, double width, double height, float scale, jobject surface, int version) {
        this->scale = scale;
        this->version = version;
        this->information.width = width;
        this->information.height = height;
        this->surface = env->NewGlobalRef(surface);

    }

    void surfaceDestroy() {
        _display = EGL_NO_DISPLAY;
    }

    void step() {
        if (!eglMakeCurrent(_display, _surface, _surface, _context)) {
            LOGE("eglMakeCurrent() returned error %d", eglGetError());
        }
    }

    void render() {
        if (_display) {
            if (!eglSwapBuffers(_display, _surface)) {
//                LOGE("eglSwapBuffers() returned error %d", eglGetError());
            }
        }
    }

};

extern "C" {

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    _vm = vm;
    return JNI_VERSION_1_6;
}

void gl_init(int64_t textureId) {
    auto it = _dataIndex.find(textureId);
    if (it != _dataIndex.end()) {
        auto canvas = it->second;
        canvas->initialize();
    }
}

void gl_prepare(int64_t textureId) {
    auto it = _dataIndex.find(textureId);
    if (it != _dataIndex.end()) {
        it->second->step();
    }
}

void gl_render(int64_t textureId) {
    auto it = _dataIndex.find(textureId);
    if (it != _dataIndex.end()) {
        it->second->render();
    }
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLTexture_dispose(JNIEnv *env, jobject thiz, jlong ptr) {
    CacheInfo *info = (CacheInfo*)ptr;
    delete info;
}

JNIEXPORT jlong JNICALL
Java_com_ero_gl_1canvas_GLTexture_init(JNIEnv *env, jobject thiz, jlong textureId) {
    return (jlong)new CacheInfo(env, thiz, textureId);
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLTexture_surfaceReady(JNIEnv *env, jobject thiz, jlong ptr,
                                                   jobject surface, jdouble width, jdouble height,
                                                   jfloat scale, jint version) {
    CacheInfo *info = (CacheInfo*)ptr;
    info->surfaceReady(env, width, height, scale, surface, version);
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLTexture_surfaceDestroy(JNIEnv *env, jobject thiz, jlong ptr) {
    CacheInfo *info = (CacheInfo*)ptr;
    info->surfaceDestroy();
}

JNIEXPORT void JNICALL
Java_com_ero_gl_1canvas_GLTexture_resize(JNIEnv *env, jobject thiz, jlong ptr, jdouble width,
                                             jdouble height) {
    CacheInfo *info = (CacheInfo*)ptr;
    info->information.width = width;
    info->information.height = height;
}

}