//
//  BlurView.m
//  BlurViewPOC
//
//  Created by Adam Kaplan on 3/26/16.
//  Copyright © 2016 Yahoo, Inc. All rights reserved.
//

#import "BlurView.h"
#import <OpenGLES/ES2/gl.h>

@interface BlurView ()
// -- OpenGL Properties
@property (nonatomic, readonly) CAEAGLLayer *layer;
@property (nonatomic, readonly) EAGLContext *glContext;
// Identifer of the renderbuffer (where the current frame will be rendered).
@property (nonatomic, readonly) GLuint renderbuffer;

// -- CoreImage Properties
@property (nonatomic, readonly) CIContext *ciContext;
@property (nonatomic, readonly) CIImage *renderedContentView;
@property (nonatomic, readonly) CIFilter *blurFilter;
@end

@implementation BlurView

@dynamic layer;

+ (Class)layerClass
{
    // Set a custom EAGLLayer to manage rendering OpenGL in this layer-backed view.
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Create OpenGL 2.0 context to hold the render state
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSAssert(_glContext, @"Unable to create ES 2.0 EAGLContext object");
        
        // Make the current thread's render context our context
        [EAGLContext setCurrentContext:self.glContext];
        
        // Next we need to set up the renderbuffer. This is the memory where
        // the rendered image for the current frame will be stored.
        // Generate a single buffer and note its ID.
        glGenRenderbuffers(1, &_renderbuffer);
        
        // Bind the renderbuffer to the GL_RENDERBUFFER target so that
        // commands against this target use this particular renderbuffer.
        glBindRenderbuffer(GL_RENDERBUFFER, self.renderbuffer);
        
        // Allocate storage for the renderbuffer.
        [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.layer];
        
        // Finally, we need to set up the framebuffer. This is a chunk of memory
        // that will be used by OpenGL when rendering the current frame.
        // Generate a single buffer and note its ID.
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        
        // Bind the framebuffer to the GL_FRAMEBUFFER target so that
        // commands against this target use this particular framebuffer.
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        // Attach our renderbuffer to the framebuffer. The slot GL_COLOR_ATTACHMENT0
        // is the attachment point for a renderbuffer. Note how renderbuffers are
        // sometimes refered to as "color buffers" or "color renderbuffers" because
        // the end result of a render is a color image.
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.renderbuffer);
        
        // Set blending options (still need to enable/disable blending when needed, i.e. glEnable(GL_BLEND)
        // This allows the content view's transparency to be composited onto whatever is in the renderbuffer
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        glBlendEquation(GL_FUNC_ADD);
        
        // Disable color management, which Apple recommends to do for performance where precise color
        // fidelity isn't important (e.g. not for image editing)
        NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null] };
        _ciContext = [CIContext contextWithEAGLContext:self.glContext options:options];
        
        // This is the CoreImage filter. The filter are one-per-thread, so if we ever go to async render,
        // this would need to change.
        _blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    }
    return self;
}

- (void)renderGL
{
    // Set the clear color. Divide by 255 because the range for any given
    // channel is from 0 to 1, but with 8 bits per channel each one has
    // only 255 possible values.
    glClearColor(150.0/255.0, 200.0/255.0, 255.0/255.0, 0.25);
    
    // Clear the renderbuffer using the clear color.
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)renderCI
{
    if (!self.contentView) {
        return;
    }
    
    [self renderContentsIfNeeded];
    
    CGRect bounds = self.contentView.bounds;
    
    [self.blurFilter setValue:@(self.blurRadius) forKey:@"inputRadius"];
    
    // Render the base content on top of which the blurred content will be composited
    [self renderGL];
    
    // Enable pixel blending, and render the CoreImage filtered content
    glEnable(GL_BLEND);
    [self.ciContext drawImage:self.blurFilter.outputImage inRect:bounds fromRect:bounds];
    glDisable(GL_BLEND);
    
    // Present the renderbuffer to the screen.
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderContentsIfNeeded
{
    CALayer *layer = self.contentView.layer;
    if (![layer needsDisplay]) {
        return;
    }
    
    CGRect bounds = layer.bounds;
    
    // Draw the layer in an image context
    UIGraphicsBeginImageContext(bounds.size);
    
    [layer drawInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *renderedContent = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Creat CoreImage representation of the CGImage
    CIImage *ciImage = [CIImage imageWithCGImage:renderedContent.CGImage];
    _renderedContentView = ciImage;
    
    // Update the input image for the CIFilter chain
    [self.blurFilter setValue:ciImage forKey: @"inputImage"];
}

- (void)setContentView:(UIView *)contentView
{
    _contentView = contentView;
    [contentView.layer setNeedsDisplay];
    [self renderCI];
}

- (void)setBlurRadius:(CGFloat)blurRadius
{
    _blurRadius = blurRadius;
    [self renderCI];
}

@end
