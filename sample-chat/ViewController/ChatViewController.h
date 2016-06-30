//
//  ChatViewController.h
//  sample-chat
//
//  Created by Andrey Moskvin on 6/9/15.
//  Copyright (c) 2015 Igor Khomenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QMChatViewController.h"

@interface ChatViewController : QMChatViewController

- (IBAction)leaveDialog:(id)sender;
@property (nonatomic, strong) QBChatDialog *dialog;

@end
