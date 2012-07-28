//
//  AppDelegate.m
//  Interception
//
//  Created by matt on 7/26/12.
//  Copyright (c) 2012 Matt Morris. All rights reserved.
//

#import "AppDelegate.h"

#define SAFARIID @"com.apple.Safari"
#define CHROMEID @"com.google.Chrome"

#define TWEETBOT_MENTIONS @"tweetbot://mentions"
#define TWEETBOT_MESSAGES @"tweetbot://messages"

#define TWITTER_MENTIONS @"twitter://mentions"
#define TWITTER_MESSAGES @"twitter://messages"

@implementation AppDelegate

- (void)preferredBrowser
{
    CFStringRef preferred = LSCopyDefaultHandlerForURLScheme(CFSTR("http"));
    NSLog(@"%@", (__bridge NSString*)preferred);
}

- (void)listAvailableBrowsers
{
    NSURL* url = [NSURL URLWithString:@"http://www.apple.com"];
    CFArrayRef apps = LSCopyApplicationURLsForURL((__bridge CFURLRef)url, kLSRolesAll);
    
    NSLog(@"apps: %@", (__bridge NSArray*)apps);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self preferredBrowser];
    [self listAvailableBrowsers];
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    OSStatus httpResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"http", (__bridge CFStringRef)bundleID);
    OSStatus httpsResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"https", (__bridge CFStringRef)bundleID);
    
    [self.window makeKeyAndOrderFront:nil];
}

-(void)openURLString:(NSString*)urlString
{
    NSURL* url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
                    withAppBundleIdentifier:SAFARIID
                                    options:NSWorkspaceLaunchAsync
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
    
    [[NSApplication sharedApplication] terminate:self];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlAsString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    if([urlAsString isEqualToString:@"https://twitter.com/mentions"])
    {
        NSURL* twitterURL = [NSURL URLWithString:@"twitter://mentions"];
        [[NSWorkspace sharedWorkspace] openURL:twitterURL];

    } else if([urlAsString isEqualToString:@"https://twitter.com/messages"]){
        NSURL* twitterURL = [NSURL URLWithString:@"twitter://messages"];
        [[NSWorkspace sharedWorkspace] openURL:twitterURL];
        
    } else {
        [self openURLString:urlAsString];
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
