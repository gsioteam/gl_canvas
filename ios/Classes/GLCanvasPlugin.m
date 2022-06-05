#import "GLCanvasPlugin.h"
#import "GLTexture.h"


@interface GLCanvas : NSObject

@property (nonatomic, readonly) int64_t textureId;
@property (nonatomic, readonly) GLTexture *texture;

- (id)initWithTextureRegistry:(NSObject<FlutterTextureRegistry>*)textureRegistry
                    withWidth:(int32_t)width
                   withHeight:(int32_t)height
                  withVersion:(int32_t)version;

- (void)destroy;

- (void)prepare;
- (void)render;

@end

NSMutableDictionary<NSNumber *, GLCanvas *> *_canvasIndex;

@implementation GLCanvasPlugin {
    NSObject<FlutterTextureRegistry>* _textureRegistry;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"gl_canvas"
              binaryMessenger:[registrar messenger]];
      GLCanvasPlugin* instance = [[GLCanvasPlugin alloc] initWithTextureRegistry:registrar.textures];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (id)initWithTextureRegistry:(NSObject<FlutterTextureRegistry>*)textureRegistry {
    self = [super init];
    if (self) {
        _textureRegistry = textureRegistry;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        int32_t width = [call.arguments[@"width"] intValue];
        int32_t height = [call.arguments[@"height"] intValue];
        int32_t version = [call.arguments[@"version"] intValue];
        GLCanvas *canvas = [[GLCanvas alloc] initWithTextureRegistry:_textureRegistry
                                                           withWidth:width
                                                          withHeight:height
                                                         withVersion:version];
        if (!_canvasIndex) {
            _canvasIndex = [NSMutableDictionary dictionary];
        }
        [_canvasIndex setObject:canvas forKey:@(canvas.textureId)];
        result(@(canvas.textureId));
    } else if ([@"destroy" isEqualToString:call.method]) {
        int64_t _id = [call.arguments[@"id"] longLongValue];
        GLCanvas *canvas = _canvasIndex[@(_id)];
        [canvas destroy];
        [_canvasIndex removeObjectForKey:@(_id)];
        result(nil);
    }
    result(FlutterMethodNotImplemented);
}

@end

@implementation GLCanvas {
    NSObject<FlutterTextureRegistry> *_textureRegistry;
}

- (id)initWithTextureRegistry:(NSObject<FlutterTextureRegistry> *)textureRegistry
                    withWidth:(int32_t)width
                   withHeight:(int32_t)height
                  withVersion:(int32_t)version {
    self = [super init];
    if (self) {
        _textureRegistry = textureRegistry;
        _texture = [[GLTexture alloc] initWithWidth:width withHeight:height withVersion:version];
        _textureId = [textureRegistry registerTexture:_texture];
    }
    return self;
}

- (void)destroy {
    [_textureRegistry unregisterTexture:_textureId];
}

- (void)prepare {
    [self.texture setCurrent];
}

- (void)render {
    [self.texture submit];
    [_textureRegistry textureFrameAvailable:_textureId];
}

@end


void gl_init(int64_t textureId) {
    GLCanvas *canvas = [_canvasIndex objectForKey:@(textureId)];
    if (canvas) {
        [canvas.texture initialize];
    }
}

void gl_prepare(int64_t textureId) {
    GLCanvas *canvas = [_canvasIndex objectForKey:@(textureId)];
    if (canvas) {
        [canvas prepare];
    }
}

void gl_render(int64_t textureId) {
    GLCanvas *canvas = [_canvasIndex objectForKey:@(textureId)];
    if (canvas) {
        [canvas render];
    }
}
