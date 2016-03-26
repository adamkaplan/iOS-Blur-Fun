//
//  ViewController.m
//  BlurViewPOC
//
//  Created by Adam Kaplan on 3/26/16.
//  Copyright © 2016 Yahoo, Inc. All rights reserved.
//

#import "ViewController.h"
#import "BlurView.h"

@interface ViewController ()
@property (nonatomic) BlurView *blurView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _blurView = [[BlurView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    [self.view addSubview:self.blurView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.blurView.bounds];
    label.text = @"$23,917.20";
    label.font = [UIFont systemFontOfSize:25.0];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    self.blurView.contentView = label;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(panGestureAction:)];
    [self.view addGestureRecognizer:pan];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.blurView.center = self.view.center;
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture
{
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateChanged: {
            CGFloat yOffset = [panGesture translationInView:self.view].y;
            CGFloat blurRadius = ABS(yOffset / -50.0);
            self.blurView.blurRadius = blurRadius;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateBegan:
        default:
            break;
    }
}

@end
