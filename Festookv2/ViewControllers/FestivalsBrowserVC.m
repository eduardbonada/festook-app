//
//  FestivalBrowserVC.m
//  Festook
//
//  Created by Eduard on 3/16/13.
//  Copyright (c) 2015 Eduard Bonada. All rights reserved.
//

#import "FestivalsBrowserVC.h"

#import "UIApplication+NetworkActivity.h"
#import "Connectability.h"

#import "Festival.h"
#import "EbcEnhancedView.h"

#import "FestivalCollectionViewCell.h"
#import "FestivalRevealVC.h"


@interface FestivalsBrowserVC () <UICollectionViewDataSource, UIAlertViewDelegate>

@property (nonatomic,strong) NSMutableDictionary *festivals; // of @"lowercaseName":Festival

@property (nonatomic,weak) IBOutlet UICollectionView *festivalsCollectionView;
@property (nonatomic,strong) NSArray *festivalsAsInCollectionView; // of @"lowercaseName"

@property (weak, nonatomic) IBOutlet UILabel *emptyListText;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

//@property (strong, nonatomic) UIBarButtonItem* helpButtonNavigationBar;

//@property (strong, nonatomic) HelpRootVC* helpRootVC;

@end

@implementation FestivalsBrowserVC

#pragma mark - Lazy Instantiation
 -(NSMutableDictionary*) festivals
{
    if(!_festivals){
        _festivals = [[NSMutableDictionary alloc] init];
    }
    return _festivals;
}

#pragma mark - View Controller Lifecycle

-(void) setup
{
    self.emptyListText.hidden = YES;
    
    [self loadFestivalsData];

    /*
     
     !!!
     
     REVIEW FOR PRODUCTION
     
     !!!
     
     */
    [self updateListFestivalsFromServer];
    
    // set background image
    self.backgroundView.roundedRects = NO;
    [self.backgroundView setBackgroundGradientFromColor:[UIColor colorWithWhite:0.8 alpha:1.0]
                                                toColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
    //[self.backgroundView setBackgroundGradientFromColor:[UIColor colorWithRed:160.0/255 green:200.0/255 blue:160.0/255 alpha:1.0] toColor:[UIColor colorWithRed:200.0/255 green:240.0/255 blue:200.0/255 alpha:1.0]]; // festuc gradient
    //[self.backgroundView setBackgroundPlain:[UIColor colorWithRed:230.0/255 green:230.0/255 blue:230.0/255 alpha:1.0] withAlpha:@(1.0)]; // grey from Festook 1.0
    
    // set color of navigation bar items
    self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
    
    // change default text attributes for back button
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
        setTitleTextAttributes:
            @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0],
              NSForegroundColorAttributeName: [UIColor darkGrayColor]
              }
        forState:UIControlStateNormal];
    
    // avoid views going below the navigation bar
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([segue.identifier isEqualToString:@"ShowFestival"]) {
        if ([segue.destinationViewController isKindOfClass:[FestivalRevealVC class]]) {
            
            FestivalCollectionViewCell *cell = (FestivalCollectionViewCell *)sender;
            NSIndexPath *indexPath = [self.festivalsCollectionView indexPathForCell:cell];
            
            // set title of 'back' button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            
            // set font of navigation bar title
            [self.navigationController.navigationBar
             setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16],
                                      NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                      }
             ];

            // configure destination VC
            FestivalRevealVC *frvc = segue.destinationViewController;
            if ([frvc isKindOfClass:[FestivalRevealVC class]]) {
                
                // set title
                [frvc setTitle:((Festival*)[self.festivals objectForKey:self.festivalsAsInCollectionView[indexPath.item]]).uppercaseName];
                
                // set festival object
                frvc.festival = [self.festivals objectForKey:self.festivalsAsInCollectionView[indexPath.item]];
                
                // update festival files (listBands, bandDistance) form server, if needed
                [self updateFilesFromFestival:frvc.festival];
                
                // load the bands of the festival
                [frvc.festival loadBandsFromJsonList];
                
                // set mustBands stored in NSUserDefaults, if any
                frvc.festival.mustBands = [frvc.festival getMustBandsFromUserDefaults];
                
                // set discardedBands stored in NSUserDefaults, if any
                frvc.festival.discardedBands = [frvc.festival getDiscardedBandsFromUserDefaults];
                
            }
        }
    }
}

#pragma mark - Management of model data (festivals, bands, etc...)

-(void) updateListFestivalsFromServer
{
    
    // get 'Application Support' directory, and create one of it does not exist
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]){
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]){
            NSLog(@"%@", error.localizedDescription);
        }
    }
    
    // update 'listFestivals.txt' file from server
    if( [[Connectability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable){
        dispatch_queue_t gettingListFestivalsQ = dispatch_queue_create("gettingListFestivalsQ", NULL);
        dispatch_async(gettingListFestivalsQ, ^{
            dispatch_async(dispatch_get_main_queue(), ^{ [[UIApplication sharedApplication] showNetworkActivityIndicator]; });
            
            //[NSThread sleepForTimeInterval:1.0];
            
            NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://ec2-54-93-107-53.eu-central-1.compute.amazonaws.com/FestookAppFiles/listFestivals.txt"]];
            if(urlData){
                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
                NSString *appSupportDirectory = [paths objectAtIndex:0];
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDirectory,@"listFestivals.txt"];
                [urlData writeToFile:filePath atomically:YES];
            }
            else{
                //NSLog(@"ERROR FestivalsBrowserVC::updateListFestivalsFromServer => Could not download file 'listFestivals.txt'");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                [self loadFestivalsData];
            });
        });
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                        message:@"Festook is trying to update the list of festivals."
                                                       delegate:self
                                              cancelButtonTitle:@"Try again"
                                              otherButtonTitles:@"Cancel",nil];
        
        [alert show];
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView.message isEqualToString:@"Festook is trying to update the list of festivals."]){
        // if 'Try Again' tapped
        if(buttonIndex == 0){
            [self setup];
        }
        else if(buttonIndex == 1){
            // Continue with the current local list of festivals
            if([self.festivals count] == 0){
                self.emptyListText.hidden = NO;
            }
        }
    }
}

-(void) loadFestivalsData
{
    
    // read file from application support directory and store its contents into an NSData object
    NSData *listFestivalsJsonData;
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"listFestivals.txt"];
    
    //NSLog(@"app support dir: %@",[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject]);

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [self.festivals removeAllObjects];
        
        listFestivalsJsonData = [[NSData alloc] initWithContentsOfFile:path];
        // get festivals list as dictionary of dictionaries
        NSDictionary* listFestivals = [self loadFestivalsListFromJson:listFestivalsJsonData];
        
        // fill festivals object
        
        for(NSString* festivalString in [listFestivals allKeys]){
            
            // create the festival object
            Festival* festival = [[Festival alloc] initWithDictionary:[listFestivals objectForKey:festivalString]];
            
            [self.festivals setObject:festival forKey:festivalString];
        }
        
        // set array that manages how the festivals are shown in the collection view - sort by decreasing festivalId
        NSArray* festivalsSortedById = [[listFestivals allKeys] sortedArrayUsingComparator:
                                        ^NSComparisonResult(NSString* festStringA, NSString* festStringB) {
                                            Festival *festivalA = [self.festivals objectForKey:festStringA];
                                            Festival *festivalB = [self.festivals objectForKey:festStringB];
                                            return festivalA == festivalB;
                                            //return [festivalA.festivalId integerValue] < [festivalB.festivalId integerValue];
                                        }];
        
        /*
         
         TODO: sort festivals by date (in previous block)
         
         */
        
        self.festivalsAsInCollectionView = festivalsSortedById;
        
        [self.festivalsCollectionView reloadData];

    }
    else{
        //NSLog(@"ERROR FestivalsBrowserVC::loadFestivalsData => File 'listFestivals.txt' does not exist");
    }
    
}

-(void) updateFilesFromFestival:(Festival*) festival
{
    /*
     
     !!!
     
     UNCOMMENT FOR PRODUCTION
     
     !!!
     
     */
    [self updateFileFromServer:festival.listBandsFile];
    [self updateFileFromServer:festival.bandDistanceFile];
    

}

-(void) updateFileFromServer:(NSDictionary*) file
{
    // aux date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    
    // get 'Application Support' directory, and create one of it does not exist
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]){
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]){
            NSLog(@"%@", error.localizedDescription);
        }
    }
    
    // get the date of the file stored in the app, if any
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[file objectForKey:@"filename"]];
    NSDictionary* pathAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDate *localDate;
    if (pathAttributes != nil) {
        localDate = (NSDate*)[pathAttributes objectForKey: NSFileModificationDate];
    }
    else{
        localDate = [dateFormatter dateFromString:@"2000-01-01T00:00:00Z"];
    }
    
    // check if the local file is older and must be updated
    NSDate* serverDate = [dateFormatter dateFromString:[file objectForKey:@"lastUpdate"]];
    
    // NSLog(@"Local Date: %@", [localDate description]);
    // NSLog(@"Server Date: %@", [serverDate description]);
    
    // update file from server, if the serverDate is newer
    if([serverDate compare:localDate] == NSOrderedDescending){

        if( [[Connectability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable){
            [[UIApplication sharedApplication] showNetworkActivityIndicator];

            NSString* serverFileString = [[NSString alloc] initWithFormat:@"http://ec2-54-93-107-53.eu-central-1.compute.amazonaws.com/FestookAppFiles/%@",[file objectForKey:@"filename"]];
            NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:serverFileString]];
            if(urlData){
                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
                NSString *appSupportDirectory = [paths objectAtIndex:0];
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDirectory,[file objectForKey:@"filename"]];
                [urlData writeToFile:filePath atomically:YES];
            }
            else{
                NSLog(@"ERROR FestivalsBrowserVC::updateFileFromServer => Could not download file");
            }

            [[UIApplication sharedApplication] hideNetworkActivityIndicator];
        }
    }
}


-(NSDictionary*) loadFestivalsListFromJson:(NSData*) jsonData
{
    // returns a dictionary of dictionaries (conversion from json structure)
    
    // read list of festivals from json stored in NSData
    NSError *error = nil;
    NSDictionary* dict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:jsonData
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&error];
    if(error){
        NSLog(@"ERROR FestivalsBrowserVC::loadFestivalsListFromJsonIn => %@",error);
    }
    
    return dict;
}


#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.festivals count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    FestivalCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"FestivalCell" forIndexPath:indexPath];
    Festival* festival = [self.festivals objectForKey:self.festivalsAsInCollectionView[indexPath.item]];
    
    // configure the festivalView
    EbcEnhancedView* festivalView = ((FestivalCollectionViewCell *) cell).festivalView;
    if([festivalView isKindOfClass:[EbcEnhancedView class]]){
        
        // set visual graphic configuration
        festivalView.roundedRects = YES;
        festivalView.cornerRadius = @(15.0);
        //[festivalView setBackgroundPlain:festival.colorA withAlpha:@(0.8)];
        [festivalView setBackgroundGradientFromColor:festival.colorA toColor:festival.colorB];
        
        // set the NSAttributedString in the title
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary* attributes = @{NSFontAttributeName            : [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0],
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSParagraphStyleAttributeName  : paragraphStyle
                                     };
        NSString* bandName = [
                              [festival.uppercaseName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]]
                              componentsJoinedByString:@"\n"
                              ];
        festivalView.centeredText = [[NSAttributedString alloc] initWithString:bandName
                                                                    attributes:attributes];
        
    }
    
    return cell;
}



@end
