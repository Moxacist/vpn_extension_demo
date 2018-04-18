//
//  ViewController.m
//  TestVPNExtention
//
//  Created by moonmd.xie on 2018/3/28.
//  Copyright © 2018年 moonmd.xie. All rights reserved.
//

#import "ViewController.h"
#import "VPNManager.h"

#import <NetworkExtension/NetworkExtension.h>


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *showBtn;
@property (nonatomic) VPNStatus status;

@property (nonatomic, strong) NETunnelProviderManager *manager;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = VPNStatus_off;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onVPNStatusChanged)
                                                     name:@"kProxyServiceVPNStatusNotification"
                                                   object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - eeeeeeee
    
- (void)viewDidLoad {
    [super viewDidLoad];
}
    
    
#pragma mark - eeeeeeee

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.status = [VPNManager sharedInstance].VPNStatus;
}

- (void)updateBtnStatus{
    switch (self.status) {
        case VPNStatus_connecting:
            [self.showBtn setTitle:@"connecting" forState:UIControlStateNormal];
            break;
            
        case VPNStatus_disconnecting:
            [self.showBtn setTitle:@"disconnect" forState:UIControlStateNormal];
            break;
            
        case VPNStatus_on:
            [self.showBtn setTitle:@"Disconnect" forState:UIControlStateNormal];
            break;
            
        case VPNStatus_off:
            [self.showBtn setTitle:@"Connect" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    self.showBtn.enabled = [VPNManager sharedInstance].VPNStatus == VPNStatus_on||[VPNManager sharedInstance].VPNStatus == VPNStatus_off;
}

- (IBAction)touchBtn:(id)sender {
    
    if([VPNManager sharedInstance].VPNStatus == VPNStatus_off){
        [[VPNManager sharedInstance] connect];
    }else{
        [[VPNManager sharedInstance] disconnect];
    }
    
}


#pragma mark - 收到监听通知处理
- (void)onVPNStatusChanged{
    self.status = [VPNManager sharedInstance].VPNStatus;
}

#pragma mark - get/set
- (void)setStatus:(VPNStatus)status{
    _status = status;
    [self updateBtnStatus];
}




@end
