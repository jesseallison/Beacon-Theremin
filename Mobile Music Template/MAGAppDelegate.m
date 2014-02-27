//
//  MAGAppDelegate.m
//  Mobile Music Template
//
//  Created by Jesse Allison on 10/17/12.
//  Copyright (c) 2012 MAG. All rights reserved.
//

#import "MAGAppDelegate.h"
#import "MAGViewController.h"

@implementation MAGAppDelegate

@synthesize audioController = _audioController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // _________________INITIALIZE Pd AUDIO____________________
    
    _audioController = [[PdAudioController alloc] init];
    /*if ([self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:NO mixingEnabled:YES] != PdAudioOK) {
        NSLog(@"failed to initialize audio components");
    }*/
    
    if ([self.audioController configureAmbientWithSampleRate:44100 numberChannels:2 mixingEnabled:YES] != PdAudioOK) {
        NSLog(@"failed to initialize audio components");
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    self.audioController.active = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // _________________ ENABLE AUDIO ____________________
    self.audioController.active = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    self.audioController.active = NO;
}

@end
