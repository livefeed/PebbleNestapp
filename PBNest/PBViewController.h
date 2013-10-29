//
//  PBViewController.h
//  PBNest
//
//  Created by Haifisch on 7/31/13.
//  Copyright (c) 2013 Haifisch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PebbleKit/PebbleKit.h>
@interface PBViewController : UIViewController <UITextFieldDelegate, UIDocumentInteractionControllerDelegate> {
    NSTimer *wat;
    NSString *apiURLString;
    UIDocumentInteractionController *documentInteractionController;
}
@property (strong, nonatomic) IBOutlet UITextField *timeInt;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)updateStart:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *updateBtn;
@property (strong, nonatomic) IBOutlet UITextField *hostField;
- (IBAction)installApp:(id)sender;

@end
