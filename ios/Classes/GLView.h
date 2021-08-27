//
//  GPView.h
//  hirender_iOS
//
//  Created by mac on 2017/1/14.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLView;

typedef struct {
  double width;
  double height;
} OpenGLCanvasInfo;

@protocol GLViewDelegate <NSObject>

//@required
//- (void)glkView:(GLView *)view drawInRect:(CGRect)rect;

@end

@interface GLView : UIView
{
    BOOL updateFramebuffer;
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint stencilRenderbuffer;
    GLuint depthRenderbuffer;
    BOOL oglDiscardSupported;
}

@property (nonatomic, weak) id<GLViewDelegate> delegate;
@property (readonly, nonatomic, getter=isUpdating) BOOL updating;

@property (nonatomic, assign) float scale;

@property (nonatomic, assign) BOOL enableDepth;
@property (nonatomic, assign) BOOL enableStencil;

@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;

@property (nonatomic, readonly) EAGLContext *context;

@property (nonatomic, assign) BOOL disabled;

- (OpenGLCanvasInfo*)information;

- (void)setup;

- (void)swapBuffers;

- (void)enable;
- (void)commit;
- (void)invalidate;

- (NSData *)readPixels:(CGRect)rect;

@end
