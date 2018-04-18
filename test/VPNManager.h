//
//  VPNManager.h
//  test
//
//  Created by moonmd.xie on 2018/3/29.
//  Copyright © 2018年 moonmd.xie. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VPNStatus){
 VPNStatus_off,
VPNStatus_connecting,
VPNStatus_on,
VPNStatus_disconnecting,
};
@interface VPNManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic) VPNStatus VPNStatus;

- (void)connect;
- (void)disconnect;

@end
