//
//  FestivalRevealVC.h
//  Festook
//
//  Created by Eduard Bonada Cruells on 14/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SWRevealViewController.h"

#import "Festival.h"

@interface FestivalRevealVC : SWRevealViewController

@property (strong, nonatomic) Festival* festival;
@property (strong, nonatomic) NSString* userID;

@end
