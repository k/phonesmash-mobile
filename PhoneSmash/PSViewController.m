//
//  PSViewController.m
//  PhoneSmash
//
//  Created by Kenneth Bambridge on 7/29/13.
//  Copyright (c) 2013 Kenneth Bambridge. All rights reserved.
//

#import "PSViewController.h"
#import <CoreMotion/CoreMotion.h>

float const kDeviceMotionUpdateInterval = 0.01;
float const kJerkThreshold = 10;
float const kMinGrav = 0.5;
#define kMinForce  0.1
#define kFilterFactor 0.1

@interface PSViewController () {
    CMMotionManager *motion;
    BOOL throwing;
    NSDate *startDate;
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
        [self.view setNeedsDisplay];
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (throwing) {
        self.view.backgroundColor = [UIColor purpleColor];
        [self startMotion];
    }
}

- (void)startMotion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
       ^()     {
           double prevforce = -1;
           startDate = [NSDate date];
           NSDate *prevTime = startDate;
           _restartButton.hidden = NO;
           NSDate *now;
           
           CMDeviceMotion *data;
           double ax, ay, az, gx, gy, gz;
           while (motion.deviceMotionActive) {
               data = motion.deviceMotion;
               now = [NSDate date];
               CMAcceleration accel = data.userAcceleration;
               ax = accel.x;
               ay = accel.y;
               az = accel.z;
               accel = data.gravity;
               gx = accel.x;
               gy = accel.y;
               gz = accel.z;
               
               double force = sqrt(pow(ax, 2) + pow(ay, 2) + pow(az, 2));
               double gforce = sqrt(pow(ax - gx, 2) + pow(ay - gy, 2) + pow(az - gz, 2));
               if (prevforce == -1) prevforce = force;
               double jerk = (force - prevforce) / [now timeIntervalSinceDate:prevTime];
               if (jerk < 0) jerk *= -1;
               
               //        NSString *formatString = @"\nax: %9.5d ay: %9.5d az: %9.5d Force: %9.5d \ngx: %9.5d gy: %9.5d gz: %9.5d Gravity: %9.5d\n Jerk: %9.5d";
               NSLog(@"%2.6f %2.6f %2.6f Force: %2.6f", ax, ay, az, force);
               NSLog(@"%2.6f %2.6f %2.6f Gravity: %2.6f", gx, gy, gz, gforce);
               NSLog(@"  %2.6f", jerk);
               if (-[startDate timeIntervalSinceNow] > 0.2 && (jerk > kJerkThreshold ||  force < kMinForce)) {
                   [motion stopDeviceMotionUpdates];
                   [self updateTime:-[startDate timeIntervalSinceNow]];
                   break;
               }
               prevforce = force;
               prevTime = now;
               [NSThread sleepForTimeInterval:0.04];
           }
       });
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
