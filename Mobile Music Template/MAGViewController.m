//
//  MAGViewController.m
//  Mobile Music Template
//
//  Created by Jesse Allison on 10/17/12.
//  Copyright (c) 2012 MAG. All rights reserved.
//

#import "MAGViewController.h"
#import <ESTBeaconManager.h>

@interface MAGViewController () <ESTBeaconManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *distance1Label;
@property (weak, nonatomic) IBOutlet UILabel *distance2Label;
@property (weak, nonatomic) IBOutlet UILabel *pollSpeedLabel;

@property (nonatomic, strong) ESTBeaconManager* beaconManager;
@property (nonatomic, strong) ESTBeacon*        beacon1;
@property (nonatomic, strong) ESTBeacon*        beacon2;
- (IBAction)fasterBeaconPoll:(id)sender;
- (IBAction)slowerBeaconPoll:(id)sender;
- (IBAction)getBeaconPollSpeed:(id)sender;

@end

@implementation MAGViewController

@synthesize enabled;
@synthesize enableButton;


#pragma mark - Manager setup

- (void)setupManager
{
    // create manager instance
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    // create sample region object (you can additionaly pass major / minor values)
    ESTBeaconRegion* region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                  identifier:@"EstimoteSampleRegion"];
    
    // start looking for estimote beacons in region
    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
    [self.beaconManager startRangingBeaconsInRegion:region];
}


- (IBAction)fasterBeaconPoll:(id)sender {
    [self.beacon1 connectToBeacon];
    unsigned short pollSpeed = 50;
    [self.beacon1 writeBeaconAdvInterval:pollSpeed withCompletion:^(unsigned short value, NSError *error){NSLog([NSString stringWithFormat:@"Interval: %d", value]);}];
    // [self.beacon1 readBeaconAdvIntervalWithCompletion:^(unsigned short value, NSError *error){NSLog([NSString stringWithFormat:@"Interval: %d", value]);}];
    [self.beacon1 disconnectBeacon];
}

- (IBAction)slowerBeaconPoll:(id)sender {
    [self.beacon1 connectToBeacon];
    unsigned short pollSpeed = 200;
    [self.beacon1 writeBeaconAdvInterval:pollSpeed withCompletion:^(unsigned short value, NSError *error){NSLog([NSString stringWithFormat:@"Interval: %d", value]);}];
    // [self.beacon1 readBeaconAdvIntervalWithCompletion:^(unsigned short value, NSError *error){NSLog([NSString stringWithFormat:@"Interval: %d", value]);}];
    [self.beacon1 disconnectBeacon];
}

- (IBAction)getBeaconPollSpeed:(id)sender {
    [self.beacon1 connectToBeacon];
    [self.beacon1 readBeaconAdvIntervalWithCompletion:^(unsigned short value, NSError *error){self.pollSpeedLabel.text = [NSString stringWithFormat:@"%d", value];}];
    [self.beacon1 disconnectBeacon];
    [self.beacon2 connectToBeacon];
    [self.beacon2 readBeaconAdvIntervalWithCompletion:^(unsigned short value, NSError *error){NSLog([NSString stringWithFormat:@"Poll 2 Interval: %d", value]);}];
    [self.beacon2 disconnectBeacon];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // _________________ LOAD Pd Patch ____________________
    dispatcher = [[PdDispatcher alloc] init];
    [PdBase setDelegate:dispatcher];
    patch = [PdBase openFile:@"iTheremin.pd" path:[[NSBundle mainBundle] resourcePath]];
    if (!patch) {
        NSLog(@"Failed to open patch!");
    }
    enabled = NO;
    [self setupManager];
}

/*
- (void)viewDidUnload
{
    // uncomment for pre-iOS 6 deployment
    [super viewDidUnload];
    [PdBase closeFile:patch];
    [PdBase setDelegate:nil];
}
 */

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ESTBeaconManagerDelegate Implementation

-(void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    if([beacons count] > 1)
    {
        if(!self.beacon1)
        {
            // initially pick closest beacon
            self.beacon1 = [beacons objectAtIndex:0];
        }
        else if(!self.beacon2)
        {
            // initially pick closest beacon
            self.beacon2 = [beacons objectAtIndex:1];
        }
        else
        {
            for (ESTBeacon* cBeacon in beacons)
            {
                // update beacon it same as selected initially
                if([self.beacon1.major unsignedShortValue] == [cBeacon.major unsignedShortValue] &&
                   [self.beacon1.minor unsignedShortValue] == [cBeacon.minor unsignedShortValue])
                {
                    self.beacon1 = cBeacon;
                    NSLog([NSString stringWithFormat:@"Pitch Major:Minor %@ : %@  -- %@ -- %@", [self.beacon1.major stringValue], [self.beacon1.minor stringValue], self.beacon1.macAddress, [self.beacon1.distance stringValue]] );
                }
                
                // update beacon it same as selected initially
                if([self.beacon2.major unsignedShortValue] == [cBeacon.major unsignedShortValue] &&
                   [self.beacon2.minor unsignedShortValue] == [cBeacon.minor unsignedShortValue])
                {
                    self.beacon2 = cBeacon;
                    NSLog([NSString stringWithFormat:@"Amplitude Major:Minor %@ : %@  -- %@ -- %@", [self.beacon2.major stringValue], [self.beacon2.minor stringValue], self.beacon2.macAddress, [self.beacon2.distance stringValue]] );
                }
            }
        }
        
        // based on observation rssi is not getting bigger then -30
        // so it changes from -30 to -100 so we normalize
        //float distFactor = ((float)self.beacon1.rssi + 30) / -70;
        
        // HIGH float distFactor = 1. - ([self.beacon1.distance floatValue] / 20.);
        float distFactor = 0.3 + ([self.beacon1.distance floatValue] / 25.);
        self.distance1Label.text = [NSString stringWithFormat:@"%@ :: %f",[self.beacon1.distance stringValue], distFactor ];
        [self pitch:distFactor];
        
        // float distFactor2 = ((float)self.beacon1.rssi + 30) / -70;
        float distFactor2 = 1 - ([self.beacon2.distance floatValue] / 20.);
        
        self.distance2Label.text = [NSString stringWithFormat:@"%@ :: %f",[self.beacon2.distance stringValue], distFactor2 ];
        [self amplitude:distFactor2];
        
        
        // calculate and set new y position
        // float newYPos = self.dotMinPos + distFactor * self.dotRange;
        // self.positionDot.center = CGPointMake(self.view.bounds.size.width / 2, newYPos);
    }
}



#pragma mark - UI Interactions with Pd Patch
// _________________ UI Interactions with Pd Patch ____________________

- (IBAction)randomPitch:(UIButton *)sender {
    [PdBase sendBangToReceiver:@"random_note"];
}

- (void)pitch:(float)pitch {
    [PdBase sendFloat:pitch toReceiver:@"pitch"];
}

- (void)amplitude:(float)amplitude {
    [PdBase sendFloat:amplitude toReceiver:@"amplitude"];
}

- (IBAction)enable:(UIButton *)sender {
    
    if (enabled) {
        enabled = NO;
        // enableButton.titleLabel = @"Enable";
        [enableButton setTitle:@"Disabled" forState:UIControlStateNormal];
        [PdBase sendFloat:0 toReceiver:@"enable"];
    } else {
        enabled = YES;
        [enableButton setTitle:@"Enabled" forState:UIControlStateNormal];
        [PdBase sendFloat:1 toReceiver:@"enable"];
    }
    
}

@end
