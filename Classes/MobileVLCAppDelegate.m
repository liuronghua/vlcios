//
//  MobileVLCAppDelegate.m
//  MobileVLC
//
//  Created by Pierre d'Herbemont on 6/27/10.
//  Copyright Applidium 2010. All rights reserved.
//

#import "MobileVLCAppDelegate.h"
#import "MLMediaLibrary.h"
#import <MobileVLCKit/MobileVLCKit.h>
#import "MVLCMovieViewController.h"

@interface MobileVLCAppDelegate (Private)
- (void)_updateMediaLibrary;
@end


@implementation MobileVLCAppDelegate
@synthesize window=_window, navigationController=_navigationController, movieListViewController=_movieListViewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // This will mark crashy files
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

    [_window addSubview:self.navigationController.view];
    [_window setRootViewController:self.navigationController];
    [_window makeKeyAndVisible];

    NSURL * urlToOpen = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if (urlToOpen != nil) {
        // We were started to open a given URL
        MVLCLog(@"Opening URL %@", urlToOpen);
        MVLCMovieViewController * movieViewController = [[MVLCMovieViewController alloc] init];
        movieViewController.url = urlToOpen;
        [self.navigationController presentViewController:0 animated:YES completion:NULL];
        [movieViewController release];
    }

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // The application becomes active after a sync (i.e., file upload)
    [self _updateMediaLibrary];

    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenPasteboardURL"]) {
        // check whether the pasteboard contains a URL we support
        if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:[NSArray arrayWithObjects:@"public.url", @"public.text", nil]]) {
            _pasteURL = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.url"];
            if (!_pasteURL || [[_pasteURL absoluteString] isEqualToString:@""]) {
                NSString * pasteString = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.text"];
                if( _pasteURL )
                    [_pasteURL release];
                _pasteURL = [NSURL URLWithString:pasteString];
            }

            if (_pasteURL && ![[_pasteURL scheme] isEqualToString:@""] && ![[_pasteURL absoluteString] isEqualToString:@""]) {
                NSString * messageString = [NSString stringWithFormat:@"Do you want to open %@?", [_pasteURL absoluteString]];
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Open URL?" message:messageString delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
                [alert show];
                [alert autorelease];
                [_pasteURL retain];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        MVLCMovieViewController * movieViewController = [[MVLCMovieViewController alloc] init];
        movieViewController.url = _pasteURL;
        [self.navigationController presentViewController:movieViewController animated:YES completion:NULL];
        [movieViewController release];
    }

    [_pasteURL release];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    if (_pasteURL)
        [_pasteURL release];

    [_movieListViewController release];
    [_navigationController release];
    [_window release];
    [super dealloc];
}
@end

@implementation MobileVLCAppDelegate (Private)
- (void)_updateMediaLibrary {
#define PIERRE_LE_GROS_CRADE 1
#if TARGET_IPHONE_SIMULATOR && PIERRE_LE_GROS_CRADE
    NSString *directoryPath = @"/Users/pinigin/Desktop/Vids";
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths objectAtIndex:0];
#endif
    MVLCLog(@"Scanning %@", directoryPath);
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[fileNames count]];
    for (NSString * fileName in fileNames) {
        if ([fileName rangeOfString:@"\\.(3gp|3gp|3gp2|3gpp|amv|asf|avi|divx|dv|flv|f4v|gvi|gxf|m1v|m2p|m2t|m2ts|m2v|m4v|mkv|moov|mov|mp2v|mp4|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv|mt2s|mts|mxf|oga|ogm|ogv|ogx|spx|ps|qt|rm|rmvb|ts|tts|vob|webm|wm|wmv)$" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch].length != 0) {
            [filePaths addObject:[directoryPath stringByAppendingPathComponent:fileName]];
        }
    }
    [[MLMediaLibrary sharedMediaLibrary] addFilePaths:filePaths];
    [[MLMediaLibrary sharedMediaLibrary] updateDatabase];
    [self.movieListViewController reloadMedia];
}
@end


