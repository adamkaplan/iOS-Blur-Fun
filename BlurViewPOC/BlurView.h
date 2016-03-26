//
//  BlurView.h
//  BlurViewPOC
//
//  Created by Adam Kaplan on 3/26/16.
//  Copyright © 2016 Yahoo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlurView : UIView

/**
 *  View to use as the basis for blurring in the receiver.
 */
@property (nonatomic) UIView *contentView;

/**
 *  Blur radius that is used during rendering, set into the underlying CIGaussianBlur CIFilter.
 */
@property (nonatomic) CGFloat blurRadius;

@end
