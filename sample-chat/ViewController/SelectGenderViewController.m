//
//  SelectGenderViewController.m
//  samplechat
//
//  Created by Goal on 6/19/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "SelectGenderViewController.h"
#import "ServicesManager.h"
#import "AppDelegate.h"
#import "DialogsViewController.h"
#import "ChatViewController.h"

@interface SelectGenderViewController () <NotificationServiceDelegate>

@property (weak, nonatomic) IBOutlet UIButton *femaleLabel;
@property (weak, nonatomic) IBOutlet UIButton *maleLabel;
@property (weak, nonatomic) IBOutlet UIButton *startLabel;
- (IBAction)femaleBtnClick:(id)sender;
- (IBAction)maleBtnClick:(id)sender;
- (IBAction)startBtnClick:(id)sender;

@property UIColor *borderColor;
@property NSString* gender;   // female, male
@end

@implementation SelectGenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.user == nil && [ServicesManager instance].currentUser) {
        self.user = [ServicesManager instance].currentUser;
    }
    //self.user = nil;
    _gender = @"female";
    [self setStyle];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setStyle {
    _borderColor = [UIColor colorWithRed:1.0 green:0.73 blue:0.16 alpha:1.0];
    _femaleLabel.layer.cornerRadius = 30.0f;
    _femaleLabel.layer.masksToBounds = true;
    _maleLabel.layer.cornerRadius = 30.0f;
    _maleLabel.layer.masksToBounds = true;
    _startLabel.layer.cornerRadius = 30.0f;
    _startLabel.layer.masksToBounds = true;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)femaleBtnClick:(id)sender {
    _femaleLabel.layer.borderWidth = 2.0f;
    _femaleLabel.layer.borderColor = _borderColor.CGColor;
    _maleLabel.layer.borderWidth = 0.0f;
    _gender = @"female";
}

- (IBAction)maleBtnClick:(id)sender {
    _maleLabel.layer.borderWidth = 2.0f;
    _maleLabel.layer.borderColor = _borderColor.CGColor;
    _femaleLabel.layer.borderWidth = 0.0f;
    _gender = @"male";
}

- (IBAction)startBtnClick:(id)sender {
    __weak __typeof(self)weakSelf = self;
    NSString *username = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *password = @"My@12345678";    //it is formal password
    NSString *email = @"Test@gmail.com";    // it is formal email
    ServicesManager *servicesManager = [ServicesManager instance];
    
    if (weakSelf.user == nil) {
        QBUUser *user = [QBUUser new];
        user.login = username;
        user.password = password;
        user.email = email;
        user.customData = _gender;
        
        
        [SVProgressHUD showWithStatus:@"Signing up"];
        
        [QBRequest signUp:user successBlock:^(QBResponse *response, QBUUser *user) {
            [QBRequest logInWithUserLogin:username password:password successBlock:^(QBResponse *response, QBUUser *user) {
                __typeof(self) strongSelf = weakSelf;
                [strongSelf registerForRemoteNotifications];
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SA_STR_LOGGED_IN", nil)];
                
                if (servicesManager.notificationService.pushDialogID == nil) {
                    [strongSelf performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
                }
                else {
                    [servicesManager.notificationService handlePushNotificationWithDelegate:self];
                }
                
            } errorBlock:^(QBResponse *response) {
                [SVProgressHUD showErrorWithStatus:@"Login error"];
            }];
            
        } errorBlock:^(QBResponse *response) {
            [SVProgressHUD showErrorWithStatus:@"Signup error"];
        }];
    } else {
        weakSelf.user.password = password;
        [SVProgressHUD showWithStatus:@"Login"];
        [ServicesManager.instance logInWithUser:weakSelf.user completion:^(BOOL success, NSString *errorMessage)
         {
             if (success)
             {
                 __typeof(self) strongSelf = weakSelf;
                 [strongSelf registerForRemoteNotifications];
                 [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SA_STR_LOGGED_IN", nil)];
                 
                 if (servicesManager.notificationService.pushDialogID == nil) {
                     [strongSelf performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
                 }
                 else {
                     [servicesManager.notificationService handlePushNotificationWithDelegate:self];
                 }
             }
             else
             {
                 [SVProgressHUD showErrorWithStatus:@"Login error"];
             }
         }];
    }
    
}


#pragma mark - NotificationServiceDelegate protocol

- (void)notificationServiceDidStartLoadingDialogFromServer {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SA_STR_LOADING_DIALOG", nil) maskType:SVProgressHUDMaskTypeClear];
}

- (void)notificationServiceDidFinishLoadingDialogFromServer {
    [SVProgressHUD dismiss];
}

- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    DialogsViewController *dialogsController = (DialogsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"DialogsViewController"];
    ChatViewController *chatController = (ChatViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatController.dialog = chatDialog;
    
    self.navigationController.viewControllers = @[dialogsController, chatController];
}

- (void)notificationServiceDidFailFetchingDialog {
    // TODO: maybe segue class should be ReplaceSegue?
    [self performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
}

#pragma mark - Push Notifications

- (void)registerForRemoteNotifications{
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

@end
