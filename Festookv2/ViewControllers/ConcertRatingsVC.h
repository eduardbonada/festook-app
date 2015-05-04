//
//  ConcertRatingsVC.h
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 04/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Festival.h"

@interface ConcertRatingsVC : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@property (nonatomic, strong) Festival *festival;
@property (strong, nonatomic) NSString* userID;

@end
