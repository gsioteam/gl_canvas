//
//  GPView.m
//  hirender_iOS
//
//  Created by mac on 2017/1/14.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GLView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#if false//(defined(__APPLE__) && !defined(DEBUG))
#define GL_ASSERT( gl_code ) gl_code
#else
#define GL_ASSERT( gl_code ) do \
{ \
gl_code; \
GLenum __gl_error_code = glGetError(); \
assert(__gl_error_code == GL_NO_ERROR); \
} while(0)
#endif


@interface GLView (Private)
- (BOOL)createFramebuffer;
- (void)deleteFramebuffer;
@end

@implementation GLView {
    BOOL _needsDisplay;
    CAEAGLLayer *_layer;
    OpenGLCanvasInfo _information;
    CGRect _frame;
}

@synthesize updating;

+ (void)load {
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        _layer = (id)self.layer;
        _scale = 1;
        // A system version of 3.1 or greater is required to use CADisplayLink.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
        {
            // Log the system version
            //NSLog(@"System Version: %@", currSysVer);
        }
        else
        {
            printf("Invalid OS Version: %s\n", (currSysVer == NULL?"NULL":[currSysVer cStringUsingEncoding:NSASCIIStringEncoding]));
            return nil;
        }
        
        // Check for OS 4.0+ features
        if ([currSysVer compare:@"4.0" options:NSNumericSearch] != NSOrderedAscending)
        {
            oglDiscardSupported = YES;
        }
        else
        {
            oglDiscardSupported = NO;
        }
        
        // Configure the CAEAGLLayer and setup out the rendering context
        CAEAGLLayer* layer = _layer;
        layer.opaque = TRUE;
        layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        // Initialize Internal Defaults
        updateFramebuffer = YES;
        defaultFramebuffer = 0;
        colorRenderbuffer = 0;
        depthRenderbuffer = 0;
        _framebufferWidth = 0;
        _framebufferHeight = 0;
        
        // Set the resource path and initalize the game
        //        NSString* bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
        //        FileSystem::setResourcePath([bundlePath fileSystemRepresentation]);
    }
    return self;
}

- (void)setup {
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    updateFramebuffer = YES;
    _layer.frame = self.bounds;
    _frame = frame;
//    [self display];
}

- (void)setScale:(float)scale {
    if (_scale != scale) {
        self.contentScaleFactor = scale;
        CAEAGLLayer* layer = (CAEAGLLayer *)self.layer;
        layer.contentsScale = scale;
        _scale = scale;
    }
}

- (void) dealloc
{
    NSLog(@"GLView dealloc");
}

- (BOOL)canBecomeFirstResponder
{
    // Override so we can control the keyboard
    return YES;
}

- (void) layoutSubviews
{
    // Called on 'resize'.
    // Mark that framebuffer needs to be updated.
    // NOTE: Current disabled since we need to have a way to reset the default frame buffer handle
    // in FrameBuffer.cpp (for FrameBuffer:bindDefault). This means that changing orientation at
    // runtime is currently not supported until we fix this.
    //updateFramebuffer = YES;
}

- (BOOL)createFramebuffer
{
    // iOS Requires all content go to a rendering buffer then it is swapped into the windows rendering surface
    assert(defaultFramebuffer == 0);
    
    // Create the default frame buffer
    GL_ASSERT( glGenFramebuffers(1, &defaultFramebuffer) );
    GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer) );
    
    // Create a color buffer to attach to the frame buffer
    GL_ASSERT( glGenRenderbuffers(1, &colorRenderbuffer) );
    GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer) );
    
    // Associate render buffer storage with CAEAGLLauyer so that the rendered content is display on our UI layer.
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_layer];
    
    // Attach the color buffer to our frame buffer
    GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer) );
    
    // Retrieve framebuffer size
    GL_ASSERT( glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth) );
    GL_ASSERT( glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight) );
    
    // If multisampling is enabled in config, create and setup a multisample buffer
    
    // Create default depth buffer and attach to the frame buffer.
    // Note: If we are using multisample buffers, we can skip depth buffer creation here since we only
    // need the color buffer to resolve to.
    GL_ASSERT( glGenRenderbuffers(1, &depthRenderbuffer) );
    GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer) );
    GL_ASSERT( glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _framebufferWidth, _framebufferHeight) );
    GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer) );
    GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer) );
    
    // Sanity check, ensure that the framebuffer is valid
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        //NSLog(@"ERROR: Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        [self deleteFramebuffer];
        return NO;
    }
    
    // If multisampling is enabled, set the currently bound framebuffer to the multisample buffer
    // since that is the buffer code should be drawing into (and FrameBuffr::initialize will detect
    // and set this bound buffer as the default one during initialization.
    GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer) );
    GL_ASSERT( glViewport(0, 0, _framebufferWidth, _framebufferHeight)); //
    return YES;
}

- (void)deleteFramebuffer
{
    [EAGLContext setCurrentContext:_context];
    if (defaultFramebuffer)
    {
        GL_ASSERT( glDeleteFramebuffers(1, &defaultFramebuffer) );
        defaultFramebuffer = 0;
    }
    if (colorRenderbuffer)
    {
        GL_ASSERT( glDeleteRenderbuffers(1, &colorRenderbuffer) );
        colorRenderbuffer = 0;
    }
    if (depthRenderbuffer)
    {
        GL_ASSERT( glDeleteRenderbuffers(1, &depthRenderbuffer) );
        depthRenderbuffer = 0;
    }
}

- (void)swapBuffers
{
    if (_context)
    {
        if (oglDiscardSupported)
        {
            // Performance hint to the GL driver that the depth buffer is no longer required.
            const GLenum discards[]  = { GL_DEPTH_ATTACHMENT };
            GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer) );
            GL_ASSERT( glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards) );
        }
        
        // Present the color buffer
        GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer) );
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
}

//- (void)display {
//    _needsDisplay = NO;
//}

//- (void)setNeedsDisplay {
//    if (!_needsDisplay) {
//        _needsDisplay = YES;
//        [self performSelectorOnMainThread:@selector(willDisplay)
//                               withObject:nil
//                            waitUntilDone:NO];
//    }
//}

//- (void)willDisplay {
//    if (_needsDisplay) {
//        [self display];
//    }
//}

- (void)enable {
    if (!_context) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    // Ensure our context is current
    if ([EAGLContext currentContext] != _context) {
        [EAGLContext setCurrentContext:_context];
    }
    
    // If the framebuffer needs (re)creating, do so
    if (updateFramebuffer)
    {
        updateFramebuffer = NO;
        [self deleteFramebuffer];
        [self createFramebuffer];
        NSLog(@"update frame %d %d", _framebufferWidth, _framebufferHeight);
        
    }
}

- (void)commit {
    
    // Execute a single game frame
    
//    [self.delegate glkView:self
//                drawInRect:self.bounds];
    
    // Present the contents of the color buffer
    [self swapBuffers];
    
}

- (NSData *)readPixels:(CGRect)rect {
    int results[4];
    [EAGLContext setCurrentContext:_context];
    glGetIntegerv(GL_VIEWPORT, results);
    NSMutableData *data = [NSMutableData data];
    int x = round(rect.origin.x), y = round(results[3] - rect.origin.y - rect.size.height),
    w = round(rect.size.width), h = round(rect.size.height);
    data.length = w * h * 4;
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), defaultFramebuffer);
    
    glFinish();
    
    GL_ASSERT(glReadPixels(x, y, w, h,
                 GL_RGBA, GL_UNSIGNED_BYTE, data.mutableBytes));
    
    size_t rowLen = w * 4;
    uint8_t *tmp = (uint8_t *)malloc(rowLen);
    uint8_t *ptr = (uint8_t *)data.mutableBytes;
    for (int i = 0, t = h/2; i < t; ++i) {
        memcpy(tmp, ptr + i * rowLen, rowLen);
        memcpy(ptr + i * rowLen, ptr + (h - i) * rowLen, rowLen);
        memcpy(ptr + (h - i) * rowLen, tmp, rowLen);
    }
    free(tmp);
    
    return data;
}

- (void)invalidate {
    [self deleteFramebuffer];
}

- (OpenGLCanvasInfo *)information {
    _information.width = _frame.size.width * _scale;
    _information.height = _frame.size.height * _scale;
    return &_information;
}

@end
