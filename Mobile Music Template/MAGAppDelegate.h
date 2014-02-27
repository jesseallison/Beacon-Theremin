//
//  MAGAppDelegate.h
//  Mobile Music Template
//
//  Created by Jesse Allison on 10/17/12.
//  Copyright (c) 2012 MAG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PdAudioController.h"

@class MAGViewController;

@interface MAGAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MAGViewController *viewController;
@property (nonatomic, strong,readonly) PdAudioController *audioController;


@end
