//
//  PBViewController.m
//  PBNest
//
//  Created by Haifisch on 7/31/13.
//  Copyright (c) 2013 Haifisch. All rights reserved.
//

#import "PBViewController.h"

@interface PBViewController () <PBPebbleCentralDelegate>


@end

@implementation PBViewController {
    PBWatch *_targetWatch;
}

-(void)refreshAction:(id)sender {
    if (_targetWatch == nil || [_targetWatch isConnected] == NO) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"No connected watch!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
       
        return;
    }
    
    NSLog(@"Text: %lu",(unsigned long)[self.hostField.text length]);
    if ([self.hostField.text length] != 0) {
        apiURLString = [NSString stringWithFormat:@"http://%@/nest/getTemp.php?email=%@&password=%@", self.hostField.text, self.usernameField.text, self.passwordField.text];
    }else{
        apiURLString = [NSString stringWithFormat:@"http://pbdb.dylanlaws.com/nest/getTemp.php?email=%@&password=%@", self.usernameField.text, self.passwordField.text];

    }
    NSLog(@"URL: %@", apiURLString);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURLString]];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *) response;
        }
        
        // NSURLConnection's completionHandler is called on the background thread.
        // Prepare a block to show an alert on the main thread:
        __block NSString *message = @"";
        void (^showAlert)(void) = ^{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                 NSLog(@"%@",message);
            }];
           
        };
        
        // Check for error or non-OK statusCode:
        if (error || httpResponse.statusCode != 200) {
            message = @"Error fetching house data";
            showAlert();
            return;
        }
        
        // Parse the JSON response:
        NSError *jsonError = nil;
        NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"%@", root);
        @try {
            if (jsonError == nil && root) {
                // TODO: type checking / validation, this is really dangerous...
                // Set the number format
                NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init ];
                [numberFormat setNumberStyle:NSNumberFormatterDecimalStyle];
                [numberFormat setMaximumFractionDigits:0];
                
                // Get the current temperature scale (Fahrenheit or Celsius)
                NSString *temperatureScale = root[@"scale"];
                
                // Get the current temperature:
                NSDictionary *current_state = [root valueForKey:@"current_state"];
                NSNumber *temperatureNumber = current_state[@"temperature"];
                
                NSString *formattedTemp = @"";
                formattedTemp = [formattedTemp stringByAppendingString:[numberFormat stringFromNumber:temperatureNumber]];
                formattedTemp = [formattedTemp stringByAppendingString:@" \u00B0"];
                formattedTemp = [formattedTemp stringByAppendingString:temperatureScale];
                
                
                // Get the humdity:
                NSDictionary *target = [root valueForKey:@"current_state"];
                 NSNumber *humidityNumber = target[@"humidity"];
                NSString *formattedHumidity = [NSString stringWithFormat:@"%@ %%", humidityNumber];
                
                // Get the mode
                // NSString *houseMode = root[@"3"];
                
                // NSString *serial = root[@"serial_number"];
                
                // Loop through response and output
                /*for(NSString* key in root)
                {
                    NSString *output = key;
                    NSString *value = [root objectForKey:key];
                    message = [output stringByAppendingString:@": "];
                    message = [output stringByAppendingString:value];
                    showAlert();
                }*/
                
                
                // Get weather icon:
                //NSNumber *weatherIconNumber = firstListItem[@"weather"][0][@"icon"];
                //uint8_t weatherIconID = [self getIconFromWeatherId:[weatherIconNumber integerValue]];
                
                // Send data to watch:
                // See demos/feature_app_messages/weather.c in the native watch app SDK for the same definitions on the watch's end:
                //NSNumber *iconKey = @(0); // This is our custom-defined key for the icon ID, which is of type uint8_t.
                NSNumber *currentTemperatureKey = @(1); // This is our custom-defined key for the current temperature string.
                NSNumber *targetTemperatureKey = @(0); // This is out custom-defined key for the target temperature string.
                // NSNumber *humidityKey = @(0); // This is our custom-defined key for the humidity string.
                // NSNumber *modeKey = @(2); // This is our custom-defined key for the humidity string.
                NSDictionary *update = @{
                                          currentTemperatureKey:[NSString stringWithFormat:@"%@", formattedTemp],
                                          targetTemperatureKey:[NSString stringWithFormat:@"%@", formattedHumidity]
                                          //humidityKey:[NSString stringWithFormat:@"%@", formattedHumidity],
                                          //modeKey:houseMode
                                        };
                [_targetWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
                    message = error ? [error localizedDescription] : @"Update sent!";
                    showAlert();
                }];
                return;
            }
        }
        @catch (NSException *exception) {
        }
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:[NSString stringWithFormat:@"%@", root[@"error"]] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [errorAlert show];
        [wat invalidate];
    }];
}

- (void)setTargetWatch:(PBWatch*)watch {
    _targetWatch = watch;
    
    // NOTE:
    // For demonstration purposes, we start communicating with the watch immediately upon connection,
    // because we are calling -appMessagesGetIsSupported: here, which implicitely opens the communication session.
    // Real world apps should communicate only if the user is actively using the app, because there
    // is one communication session that is shared between all 3rd party iOS apps.
    
    // Test if the Pebble's firmware supports AppMessages / Weather:
    [watch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
        if (isAppMessagesSupported) {
            // Configure our communications channel to target the weather app:
            // See demos/feature_app_messages/weather.c in the native watch app SDK for the same definition on the watch's end:
            uint8_t bytes[] = {0x42, 0xc8, 0x6e, 0xa4, 0x1c, 0x3e, 0x4a, 0x7, 0xb8, 0x89, 0x2c, 0xcc, 0xca, 0x91, 0x41, 0x98};
            NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
            [watch appMessagesSetUUID:uuid];
            
            NSString *message = [NSString stringWithFormat:@"Yay! %@ supports AppMessages :D", [watch name]];
            //[[[UIAlertView alloc] initWithTitle:@"Connected!" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"%@",message);
        } else {
            
            NSString *message = [NSString stringWithFormat:@"Blegh... %@ does NOT support AppMessages :'(", [watch name]];
            //[[[UIAlertView alloc] initWithTitle:@"Connected..." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"%@",message);
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // We'd like to get called when Pebbles connect and disconnect, so become the delegate of PBPebbleCentral:
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"noisy_grid"]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:@"username"] != NULL && [defaults objectForKey:@"password"]){
        self.usernameField.text = [defaults objectForKey:@"username"];
        self.passwordField.text = [defaults objectForKey:@"password"];
        wat = [NSTimer scheduledTimerWithTimeInterval:[self.timeInt.text integerValue]
                                         target:self
                                       selector:@selector(refreshAction:)
                                       userInfo:nil
                                        repeats:YES];
        }else {
       [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please fill in your user data, then click the button!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    // Initialize with the last connected watch:
    [self setTargetWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
 *  PBPebbleCentral delegate methods
 */

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    [self setTargetWatch:watch];
    wat = [NSTimer scheduledTimerWithTimeInterval:[self.timeInt.text integerValue]
                                           target:self
                                         selector:@selector(refreshAction:)
                                         userInfo:nil
                                          repeats:YES];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    [wat invalidate];
    [[[UIAlertView alloc] initWithTitle:@"Disconnected!" message:[watch name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    if (_targetWatch == watch || [watch isEqual:_targetWatch]) {
        [self setTargetWatch:nil];
    }
    [watch wake];
}
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.usernameField.text forKey:@"username"];
    [defaults setObject:self.passwordField.text forKey:@"password"];
    [defaults synchronize];
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)updateStart:(id)sender {
    NSLog(@"stoping");
    [wat invalidate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.usernameField.text forKey:@"username"];
    [defaults setObject:self.passwordField.text forKey:@"password"];
    [defaults synchronize];
    wat = [NSTimer scheduledTimerWithTimeInterval:[self.timeInt.text integerValue]
                                           target:self
                                         selector:@selector(refreshAction:)
                                         userInfo:nil
                                          repeats:YES];
    NSLog(@"starting");
}
- (IBAction)installApp:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://dylanlaws.com/pebble/PebbleNest.pbw"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingString:@"/PBNest.pbw"];
    [data writeToFile:path atomically:YES];
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:path];

	if (path) {
		documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        
		documentInteractionController.delegate = self;
		
		//self.documentInteractionController.name = @"Title";
		//self.documentInteractionController.UTI = @"com.adobe.pdf";
		[documentInteractionController presentOptionsMenuFromRect:CGRectZero
                                                                inView:self.view
                                                              animated:YES];
	}
    
}
@end
