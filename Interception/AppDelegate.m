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

- (NSString*)preferredBrowser
{
    CFStringRef preferred = LSCopyDefaultHandlerForURLScheme(CFSTR("http"));
    
    return (__bridge NSString*)preferred;
}

- (NSURL*)preferredBrowser2
{
    NSURL* url = [NSURL URLWithString:@"http://www.apple.com"];
    CFURLRef preferredApplication;
    OSStatus stat = LSGetApplicationForURL((__bridge CFURLRef)url,
                                           kLSRolesAll,
                                           NULL,
                                           &preferredApplication);
    
    // TODO: check stat

    return (__bridge NSURL*)preferredApplication;
}

// Returns array of URLs
- (NSArray*)listAvailableTwitterClients
{
    NSArray* twitterClientIDs = @[@"com.tapbots.TweetbotMacAdHoc",
                                  @"com.violasong.Hibari",
                                  @"com.twitter.twitter-mac"];
    
    NSMutableArray* URLs = [NSMutableArray array];
    
    for(NSString* appId in twitterClientIDs) {
        NSURL* appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:appId];
        [URLs addObject:appURL];
    }
    
    return URLs;
}

// returns array of URLs
- (NSArray*)listAvailableBrowsers
{
    NSURL* url = [NSURL URLWithString:@"http://www.apple.com"];
    CFArrayRef apps = LSCopyApplicationURLsForURL((__bridge CFURLRef)url, kLSRolesAll);
    
    NSLog(@"apps: %@", (__bridge NSArray*)apps);
    
    NSArray* ret = [NSArray arrayWithArray:(__bridge NSArray*)apps];
    
    return ret;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSArray* availBrowsers = [self listAvailableBrowsers];
    NSArray* availTwitterClients = [self listAvailableTwitterClients];
    NSLog(@"tc: %@", availTwitterClients);

    {// set http dropdown
        self.appNameToURL = [NSMutableDictionary dictionary];
        for(NSURL* bundleURL in availBrowsers) {
            NSLog(@"%@", bundleURL);
            NSBundle* appBundle = [NSBundle bundleWithURL:bundleURL];
            
            NSString* appName = [[appBundle infoDictionary] objectForKey:@"CFBundleName"];
            NSLog(@"app name: %@", appName);
            
            [self.appNameToURL setObject:bundleURL forKey:appName];
        }
        
        [self.browserDropdown removeAllItems];
        [self.browserDropdown addItemsWithTitles:self.appNameToURL.allKeys];
    }
    
    {// set twitter dropdown
        self.twitterNameToURL = [NSMutableDictionary dictionary];
        for(NSURL* bundleURL in availTwitterClients) {
            NSLog(@"%@", bundleURL);
            NSBundle* appBundle = [NSBundle bundleWithURL:bundleURL];
            
            NSString* appName = [[appBundle infoDictionary] objectForKey:@"CFBundleName"];
            NSLog(@"app name: %@", appName);
            
            [self.twitterNameToURL setObject:bundleURL forKey:appName];
        }
        
        [self.twitterDropdown removeAllItems];
        [self.twitterDropdown addItemsWithTitles:self.twitterNameToURL.allKeys];
    }
    
    //[self openTwitterForURL:@"foo"];
    
    [self.window makeKeyAndOrderFront:nil];
    
#if 0
    // older test code...
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    OSStatus httpResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"http", (__bridge CFStringRef)bundleID);
    OSStatus httpsResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"https", (__bridge CFStringRef)bundleID);
    
    [self.window makeKeyAndOrderFront:nil];
#endif
}

-(void)openURLString:(NSString*)urlString
{
    NSString* browserURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"preferred_browser"];
    NSURL* browserURL = [NSURL URLWithString:browserURLString];
    NSLog(@"def browser: %@", browserURL);
    
    NSBundle* browserBundle = [NSBundle bundleWithURL:browserURL];
    NSString* browserID = [browserBundle bundleIdentifier];
    
    NSURL* url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
                    withAppBundleIdentifier:browserID
                                    options:NSWorkspaceLaunchAsync
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
    
    [[NSApplication sharedApplication] terminate:self];
}

-(void)openTwitterForURL:(NSString*)urlString
{
    //TODO: handle URL... go to mentions for messages for the particular app.
    
    NSString* twitterURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"preferred_twitter"];
    NSURL* twitterURL = [NSURL URLWithString:twitterURLString];
    NSLog(@"def twitter: %@", twitterURL);
    
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:twitterURL
                                                  options:NSWorkspaceLaunchAsync
                                            configuration:nil
                                                    error:NULL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlAsString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    NSLog(@"URL: %@", urlAsString);
    
    if([urlAsString isEqualToString:@"https://twitter.com/mentions"])
    {
        //NSURL* twitterURL = [NSURL URLWithString:@"twitter://mentions"];
        //[[NSWorkspace sharedWorkspace] openURL:twitterURL];
        [self openTwitterForURL:urlAsString];

    } else if([urlAsString isEqualToString:@"https://twitter.com/messages"]){
        //NSURL* twitterURL = [NSURL URLWithString:@"twitter://messages"];
        //[[NSWorkspace sharedWorkspace] openURL:twitterURL];
        [self openTwitterForURL:urlAsString];
        
    } else {
        [self openURLString:urlAsString];
    }
    
    [[NSApplication sharedApplication] terminate:self];
}

-(void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"1");
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    
    NSString* browserURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"preferred_browser"];
    NSURL* browserURL = [NSURL URLWithString:browserURLString];
    NSLog(@"def browser: %@", browserURL);
    
    NSString* twitterURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"preferred_twitter"];
    NSURL* twitterURL = [NSURL URLWithString:twitterURLString];
    NSLog(@"def twitter: %@", twitterURL);
}

- (IBAction)okayClicked:(id)sender {
    NSLog(@"okayClicked");
    
    NSLog(@"%@", self.browserDropdown.selectedItem.title);
    
    // map title back to bundle id
    NSURL* browserURL = [self.appNameToURL objectForKey:self.browserDropdown.selectedItem.title];
    NSLog(@"setting: %@", browserURL);
    // set the default browser for everything else.
    [[NSUserDefaults standardUserDefaults] setObject:[browserURL absoluteString] forKey:@"preferred_browser"];
    
    
    NSURL* twitterAppURL = [self.twitterNameToURL objectForKey:self.twitterDropdown.selectedItem.title];
    NSLog(@"setting: %@", twitterAppURL);
    // set the default browser for everything else.
    [[NSUserDefaults standardUserDefaults] setObject:[twitterAppURL absoluteString] forKey:@"preferred_twitter"];
    
    
    // Become the default http[s] handler
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    // TODO: check result codes
    OSStatus httpResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"http", (__bridge CFStringRef)bundleID);
    OSStatus httpsResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"https", (__bridge CFStringRef)bundleID);
    
    // TODO: terminate here.
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)cancelClicked:(id)sender {
    NSLog(@"cancelClicked");
    
    [[NSApplication sharedApplication] terminate:self];
}
@end
