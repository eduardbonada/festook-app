//
//  AboutVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 30/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "AboutVC.h"

#import "LegalTextVC.h"
#import "WalkthroughRootVC.h"

#import "EbcEnhancedView.h"

#import <MessageUI/MessageUI.h>
#import "UIApplication+NetworkActivity.h"

#import "Flurry.h"

#define SERVER @"52.28.21.228"
#define FOLDER @"FestookAppFiles"

@interface AboutVC () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *logoContainerBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *walkthroughButton;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *askMailContainerBackgroundView;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *rateBackgroundView;
@property (weak, nonatomic) IBOutlet EbcEnhancedView *supportBackgroundView;
@property (weak, nonatomic) IBOutlet EbcEnhancedView *legalBackgroundView;
@property (weak, nonatomic) IBOutlet EbcEnhancedView *devBackgroundView;
@end

@implementation AboutVC

#pragma mark Initialization

- (void)viewDidLoad
{

    [super viewDidLoad];
    
    // set background image
    self.backgroundView.roundedRects = NO;
    [self.backgroundView setBackgroundGradientFromColor:[UIColor colorWithRed:160.0/255 green:215.0/255 blue:178.0/255 alpha:1.0]
                                                toColor:[UIColor colorWithRed:200.0/255 green:240.0/255 blue:210.0/255 alpha:1.0]]; // dark festuc gradient
    
    // set border of 'walkthrough' button
    self.walkthroughButton.layer.cornerRadius = 5;
    self.walkthroughButton.clipsToBounds = YES;
    [self.walkthroughButton.layer setBorderWidth:1.0];
    [self.walkthroughButton.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];

    [self configureLogoContainer];
    
    [self configureAskMailContainer];
    
    [self configureRateContainer];
    
    [self configureSupportContainer];
    
    [self configureLegalContainer];
    
    [self configureDevContainer];
    
    [self logPresenceEventInFlurry];
    
    // testing notification
    /*
     UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertBody = [NSString stringWithFormat:@"5 seconds passed..."];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
     */
    
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"ShowLegalText"]) {
        if ([segue.destinationViewController isKindOfClass:[LegalTextVC class]]) {
            [self logActionClickEventInFlurry:@"legalText"];
        }
    }
    else if ([segue.identifier isEqualToString:@"ShowWalkthrough"]) {
        if ([segue.destinationViewController isKindOfClass:[WalkthroughRootVC class]]) {
            [self logActionClickEventInFlurry:@"walkthrough"];
        }
    }
    
}

- (IBAction)dismissAbout:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark Flurry Metrics Logging

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"About_Shown" withParameters:@{@"userID":self.userID}];
}
-(void)logActionClickEventInFlurry:(NSString*) action
{
    [Flurry logEvent:@"About_Action" withParameters:@{@"userID":self.userID,@"action":action}];
}

#pragma mark Containers Configuration

-(void) configureLogoContainer
{
    self.logoContainerBackgroundView.roundedRects = YES;
    self.logoContainerBackgroundView.cornerRadius = @(10.0);
    [self.logoContainerBackgroundView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
}
-(void) configureAskMailContainer
{
    self.askMailContainerBackgroundView.roundedRects = YES;
    self.askMailContainerBackgroundView.cornerRadius = @(10.0);
    [self.askMailContainerBackgroundView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
}
-(void) configureRateContainer
{
    self.rateBackgroundView.roundedRects = YES;
    self.rateBackgroundView.cornerRadius = @(10.0);
    [self.rateBackgroundView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
}
-(void) configureSupportContainer
{
    self.supportBackgroundView.roundedRects = YES;
    self.supportBackgroundView.cornerRadius = @(10.0);
    [self.supportBackgroundView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
}
-(void) configureLegalContainer
{
    self.legalBackgroundView.roundedRects = YES;
    self.legalBackgroundView.cornerRadius = @(10.0);
    [self.legalBackgroundView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
}
-(void) configureDevContainer
{
    self.devBackgroundView.roundedRects = YES;
    self.devBackgroundView.cornerRadius = @(10.0);
    [self.devBackgroundView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
}


#pragma mark Tapping actions

- (IBAction)showEmailPrompt:(UITapGestureRecognizer *)sender
{
    // Configure the alert with the input text for the email
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Subscribe"
                                          message:@"Leave us your email so we can come back to you with further updates."
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = @"Enter your email here";
     }];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       // NSLog(@"Cancel action");
                                   }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   [self saveEmailInBackend:((UITextField*)alertController.textFields.firstObject).text];
                               }];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    [self logActionClickEventInFlurry:@"subscription"];
    
}
-(void) saveEmailInBackend:(NSString*) email
{
    [[UIApplication sharedApplication] showNetworkActivityIndicator];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/%@",SERVER,FOLDER,@"setUserEmail.php"]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSString *postVariablesString = [NSString stringWithFormat:@"userID=%@&email=%@", self.userID, email];
    NSError *error = nil;
    NSData *data = [postVariablesString dataUsingEncoding:NSUTF8StringEncoding];
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data
                                                          completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
                                                              if(!error){
                                                                  if(error){
                                                                      UIAlertController *alertController = [UIAlertController
                                                                                                            alertControllerWithTitle:@"Subscription Error"
                                                                                                            message:[NSString stringWithFormat:@"An error occurred in the process of saving the email:\n%@",[error localizedDescription]]
                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                                      UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
                                                                      [alertController addAction:okAction];
                                                                      [self presentViewController:alertController animated:YES completion:nil];
                                                                  }
                                                                  else{
                                                                      //NSLog([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                                                      
                                                                      NSDictionary* dict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data
                                                                                                                                          options:NSJSONReadingMutableContainers
                                                                                                                                            error:&error];
                                                                      if([[dict objectForKey:@"userID"] isEqualToString:self.userID] && [[dict objectForKey:@"email"] isEqualToString:email]){
                                                                          UIAlertController *alertController = [UIAlertController
                                                                                                                alertControllerWithTitle:@"Subscription Success "
                                                                                                                message:[NSString stringWithFormat:@"The email '%@' has been succesfully subscribed.",email]
                                                                                                                preferredStyle:UIAlertControllerStyleAlert];
                                                                          UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
                                                                          [alertController addAction:okAction];
                                                                          [self presentViewController:alertController animated:YES completion:nil];
                                                                      }
                                                                      else{
                                                                          UIAlertController *alertController = [UIAlertController
                                                                                                                alertControllerWithTitle:@"Subscription Error"
                                                                                                                message:[NSString stringWithFormat:@"An error occurred in the process of saving the email. Please try again later."]
                                                                                                                preferredStyle:UIAlertControllerStyleAlert];
                                                                          UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
                                                                          [alertController addAction:okAction];
                                                                          [self presentViewController:alertController animated:YES completion:nil];
                                                                      }
                                                                }
                                                              }
                                                              [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                                                          }];
        
        [uploadTask resume];
    }
    
}

- (IBAction)rateInAppStore:(UITapGestureRecognizer *)sender
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"itms-apps://"]]){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id926115629"]];
    }
    else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id926115629"]];
    }
    
    [self logActionClickEventInFlurry:@"rateApp"];
}

- (IBAction)showContactSupport:(UITapGestureRecognizer *)sender
{
    [self sendContactSupportMail];
    
    [self logActionClickEventInFlurry:@"contactSupport"];
}

- (IBAction)showDeveloperWeb:(UITapGestureRecognizer *)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ebc.cat"]];
    
    [self logActionClickEventInFlurry:@"developer"];
}


#pragma mark Contact Support email

- (void) sendContactSupportMail
{
    // based on: http://www.appcoda.com/ios-programming-create-email-attachment/
    
    NSString *emailTitle = @"[Festook Support]";
    NSString *messageBody = @"";
    NSArray *toRecipents = @[@"info@festook.com"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    // method of MFMailComposeViewControllerDelegate
    
    switch (result)
    {
        case MFMailComposeResultSent:{
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Festook Contact Support"
                                                  message:@"Thank you for contacting us. We'll come back to you as soon as possible."
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
            [alertController addAction:okAction];

            [self dismissViewControllerAnimated:YES completion:NULL];

            [self presentViewController:alertController animated:YES completion:nil];

            break;
        }
        case MFMailComposeResultFailed:{
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Festook Contact Support"
                                                  message:[NSString stringWithFormat:@"An error occurred in the process of sending the email:\n%@",[error localizedDescription]]
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
            [alertController addAction:okAction];

            [self dismissViewControllerAnimated:YES completion:NULL];
            
            [self presentViewController:alertController animated:YES completion:nil];

            break;
        }
        default:
            [self dismissViewControllerAnimated:YES completion:NULL];
            break;
    }
    
    
}

@end

