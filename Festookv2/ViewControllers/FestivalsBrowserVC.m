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
#import "AboutVC.h"

#import "Flurry.h"

#define SERVER @"52.28.21.228"
#define FOLDER @"FestookAppFiles"

@interface FestivalsBrowserVC () <UICollectionViewDataSource>

@property (nonatomic,strong) NSMutableDictionary *festivals; // of @"lowercaseName":Festival

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (nonatomic,weak) IBOutlet UICollectionView *festivalsCollectionView;
@property (nonatomic,strong) NSArray *festivalsAsInCollectionView; // of @"lowercaseName"

@property (weak, nonatomic) IBOutlet EbcEnhancedView *emptyListTextBackground;
@property (weak, nonatomic) IBOutlet UILabel *emptyListText;

@property (strong, nonatomic) NSString* userID;

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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getUserID];
    
    // set background image
    self.backgroundView.roundedRects = NO;
    //[self.backgroundView setBackgroundGradientFromColor:[UIColor colorWithRed:168.0/255 green:223.0/255 blue:184.0/255 alpha:1.0] toColor:[UIColor colorWithRed:208.0/255 green:248.0/255 blue:219.0/255 alpha:1.0]]; // festuc gradient
    //[self.backgroundView setBackgroundGradientFromColor:[UIColor colorWithRed:230.0/255 green:230.0/255 blue:230.0/255 alpha:1.0] toColor:[UIColor colorWithRed:250.0/255 green:250.0/255 blue:250.0/255 alpha:1.0]]; // grey gradient
    [self.backgroundView setBackgroundPlain:[UIColor colorWithRed:230.0/255 green:230.0/255 blue:230.0/255 alpha:1.0] withAlpha:@(1.0)]; // grey from Festook 1.0
    
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [self setup];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateListFestivalsFromServer]; // called here because we need a shown view to add the alert
}

-(void) setup
{
    
    [self loadFestivalsData];
    
    if([self.festivals count] == 0){
        self.emptyListText.hidden = NO;
        self.emptyListTextBackground.hidden = NO;
        self.emptyListText.text = @"Downloading festivals information...";
    }
    
    // compute size of collection view cells
    CGFloat cellsPerRow = 2.0;
    CGFloat leftRightMargin = 16.0;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.festivalsCollectionView.collectionViewLayout;
    CGFloat availableWidthForCells = (self.view.frame.size.width-2*leftRightMargin) - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (cellsPerRow - 1);
    CGFloat cellWidth = availableWidthForCells / cellsPerRow;
    /*NSLog(@"self.festivalsCollectionView.frame: %@", NSStringFromCGRect(self.festivalsCollectionView.frame));
    NSLog(@"self.view.frame: %@", NSStringFromCGRect(self.view.frame));
    NSLog(@"flowLayout.sectionInset.left: %f",flowLayout.sectionInset.left);
    NSLog(@"flowLayout.sectionInset.right: %f",flowLayout.sectionInset.left);
    NSLog(@"flowLayout.minimumInteritemSpacing: %f",flowLayout.minimumInteritemSpacing);
    NSLog(@"availableWidthForCells: %f",availableWidthForCells);
    NSLog(@"cellWidth: %f",cellWidth);*/
    flowLayout.itemSize = CGSizeMake(cellWidth, cellWidth); //flowLayout.itemSize.height);
    
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([segue.identifier isEqualToString:@"ShowFestival"]) {
        if ([segue.destinationViewController isKindOfClass:[FestivalRevealVC class]]) {
            
            FestivalCollectionViewCell *cell = (FestivalCollectionViewCell *)sender;
            NSIndexPath *indexPath = [self.festivalsCollectionView indexPathForCell:cell];
            
            // configure destination VC
            FestivalRevealVC *frvc = segue.destinationViewController;
            if ([frvc isKindOfClass:[FestivalRevealVC class]]) {
                
                // set title of 'back' button
                self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
                
                // set font of navigation bar title
                [self.navigationController.navigationBar
                 setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16],
                                          NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                          }
                 ];
                
                // set title
                [frvc setTitle:((Festival*)[self.festivals objectForKey:self.festivalsAsInCollectionView[indexPath.item]]).uppercaseName];
                
                // set festival object
                frvc.festival = [self.festivals objectForKey:self.festivalsAsInCollectionView[indexPath.item]];

                // set userID
                frvc.userID = self.userID;

                // load the bands of the festival
                [frvc.festival loadBandsFromJsonList];
                
                // set mustBands stored in NSUserDefaults, if any
                frvc.festival.mustBands = [frvc.festival getMustBandsFromNSUserDefaults];
                
                // set discardedBands stored in NSUserDefaults, if any
                frvc.festival.discardedBands = [frvc.festival getDiscardedBandsFromNSUserDefaults];
                
            }
        }
    }
    else if ([segue.identifier isEqualToString:@"ShowAbout"]) {
        if ([segue.destinationViewController isKindOfClass:[AboutVC class]]) {
            
            // configure destination VC
            AboutVC *avc = segue.destinationViewController;
            if ([avc isKindOfClass:[AboutVC class]]) {
                avc.userID = self.userID;
            }
        }
    }
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    
    if([identifier isEqualToString:@"ShowFestival"]){
        FestivalCollectionViewCell *cell = (FestivalCollectionViewCell *)sender;
        NSIndexPath *indexPath = [self.festivalsCollectionView indexPathForCell:cell];

        Festival* festival = [self.festivals objectForKey:self.festivalsAsInCollectionView[indexPath.item]];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *pathListBands = [[paths objectAtIndex:0] stringByAppendingPathComponent:[festival.listBandsFile objectForKey:@"filename"]];
        NSString *pathDistanceMx = [[paths objectAtIndex:0] stringByAppendingPathComponent:[festival.bandDistanceFile objectForKey:@"filename"]];
        
        if ( [[NSFileManager defaultManager] fileExistsAtPath:pathListBands] && [[NSFileManager defaultManager] fileExistsAtPath:pathDistanceMx]){
            return YES;
        }
        else{
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Missing Data"
                                                  message:@"The festival data could not be downloaded."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
            
            return NO;
        }
    }
    else if ([identifier isEqualToString:@"ShowAbout"]) {
        return YES;
    }
    
    return NO;
}


#pragma mark - Interaction with Backend

-(void) getUserID
{
    // get userID stored in NSUserDefaults, or ask for one to the server
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
    if(!userID){
        [self getUserIDfromServer]; // run asynchronously
    }
    else{
        self.userID = userID;
        [self logPresenceEventInFlurry];
    }
}

-(void) getUserIDfromServer
{
    
    [[UIApplication sharedApplication] showNetworkActivityIndicator];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 10.0;
    sessionConfig.timeoutIntervalForResource = 10.0;
    sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/%@",SERVER,FOLDER,@"getUserID.php"]]
                                          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if(!error){
                                                  NSDictionary* dict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data
                                                                                                                      options:NSJSONReadingMutableContainers
                                                                                                                        error:&error];
                                                  if(error){
                                                      NSLog(@"ERROR FestivalsBrowserVC::getUserIDFromServer => %@",error);
                                                  }
                                                  else{
                                                      //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
                                                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                      [defaults setObject:[dict objectForKey:@"userID"] forKey:@"userID"];
                                                      [defaults synchronize];
                                                      self.userID = [dict objectForKey:@"userID"];
                                                      [self logPresenceEventInFlurry];
                                                  }
                                              }
                                              [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                                          }];
    [downloadTask resume];
    
}

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"List_Festivals_Shown" withParameters:@{@"userID":self.userID}];
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
            
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 10.0;
            sessionConfig.timeoutIntervalForResource = 10.0;
            sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
            //NSLog(@"%@",[NSString stringWithFormat:@"http://%@/%@/listFestivals.txt",SERVER,FOLDER]);
            NSURLSessionDataTask *downloadTask = [[NSURLSession sessionWithConfiguration:sessionConfig]
                                                  dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/listFestivals.txt",SERVER,FOLDER]]
                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      if(!error){
                                                          //NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                                                          NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
                                                          NSString *appSupportDirectory = [paths objectAtIndex:0];
                                                          NSString *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDirectory,@"listFestivals.txt"];
                                                          [data writeToFile:filePath atomically:YES];
                                                      }
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                                                          [self loadFestivalsData];
                                                          self.emptyListText.hidden = YES;
                                                          self.emptyListTextBackground.hidden = YES;
                                                      });
                                                  }];
            [downloadTask resume];
            
        });
    }
    else{
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"No Internet Connection"
                                              message:@"Festook is trying to update festivals data."
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try again"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action){
                                                                   [self updateListFestivalsFromServer];
                                                               }];
        [alertController addAction:tryAgainAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action){
                                                                   // Continue with the current local list of festivals
                                                                   if([self.festivals count] == 0){
                                                                       self.emptyListText.hidden = NO;
                                                                       self.emptyListTextBackground.hidden = NO;
                                                                       self.emptyListText.text = @"No festivals found. Check your internet connection and restart the app.";
                                                                   }
                                                               }];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
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
                                            //return festivalA == festivalB;
                                            return [festivalA.festivalId integerValue] > [festivalB.festivalId integerValue];
                                        }];
        
        /*
         
         TODO: sort festivals by date (in previous block)
         
         */
        
        self.festivalsAsInCollectionView = festivalsSortedById;
        
        [self.festivalsCollectionView reloadData];
        
        // update festival files (listBands, bandDistance) form server, if needed
        for(NSString* festivalName in [self.festivals allKeys]){
            [self updateFilesFromFestival:[self.festivals objectForKey:festivalName]];
        }

    }
    else{
        //NSLog(@"ERROR FestivalsBrowserVC::loadFestivalsData => File 'listFestivals.txt' does not exist");
    }
    
}

-(void) updateFilesFromFestival:(Festival*) festival
{
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
        
        [[UIApplication sharedApplication] showNetworkActivityIndicator];

        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 10.0;
        sessionConfig.timeoutIntervalForResource = 10.0;
        sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                              dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/%@",SERVER,FOLDER,[file objectForKey:@"filename"]]]
                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                  if(!error){
                                                      
                                                      NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
                                                      NSString *appSupportDirectory = [paths objectAtIndex:0];
                                                      NSString *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDirectory,[file objectForKey:@"filename"]];
                                                      [data writeToFile:filePath atomically:YES];
                                                  }
                                                  [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                                              }];
        [downloadTask resume];

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
        festivalView.cornerRadius = @(18.0);
        //[festivalView setBackgroundPlain:festival.colorA withAlpha:@(0.8)];
        [festivalView setBackgroundGradientFromColor:festival.colorA toColor:festival.colorB];
        
        // set the NSAttributedString in the title
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary* attributes = @{NSFontAttributeName            : [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0],
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSParagraphStyleAttributeName  : paragraphStyle
                                     };
        NSString* festivalName = [
                              [festival.uppercaseName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]]
                              componentsJoinedByString:@"\n"
                              ];
        festivalView.centeredText = [[NSAttributedString alloc] initWithString:festivalName
                                                                    attributes:attributes];
        
        if([festival.state isEqualToString:@"inactive"]){
            [cell.festivalView setBackgroundPlain:[UIColor whiteColor] withAlpha:@(0.5)]; // to add an effect of disabled
            cell.inactiveLabel.transform = CGAffineTransformMakeRotation (-3.14/8);
            cell.inactiveLabel.hidden = NO;
            cell.userInteractionEnabled = NO;
        }
        else{
            [cell.festivalView setBackgroundPlain:[UIColor clearColor] withAlpha:@(1.0)];
            cell.inactiveLabel.hidden = YES;
            cell.userInteractionEnabled = YES;
        }
        
    }
    
    return cell;
}



@end
