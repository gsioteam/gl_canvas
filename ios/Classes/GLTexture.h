//
//  GLTexture.h
//  gl_canvas
//
//  Created by gen on 1/8/22.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLTexture : NSObject <FlutterTexture>

@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;

- (id)initWithWidth:(int32_t)width withHeight:(int32_t)height withVersion:(int32_t)version;

- (void)initialize;

- (void)setCurrent;
- (void)submit;

@end

NS_ASSUME_NONNULL_END
