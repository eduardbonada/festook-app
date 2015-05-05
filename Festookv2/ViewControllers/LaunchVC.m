//
//  LaunchVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 05/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "LaunchVC.h"

@interface LaunchVC ()

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@end

@implementation LaunchVC

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self animateLogo];
}

-(void) animateLogo
{
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.75
                          delay:0.50
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^(void){
                         self.logoImageView.frame = CGRectMake(self.logoImageView.frame.origin.x,
                                                               28.0,
                                                               self.logoImageView.frame.size.width,
                                                               self.logoImageView.frame.size.height);
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                         [self performSegueWithIdentifier:@"ShowFestivalBrowser" sender:self];
                     }];
}

@end
