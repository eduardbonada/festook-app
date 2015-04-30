//
//  BandInfoVC.h
//  FestivalSchedule
//
//  Created by Eduard Bonada Cruells on 11/09/14.
//  Copyright (c) 2014 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Band.h"

@interface BandInfoVC : UIViewController

@property (strong, nonatomic) Band* band;
@property (strong, nonatomic) NSString* userID;

@end
