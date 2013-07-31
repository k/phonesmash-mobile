//
//  PSViewController.m
//  PhoneSmash
//
//  Created by Kenneth Bambridge on 7/29/13.
//  Copyright (c) 2013 Kenneth Bambridge. All rights reserved.
//

#import "PSViewController.h"
#import <CoreMotion/CoreMotion.h>

float const kDeviceMotionUpdateInterval = 0.05;
float const kInstantAccel = 10;
float const kMinForce = 3;
#define kFilterFactor 0.1

@interface PSViewController () {
    CMMotionManager *motion;
    BOOL throwing;
}
@property (strong, nonatomic) IBOutlet UIButton *restartButton;
- (IBAction)restart:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *timerLabel;
@end

@implementation PSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    motion = [[CMMotionManager alloc]init];
    motion.deviceMotionUpdateInterval = kDeviceMotionUpdateInterval;
    NSLog(@"%d", motion.deviceMotionAvailable);
    self.view.backgroundColor = [UIColor whiteColor];

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!throwing) {
        self.view.backgroundColor = [UIColor greenColor];
        [motion startDeviceMotionUpdates];
        throwing = YES;
    } else { // Temporary for testing purposes
        [motion stopDeviceMotionUpdates];
        self.view.backgroundColor = [UIColor whiteColor];
        _restartButton.hidden = NO;
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (throwing) {
        self.view.backgroundColor = [UIColor purpleColor];
        [self startMotion];
    }
}

- (void)startMotion {
    double prevforce = -1;
    NSDate *startTime = [NSDate date];
    _restartButton.hidden = NO;
    
    CMDeviceMotion *data;
    double ax, ay, az, gx, gy, gz;
    while (motion.deviceMotionActive) {
        data = motion.deviceMotion;
        CMAcceleration accel = data.userAcceleration;
        ax = accel.x - (accel.x * kFilterFactor) + (ax * (1 - kFilterFactor));
        ay = accel.y - (accel.y * kFilterFactor) + (ay * (1 - kFilterFactor));
        az = accel.z - (accel.z * kFilterFactor) + (az * (1 - kFilterFactor));
        gx = (accel.x * kFilterFactor) + (gx * (1 - kFilterFactor));
        gy = (accel.y * kFilterFactor) + (gy * (1 - kFilterFactor));
        gz = (accel.z * kFilterFactor) + (gz * (1 - kFilterFactor));
        
        double force = sqrt(pow(ax, 2) + pow(ay, 2) + pow(az, 2));
        double gforce = sqrt(pow(gx, 2) + pow(gy, 2) + pow(gz, 2));
//        double gforce = sqrt(pow(ax - gx, 2) + pow(ay - gy, 2) + pow(az - gz, 2));
//        double jerk = abs(force - prevforce) / kDeviceMotionUpdateInterval;
        
//        NSString *formatString = @"\nax: %9.5d ay: %9.5d az: %9.5d Force: %9.5d \ngx: %9.5d gy: %9.5d gz: %9.5d Gravity: %9.5d\n Jerk: %9.5d";
        NSLog(@"%2.6f %2.6f %2.6f Force: %2.6f", ax, ay, az, force);
        NSLog(@"%2.6f %2.6f %2.6f Gravity: %2.6f", gx, gy, gz, gforce);
//        if (-[startTime timeIntervalSinceNow] > 0.2 && force > kInstantAccel) {
//             [motion stopDeviceMotionUpdates];
//             [self updateTime:-[startTime timeIntervalSinceNow]];
//             break;
//         }
        prevforce = force;
        [NSThread sleepForTimeInterval:0.05];
    }
}

- (void)updateTime:(NSTimeInterval) time {
    self.view.backgroundColor = [UIColor whiteColor];
    _timerLabel.text = [NSString stringWithFormat:@"%d:%d", (int) time, ((int)(time * 100)) % 100];
    _restartButton.hidden = NO;
    
}

- (IBAction)restart:(UIButton *)sender {
    throwing = NO;
    _restartButton.hidden = YES;
//    [_restartButton setNeedsDisplay];
}
@end
