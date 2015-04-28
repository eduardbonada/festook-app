//
//  FestivalInfoVC.h
//  Festook
//
//  Created by Eduard Bonada Cruells on 22/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Festival.h"

@interface FestivalInfoVC : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@property (nonatomic, strong) Festival *festival;

@end
