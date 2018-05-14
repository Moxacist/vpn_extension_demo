//
//  VPNManager.m
//  test
//
//  Created by moonmd.xie on 2018/3/29.
//  Copyright © 2018年 moonmd.xie. All rights reserved.
//

#import "VPNManager.h"
#import <NetworkExtension/NetworkExtension.h>

@interface VPNManager()

@property (nonatomic, assign) BOOL observerAdded;
//@property (nonatomic, strong) NETunnelProviderManager *manager;

@end

@implementation VPNManager

#pragma mark - set/get
- (void)setVPNStatus:(VPNStatus)VPNStatus{
    _VPNStatus = VPNStatus;
    if (VPNStatus == VPNStatus_off) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kProxyServiceVPNStatusNotification" object:nil];
    }
}

+ (instancetype)sharedInstance{
    static VPNManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VPNManager alloc] init];
    });
    return manager;
}

- (instancetype)init{
    if (self = [super init]) {
        __weak typeof(self) weakself = self;
        [self loadProviderManager:^(NETunnelProviderManager *manager) {
            
            [weakself updateVPNStatus:manager];
        }];
        
        [self addVPNStatusObserver];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - exposed method
- (void)connect{
    
    [self loadAndCreatePrividerManager:^(NETunnelProviderManager *manager) {
        if (!manager) {
            return ;
        }
        NSError *error;
        [manager.connection startVPNTunnelWithOptions:@{} andReturnError:&error];
        if (error) {
            NSLog(@"start error");
        }else{
            NSLog(@"rsssss");
        }
    }];
    
}
    
    
    
    
    
- (void)disconnect{
    [self loadProviderManager:^(NETunnelProviderManager *manager) {
        [manager.connection stopVPNTunnel];
    }];
}

#pragma mark - private method

- (void)loadProviderManager:(void(^)(NETunnelProviderManager *manager))pm{
    
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers.count > 0) {
            pm(managers.firstObject);
            return ;
        }
        return pm(nil);
    }];
}

- (NETunnelProviderManager *)createProviderManager{
    
    NETunnelProviderManager *manager = [[NETunnelProviderManager alloc] init];
    NETunnelProviderProtocol *conf = [[NETunnelProviderProtocol alloc] init];
    conf.serverAddress = @"name";
    manager.protocolConfiguration = conf;
    manager.localizedDescription = @"vpn name show";
    return manager;
}

- (void)loadAndCreatePrividerManager:(void(^)(NETunnelProviderManager *manager))compelte{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        NETunnelProviderManager *manager = [[NETunnelProviderManager alloc] init];
        if (managers.count>0) {
            manager = managers.firstObject;
            if (managers.count>1) {
                for (NETunnelProviderManager* manager in managers) {
                    [manager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                        if (error == nil) {
                            NSLog(@"remove dumplicate VPN config successful!");
                        }else{
                            NSLog(@"remove dumplicate VPN config failed with %@", error);
                        }
                    }];
                }
            }
        }else{
            manager = [self createProviderManager];
        }
        manager.enabled = YES;
        
        //set rule config
        NSMutableDictionary *conf = @{}.mutableCopy;
        conf[@"ss_address"] = @"170.218.212.145";
        conf[@"ss_port"] = @8888;
        conf[@"ss_method"] = @"RC4MD5";// 大写 没有横杠 看Extension中的枚举类设定 否则引发fatal error
        conf[@"ss_password"] = @"ceshi";
        
        conf[@"ymal_conf"] = [self getRuleConf];
        NETunnelProviderProtocol *orignConf = (NETunnelProviderProtocol *)manager.protocolConfiguration;
        orignConf.providerConfiguration = conf;
        manager.protocolConfiguration = orignConf;
        
        //save vpn
        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            if (error == nil) {
                //注意这里保存配置成功后，一定要再次load，否则会导致后面StartVPN出异常
                [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (error == nil) {
                        NSLog(@"save vpn success");
                        compelte(manager);return;
                    }
                    compelte(nil);return;
                }];
            }else{
                compelte(nil);return;
            }
        }];
    }];
}

- (NSString *)getRuleConf{
    NSString * Path = [[NSBundle mainBundle] pathForResource:@"NEKitRule" ofType:@"conf"];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:Path]];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


#pragma mark - tool

- (void)updateVPNStatus:(NEVPNManager *)manager{
    switch (manager.connection.status) {
        case NEVPNStatusConnected:
            self.VPNStatus = VPNStatus_on;
            break;
        case NEVPNStatusConnecting:
            self.VPNStatus = VPNStatus_connecting;
            break;
        case NEVPNStatusReasserting:
            self.VPNStatus = VPNStatus_connecting;
            break;
        case NEVPNStatusDisconnecting:
            self.VPNStatus = VPNStatus_disconnecting;
            break;
        case NEVPNStatusDisconnected:
            self.VPNStatus = VPNStatus_off;
            break;
        case NEVPNStatusInvalid:
            self.VPNStatus = VPNStatus_off;
            break;
        default:
            break;
    }
}

- (void)addVPNStatusObserver{
    if (self.observerAdded) {
        return;
    }
    
    
    [self loadProviderManager:^(NETunnelProviderManager *manager) {
        if (manager) {
            self.observerAdded = true;
            [[NSNotificationCenter defaultCenter] addObserverForName:NEVPNStatusDidChangeNotification
                                                              object:manager.connection
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification * _Nonnull note) {
                                                              [self updateVPNStatus:manager];
                                                          }];
        }
    }];
}




#pragma mark---old
@end
