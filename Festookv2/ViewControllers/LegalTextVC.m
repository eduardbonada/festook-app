//
//  LegalTextVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 02/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "LegalTextVC.h"

@interface LegalTextVC ()

@property (weak, nonatomic) IBOutlet UITextView *legalTextView;

@end

@implementation LegalTextVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews {
    [self.legalTextView setContentOffset:CGPointZero animated:NO];
}

- (IBAction)dismissLegalText:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
