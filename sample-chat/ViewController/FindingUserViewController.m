//
//  FindingUserViewController.m
//  samplechat
//
//  Created by Goal on 6/29/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "FindingUserViewController.h"
#import "ServicesManager.h"
#import "ChatViewController.h"


@interface FindingUserViewController ()
<
QMChatServiceDelegate,
QMAuthServiceDelegate,
QMChatConnectionDelegate
>

@property (nonatomic, strong) id <NSObject> observerDidBecomeActive;
@end

@implementation FindingUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // calling awakeFromNib due to viewDidLoad not being called by instantiateViewControllerWithIdentifier
    [[ServicesManager instance].chatService addDelegate:self];
    self.observerDidBecomeActive = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                     object:nil queue:[NSOperationQueue mainQueue]
                                                                                 usingBlock:^(NSNotification *note) {
                                                                                     if (![[QBChat instance] isConnected]) {
                                                                                         [SVProgressHUD showWithStatus:NSLocalizedString(@"SA_STR_CONNECTING_TO_CHAT", nil) maskType:SVProgressHUDMaskTypeClear];
                                                                                     }
                                                                                 }];

    if ([ServicesManager instance].isAuthorized) {
        [self searchDialog];
    }
    _pageNo = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


int randomIntBetween(int smallNumber, int bigNumber)
{
    float diff = (float)(bigNumber - smallNumber);
    return (int)(((float) rand() / RAND_MAX) * diff) + smallNumber;
}

- (void) searchDialog {
    __weak __typeof(self) weakSelf = self;
    
    if ([ServicesManager instance].lastActivityDate != nil) {
        [[ServicesManager instance].chatService fetchDialogsUpdatedFromDate:[ServicesManager instance].lastActivityDate andPageLimit:kDialogsPageLimit iterationBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop) {
            if(dialogObjects.count == 0) {
                [self searchUser];
            } else {
                __typeof(self) strongSelf = self;
                NSInteger index = randomIntBetween(0, (int)(dialogObjects.count));
                bool a = [[QBChat instance] isConnected];
                
                [strongSelf navigateToChatViewControllerWithDialog:dialogObjects[index]];
            }
        } completionBlock:^(QBResponse *response) {
            if ([ServicesManager instance].isAuthorized && response.success) {
                [ServicesManager instance].lastActivityDate = [NSDate date];
            }
        }];
    }
    else {
        //[SVProgressHUD showWithStatus:NSLocalizedString(@"SA_STR_LOADING_DIALOGS", nil) maskType:SVProgressHUDMaskTypeClear];
        [[ServicesManager instance].chatService allDialogsWithPageLimit:kDialogsPageLimit extendedRequest:nil iterationBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop) {
            if(dialogObjects.count == 0) {
                [self searchUser];
            } else {
                __typeof(self) strongSelf = weakSelf;
                NSInteger index = randomIntBetween(0, (int)(dialogObjects.count));
                bool a = [[QBChat instance] isConnected];
                
                [strongSelf navigateToChatViewControllerWithDialog:dialogObjects[index]];
            }
        } completion:^(QBResponse *response) {
            if ([ServicesManager instance].isAuthorized) {
                if (response.success) {
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SA_STR_COMPLETED", nil)];
                    [ServicesManager instance].lastActivityDate = [NSDate date];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"SA_STR_FAILED_LOAD_DIALOGS", nil)];
                }
            }
        }];
    }
}

- (void) searchUser {
    
    
    NSMutableDictionary *filters = [self getFilter];
    [QBRequest usersWithExtendedRequest:filters page:[QBGeneralResponsePage responsePageWithCurrentPage:self.pageNo perPage:10] successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
        
        NSArray *strangers = [users copy];
        strangers = [self removeCurrentUser:strangers];
        
        if(self.pageNo == 0 && strangers.count == 0) {  // the case there is only 2 users(admin and himself) in the first page
            
            [SVProgressHUD showErrorWithStatus:@"Can not find a online user"];
            return;
            
        } else if (self.pageNo != 0 && strangers.count == 0) {   // the case there is only 2 users in the last page
            
            self.pageNo = 0;
            [QBRequest usersWithExtendedRequest:filters page:[QBGeneralResponsePage responsePageWithCurrentPage:self.pageNo perPage:10] successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
                
                NSArray *strangers = [users copy];
                strangers = [self removeCurrentUser:strangers];
                if(strangers.count == 0) {  // the case there is only 2 users(admin and himself) in the first page
                    
                    [SVProgressHUD showErrorWithStatus:@"Can not find a online user"];
                    return;
                }
                __weak __typeof(self) weakSelf = self;
                int randomUserIndex = randomIntBetween(0, (int)(strangers.count));
                QBUUser *stranger = (QBUUser *)strangers[randomUserIndex];
                
                [self createChatWithUser:stranger completion:^(QBChatDialog *dialog) {
                    __typeof(self) strongSelf = weakSelf;
                    if( dialog != nil ) {
                        NSArray *strangerArray = [NSArray arrayWithObject:stranger];
                        [[ServicesManager instance].usersService.usersMemoryStorage addUsers:strangerArray];
                        [strongSelf navigateToChatViewControllerWithDialog:dialog];
                    }
                    else {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"SA_STR_CANNOT_CREATE_DIALOG", nil)];
                    }
                }];
            } errorBlock:^(QBResponse *response) {
                [SVProgressHUD showErrorWithStatus:@"Can not find a online user"];
                
            }];
            
        } else {
            self.pageNo++;
            __weak __typeof(self) weakSelf = self;
            int randomUserIndex = randomIntBetween(0, (int)(strangers.count));
            QBUUser *stranger = (QBUUser *)strangers[randomUserIndex];
            [self createChatWithUser:stranger completion:^(QBChatDialog *dialog) {
                __typeof(self) strongSelf = weakSelf;
                if( dialog != nil ) {
                    NSArray *strangerArray = [NSArray arrayWithObject:stranger];
                    [[ServicesManager instance].usersService.usersMemoryStorage addUsers:strangerArray];
                    bool a = [[QBChat instance] isConnected];
                    [strongSelf navigateToChatViewControllerWithDialog:dialog];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"SA_STR_CANNOT_CREATE_DIALOG", nil)];
                }
            }];
        }
    } errorBlock:^(QBResponse *response) {
        [SVProgressHUD showErrorWithStatus:@"Can not find a online user"];
        
    }];
}

- (NSMutableDictionary *) getFilter {
    
    double secsUtc1970 = [[NSDate date]timeIntervalSince1970];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: secsUtc1970 - onlineTimeInterval];
    NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
    // or Timezone with specific name like
    // [NSTimeZone timeZoneWithName:@"Europe/Riga"] (see link below)
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:timeZone];
    //@"date last_request_at gt 2016-06-28T20:10:38+02";
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'+02'"];
    NSString *localDateString = [dateFormatter stringFromDate:date];
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    filters[@"filter[]"] = [NSString stringWithFormat: @"date last_request_at gt %@",localDateString];  // filter users whose active time is less than 10 mins.
    return filters;
}

- (NSArray *) removeCurrentUser: (NSArray *) strangers {
    
    ServicesManager *servicesManager = [ServicesManager instance];
    NSUInteger count = strangers.count;
    for(int i = 0; i < count; i++) {
        QBUUser * itemUser = (QBUUser *)strangers[i];
        if([itemUser.email isEqualToString: servicesManager.currentUser.email] || [itemUser.email isEqualToString:adminLogin]) {
            NSMutableArray *mutableStrangers = [NSMutableArray arrayWithArray:strangers];
            [mutableStrangers removeObjectAtIndex:i];
            strangers = [NSArray arrayWithArray:mutableStrangers];
            i = -1;
            count = strangers.count;
        }
    }
    return strangers;
}

/**
 *  Creates a chat with name
 *  If name is empty, then "login1_login2, login3, login4" string will be used as a chat name, where login1 is
 *  a dialog creator(owner)
 *
 *  @param name       chat name, can be nil
 *  @param completion completion block
 */
- (void)createChatWithUser:(QBUUser *)user completion:(void(^)(QBChatDialog *dialog))completion {
    
    // Creating private chat dialog.
    [ServicesManager.instance.chatService createPrivateChatDialogWithOpponent:user completion:^(QBResponse *response, QBChatDialog *createdDialog) {
        if (!response.success && createdDialog == nil) {
            if (completion) {
                completion(nil);
            }
        }
        else {
            if (completion) {
                completion(createdDialog);
            }
        }
    }];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kGoToChatSegueIdentifier]) {
        ChatViewController* viewController = segue.destinationViewController;
        viewController.dialog = sender;
    }
}

- (void)navigateToChatViewControllerWithDialog:(QBChatDialog *)dialog {
    [self performSegueWithIdentifier:kGoToChatSegueIdentifier sender:dialog];
}

#pragma mark -
#pragma mark Chat Service Delegate

- (void)chatService:(QMChatService *)chatService didAddChatDialogsToMemoryStorage:(NSArray *)chatDialogs {
    
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)chatDialog {
    
}

- (void)chatService:(QMChatService *)chatService didUpdateChatDialogInMemoryStorage:(QBChatDialog *)chatDialog {
    
}

- (void)chatService:(QMChatService *)chatService didUpdateChatDialogsInMemoryStorage:(NSArray *)dialogs {
    
}

- (void)chatService:(QMChatService *)chatService didReceiveNotificationMessage:(QBChatMessage *)message createDialog:(QBChatDialog *)dialog {
   
}

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    
}

- (void)chatService:(QMChatService *)chatService didAddMessagesToMemoryStorage:(NSArray *)messages forDialogID:(NSString *)dialogID {
    
}

- (void)chatService:(QMChatService *)chatService didDeleteChatDialogWithIDFromMemoryStorage:(NSString *)chatDialogID {
    
}

#pragma mark - NotificationServiceDelegate protocol

- (void)notificationServiceDidStartLoadingDialogFromServer {
    
}

- (void)notificationServiceDidFinishLoadingDialogFromServer {
    
}

- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    /*
    ChatViewController *chatController = (ChatViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatController.dialog = chatDialog;
    
    self.navigationController.viewControllers = @[chatController];
     */
    [self navigateToChatViewControllerWithDialog:chatDialog];
}

- (void)notificationServiceDidFailFetchingDialog {
    // TODO: maybe segue class should be ReplaceSegue?
    //[self performSegueWithIdentifier:kGoToDialogsSegueIdentifier sender:nil];
}


#pragma mark - QMChatConnectionDelegate

- (void)chatServiceChatDidConnect:(QMChatService *)chatService {
    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SA_STR_CONNECTED", nil) maskType:SVProgressHUDMaskTypeClear];
   
}

- (void)chatServiceChatDidReconnect:(QMChatService *)chatService {
    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"SA_STR_RECONNECTED", nil) maskType:SVProgressHUDMaskTypeClear];
   
}

- (void)chatServiceChatDidAccidentallyDisconnect:(QMChatService *)chatService {
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"SA_STR_DISCONNECTED", nil)];
}

- (void)chatService:(QMChatService *)chatService chatDidNotConnectWithError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"SA_STR_DID_NOT_CONNECT_ERROR", nil), [error localizedDescription]]];
}

- (void)chatServiceChatDidFailWithStreamError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"SA_STR_FAILED_TO_CONNECT_WITH_ERROR", nil), [error localizedDescription]]];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
