//
//  NowPlayingVC.h
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 13/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Festival.h"

@interface NowPlayingVC : UIViewController

@property (nonatomic, strong) Festival *festival;
@property (strong, nonatomic) NSString* userID;

@end
