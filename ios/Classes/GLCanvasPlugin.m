#import "GLCanvasPlugin.h"
#import "GLView.h"

@interface GLCanvasViewFactory : NSObject <FlutterPlatformViewFactory>
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end

@interface GLCanvasView : NSObject <FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

- (UIView*)view;
@end

@implementation GLCanvasPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"gl_canvas"
              binaryMessenger:[registrar messenger]];
      GLCanvasPlugin* instance = [[GLCanvasPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    GLCanvasViewFactory* factory =
        [[GLCanvasViewFactory alloc] initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:factory withId:@"gl_canvas_view"];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(FlutterMethodNotImplemented);
}

@end


@implementation GLCanvasViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[GLCanvasView alloc] initWithFrame:frame
                              viewIdentifier:viewId
                                   arguments:args
                             binaryMessenger:_messenger];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return FlutterStandardMessageCodec.sharedInstance;
}

@end

NSMutableDictionary<NSNumber *, GLView *> *_caches;

@implementation GLCanvasView {
    GLView      *_view;
    NSInteger   _viewId;
    
    FlutterEngine *_flutterEngine;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if (self = [super init]) {
      @synchronized (GLCanvasView.class) {
          frame.size.width = [args[@"width"] floatValue];
          frame.size.height = [args[@"height"] floatValue];
          _view = [[GLView alloc] initWithFrame:frame];
          _view.scale = [UIScreen mainScreen].scale;
          _viewId = [[args objectForKey:@"id"] integerValue];
          
          if (!_caches) {
              _caches = [NSMutableDictionary dictionary];
          }
          [_caches setObject:_view forKey:@(_viewId)];
      }
  }
  return self;
}

- (UIView*)view {
    return _view;
}

- (void)dealloc {
    @synchronized (GLCanvasView.class) {
        _view.disabled = YES;
        [_caches removeObjectForKey:@(_viewId)];
    }
}

@end

void* glCanvasSetup(int viewId) {
    @synchronized (GLCanvasView.class) {
        GLView *glView = [_caches objectForKey:@(viewId)];
        if (glView) {
            [glView setup];
            return (void *)CFBridgingRetain(glView);
        } else {
            return nil;
        }
    }
}

int glCanvasStep(void *ptr) {
    GLView *glView = (__bridge GLView *)ptr;
    if (glView.disabled) {
        return 0;
    } else {
        [glView enable];
        return 1;
    }
}

OpenGLCanvasInfo *glCanvasGetInfo(void *ptr) {
    GLView *glView = (__bridge GLView *)ptr;
    return glView.information;
}

void glCanvasRender(void *ptr) {
    GLView *glView = (__bridge GLView *)ptr;
    [glView commit];
}

void glCanvasStop(void *ptr) {
    CFBridgingRelease(ptr);
}
