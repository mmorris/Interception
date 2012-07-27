//
//  AppDelegate.m
//  Interception
//
//  Created by matt on 7/26/12.
//  Copyright (c) 2012 Matt Morris. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlAsString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSLog(@"urlstring: %@", urlAsString);
    
    if([urlAsString isEqualToString:@"https://twitter.com/mentions"])
    {
        NSURL* twitterURL = [NSURL URLWithString:@"tweetbot://mentions"];
        [[NSWorkspace sharedWorkspace] openURL:twitterURL];

    } else if([urlAsString isEqualToString:@"https://twitter.com/messages"]){
        NSURL* twitterURL = [NSURL URLWithString:@"tweetbot://mentions"];
        [[NSWorkspace sharedWorkspace] openURL:twitterURL];
        
    } else {
        NSLog(@"open with chrome or safari");
    }
    
    [[NSApplication sharedApplication] terminate:self];
    
    // else
    
    //https://twitter.com/messages
    //https://twitter.com/mentions
    
}

-(void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"1");
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

@end
