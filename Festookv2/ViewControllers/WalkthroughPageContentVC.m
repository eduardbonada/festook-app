//
//  WalkthroughPageContentVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 06/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "WalkthroughPageContentVC.h"

@interface WalkthroughPageContentVC ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation WalkthroughPageContentVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    // set title and image to show
    self.titleLabel.text = self.titleText;
    self.imageView.image = [UIImage imageNamed:self.imageFile];

}

@end
