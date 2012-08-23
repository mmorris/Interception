#import "AppDelegate.h"

@implementation AppDelegate

- (NSString*)preferredBrowser
{
    CFStringRef preferred = LSCopyDefaultHandlerForURLScheme(CFSTR("http"));
    
    if([(__bridge NSString*)preferred caseInsensitiveCompare:@"com.mattmorris.Interception"] == NSOrderedSame) {
        NSString* browserURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"preferred_browser"];
        NSURL* browserURL = [NSURL URLWithString:browserURLString];
        NSBundle* browserBundle = [NSBundle bundleWithURL:browserURL];
        
        return [browserBundle bundleIdentifier];
    } else {
        return (__bridge NSString*)preferred;
    }
}

// Returns array of URLs
- (NSArray*)listAvailableTwitterClients
{
    // To support new clients, just add their app IDs here
    NSArray* twitterClientIDs = @[@"com.tapbots.TweetbotMacAdHoc",
                                  @"com.violasong.Hibari",
                                  @"com.twitter.twitter-mac",
                                  @"com.twitter.TweetDeck"];
    
    NSMutableArray* URLs = [NSMutableArray array];
    
    for(NSString* appId in twitterClientIDs) {
        NSURL* appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:appId];
        if(appURL != nil) {
            [URLs addObject:appURL];
        }
    }
    
    return URLs;
}

// returns array of URLs
- (NSArray*)listAvailableBrowsers
{
    NSURL* url = [NSURL URLWithString:@"http://www.apple.com"];
    CFArrayRef apps = LSCopyApplicationURLsForURL((__bridge CFURLRef)url, kLSRolesAll);
    
    NSArray* ret = [NSArray arrayWithArray:(__bridge NSArray*)apps];
    
    return ret;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSArray* availTwitterClients = [self listAvailableTwitterClients];
    
    NSString* preferredTwitterID = nil;
    {
        NSString* twitterURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"preferred_twitter"];
        if(twitterURLString) {
            NSURL* twitterURL = [NSURL URLWithString:twitterURLString];
            NSBundle* twitterBundle = [NSBundle bundleWithURL:twitterURL];
            preferredTwitterID = [twitterBundle bundleIdentifier];
        }
    }
    
    NSMutableArray* appNames = [NSMutableArray array];
    {// set twitter dropdown
        self.twitterNameToURL = [NSMutableDictionary dictionary];
        for(NSURL* bundleURL in availTwitterClients) {
            NSBundle* appBundle = [NSBundle bundleWithURL:bundleURL];
            
            NSString* appName = [[appBundle infoDictionary] objectForKey:@"CFBundleName"];
            
            [self.twitterNameToURL setObject:bundleURL forKey:appName];
    
            // ensures that the current chosen app is shown first
            if([preferredTwitterID caseInsensitiveCompare:[appBundle bundleIdentifier]] == NSOrderedSame) {
                [appNames insertObject:appName atIndex:0];
            } else {
                [appNames addObject:appName];
            }
        }
        
        [self.twitterDropdown removeAllItems];
        [self.twitterDropdown addItemsWithTitles:appNames];
    }
    
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    
    {
        // if we've gotten this far, let's go ahead and show a dock icon.
        
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
        SetFrontProcess(&psn);
    }
}

-(void)openURLString:(NSString*)urlString
{
    NSString* browserID = [self preferredBrowser];;
    
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
    
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:twitterURL
                                                  options:NSWorkspaceLaunchAsync
                                            configuration:nil
                                                    error:NULL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlAsString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    if([urlAsString isEqualToString:@"https://twitter.com/mentions"]) {
        [self openTwitterForURL:urlAsString];
    } else if([urlAsString isEqualToString:@"https://twitter.com/messages"]) {
        [self openTwitterForURL:urlAsString];
    } else {
        [self openURLString:urlAsString];
    }
    
    [[NSApplication sharedApplication] terminate:self];
}

-(void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (IBAction)okayClicked:(id)sender
{
    NSURL* twitterAppURL = [self.twitterNameToURL objectForKey:self.twitterDropdown.selectedItem.title];

    // set the default browser for everything else.
    [[NSUserDefaults standardUserDefaults] setObject:[twitterAppURL absoluteString] forKey:@"preferred_twitter"];
    
    
    // Become the default https handler
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    // TODO: check result codes

    OSStatus httpsResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"https", (__bridge CFStringRef)bundleID);
    
    [[NSApplication sharedApplication] terminate:self];
}

- (IBAction)cancelClicked:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}
@end
