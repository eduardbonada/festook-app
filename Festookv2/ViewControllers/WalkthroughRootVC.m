//
//  WalkthroughRootVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 06/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "WalkthroughRootVC.h"

#import "WalkthroughPageContentVC.h"

@interface WalkthroughRootVC ()<UIPageViewControllerDataSource>

@property (strong, nonatomic) UIPageViewController *walkthroughPageViewController;
@property (strong, nonatomic) NSArray *walkthroughPageTitles;
@property (strong, nonatomic) NSArray *walkthroughPageImages;

@end

@implementation WalkthroughRootVC

#pragma mark - Initialization and Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeWalkthrough];
}
    
-(void) initializeWalkthrough
{
    
    // initialize pages to show
    self.walkthroughPageTitles = @[@"1. Choose a festival.",
                                   @"2. Browse the Line-up.",
                                   @"3. Mark a few concerts\nyou don't want to miss.",
                                   @"4. Check the recommended schedule.",
                                   @"5- Refine the schedule\nmarking the concerts you don't need to see."];
    self.walkthroughPageImages = @[@"walkthoughFestivals",
                                   @"walkthoughLineup",
                                   @"walkthoughBandInfoYes",
                                   @"walkthoughSchedule",
                                   @"walkthoughBandInfoNo"];
    //self.walkthroughPageImages = @[@"walkthroughFestivals", @"walkthroughLineup", @"walkthroughWantToGo", @"walkthroughSchedule",@"walkthroughWantToAvoid"];
    
    // Create page view controller
    self.walkthroughPageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WalkthroughPageViewController"];
    self.walkthroughPageViewController.dataSource = self;
    
    // Configure page content view controller
    WalkthroughPageContentVC *startingVC = [self viewControllerAtIndex:0];
    NSArray *allVCs = @[startingVC];
    [self.walkthroughPageViewController setViewControllers:allVCs
                                                 direction:UIPageViewControllerNavigationDirectionForward
                                                  animated:NO
                                                completion:nil];
    
    // Change the size of page view controller
    self.walkthroughPageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-30);
    
    // add to view hierarchy
    [self addChildViewController:self.walkthroughPageViewController];
    [self.view addSubview:self.walkthroughPageViewController.view];
    [self.walkthroughPageViewController didMoveToParentViewController:self];
    
}

- (IBAction)dismissHelpButtonPressed:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((WalkthroughPageContentVC*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((WalkthroughPageContentVC*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    
    if (index == [self.walkthroughPageTitles count]) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.walkthroughPageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

-(WalkthroughPageContentVC *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.walkthroughPageTitles count] == 0) || (index >= [self.walkthroughPageTitles count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    WalkthroughPageContentVC *wpvc = [self.storyboard instantiateViewControllerWithIdentifier:@"WalkthroughPageContentViewController"];
    wpvc.imageFile = self.walkthroughPageImages[index];
    wpvc.titleText = self.walkthroughPageTitles[index];
    wpvc.pageIndex = index;
    
    return wpvc;
}

@end
