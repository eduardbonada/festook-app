//
//  FestivalRevealVC.m
//  Festook
//
//  Created by Eduard Bonada Cruells on 14/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "FestivalRevealVC.h"

#import "FestivalMenuTVC.h"

@interface FestivalRevealVC ()

@property (weak, nonatomic) IBOutlet UITextView *festivalSummaryTextView;

@end

@implementation FestivalRevealVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self customizeRevealVC];
}


-(void) customizeRevealVC
{
    
    // INITIAL APPEARANCE
    self.frontViewPosition = FrontViewPositionRight; // FrontViewPositionLeft (only content), FrontViewPositionRight(menu and content), FrontViewPositionRightMost(only menu), ...
    
    // TOGGLING APPEARANCE
    self.rearViewRevealWidth = 190.0f; // how much of the menu is shown (default 260.0)
    self.rearViewRevealOverdraw = 0.0f; // how much of an overdraw can occur when dragging further than 'rearViewRevealWidth' (default 60.0)
    self.rearViewRevealDisplacement = 85.0f; // how much displacement is applied to the menu when animating or dragging the content (default 40.0)
    self.bounceBackOnOverdraw = NO; // If YES the controller will bounce to the Left position when dragging further than 'rearViewRevealWidth' (default YES)
    
    // DRAGGING ANIMATION
    self.toggleAnimationType = SWRevealToggleAnimationTypeEaseOut; // Animation type (SWRevealToggleAnimationTypeEaseOut or SWRevealToggleAnimationTypeSpring)
    self.springDampingRatio = 1.0f; // damping ratio if SWRevealToggleAnimationTypeSpring (default 1.0)
    self.toggleAnimationDuration = 0.3f; // Duration for the revealToggle animation (default 0.25)
    
    // SHADOW
    self.frontViewShadowRadius = 10.0f; // radius of the front view's shadow (default 2.5)
    self.frontViewShadowOffset = CGSizeMake(0.0f, 2.5f); // radius of the front view's shadow offset (default {0.0f,2.5f})
    self.frontViewShadowOpacity = 0.8f; // front view's shadow opacity (default 1.0)
    self.frontViewShadowColor = [UIColor blackColor]; // front view's shadow color (default blackColor)
    
}

@end
