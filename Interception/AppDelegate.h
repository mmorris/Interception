//
//  AppDelegate.h
//  Interception
//
//  Created by matt on 7/26/12.
//  Copyright (c) 2012 Matt Morris. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) NSMutableDictionary* appNameToURL;
@property (nonatomic, strong) NSMutableDictionary* twitterNameToURL;

@property (weak) IBOutlet NSPopUpButton *twitterDropdown;
@property (weak) IBOutlet NSPopUpButton *browserDropdown;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *okayButton;
- (IBAction)okayClicked:(id)sender;
- (IBAction)cancelClicked:(id)sender;

@end
