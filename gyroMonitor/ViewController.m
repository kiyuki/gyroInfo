//
//  ViewController.m
//  gyroMonitor
//
//  Created by 海老晃行 on 2019/07/29.
//  Copyright © 2019 海老晃行. All rights reserved.
//

#import "ViewController.h"
#import "CoreMotion/CoreMotion.h"
@import SocketIO;

@interface ViewController ()
@property CMMotionManager *motionManager;
@property NSURL* url;
@property SocketManager* manager;
@property SocketIOClient* socket;
@property float gyroOrManu;
@property float posi;
@property NSMutableDictionary* gyro;
@property (weak, nonatomic) IBOutlet UILabel *pitch;
@property (weak, nonatomic) IBOutlet UILabel *roll;
@property (weak, nonatomic) IBOutlet UILabel *yaw;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;
- (IBAction)changeGyroManu:(UISwitch *)sender;
- (IBAction)posi1:(UIButton *)sender;
- (IBAction)posi2:(UIButton *)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.motionManager = [[CMMotionManager alloc] init];
    [self setupAccelerometer];
    self.url = [[NSURL alloc] initWithString:@"http://192.168.100.154:5000"];
    self.manager = [[SocketManager alloc] initWithSocketURL:self.url config:@{@"log": @YES, @"compress": @YES}];
    self.socket = self.manager.defaultSocket;
    
    [self.socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
    }];
    
    [self.socket connect]; 
    self.gyro = [NSMutableDictionary dictionary];
    [self.gyro setObject:[NSNumber numberWithInt:0] forKey:@"roll"];
    [self.gyro setObject:[NSNumber numberWithInt:0] forKey:@"pitch"];
    [self.gyro setObject:[NSNumber numberWithInt:0] forKey:@"yaw"];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)setupAccelerometer{
    if(self.motionManager.deviceMotionAvailable){
        self.motionManager.deviceMotionUpdateInterval = 0.1f;
        
        CMDeviceMotionHandler handler2 = ^(CMDeviceMotion *motion, NSError *error){
            CATransform3D pitch = CATransform3DMakeRotation(motion.attitude.pitch,  1, 0, 0);
            CATransform3D roll = CATransform3DMakeRotation(motion.attitude.roll, 0, 1, 0);
            CATransform3D yaw = CATransform3DMakeRotation(motion.attitude.yaw, 0, 0, 1);
            self.arrowImage.layer.transform = CATransform3DConcat(CATransform3DConcat(yaw, pitch), roll);
            double x = motion.attitude.pitch * 180 / M_PI;
            double y = motion.attitude.roll * 180 / M_PI;
            double z = motion.attitude.yaw * 180 / M_PI;
            [self.gyro setObject:[NSNumber numberWithDouble:x] forKey:@"pitch"];
            [self.gyro setObject:[NSNumber numberWithDouble:y] forKey:@"roll"];
            [self.gyro setObject:[NSNumber numberWithDouble:z] forKey:@"yaw"];
            [self.gyro setObject:[NSNumber numberWithFloat:self.gyroOrManu] forKey:@"gyroOrManu"];
            [self.gyro setObject:[NSNumber numberWithFloat:self.posi] forKey:@"posi"];
            [self.socket emit:@"gyro" with:[NSArray arrayWithObject:self.gyro]];
            self.pitch.text = [NSString stringWithFormat:@"pitch: %f", x];
            self.roll.text = [NSString stringWithFormat:@"roll_: %f", y];
            self.yaw.text = [NSString stringWithFormat:@"yaw: %f", z];
            NSLog(@"%lf, %lf, %lf", x, y, z);
        };
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler2];
    }
}


- (IBAction)changeGyroManu:(UISwitch *)sender {
    if(sender.isOn){
        self.gyroOrManu = 1;
    }else{
        self.gyroOrManu = 0;
    }
}

- (IBAction)posi1:(UIButton *)sender {
    self.posi = 1;
}

- (IBAction)posi2:(UIButton *)sender {
    self.posi = 2;
}
@end
