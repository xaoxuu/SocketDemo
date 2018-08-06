//
//  IPAddress.m
//  SocketDemo
//
//  Created by xaoxuu on 2018/7/5.
//  Copyright © 2018 Titan Studio. All rights reserved.
//

#import "IPAddress.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <UIKit/UIKit.h>

#if TARGET_IPHONE_SIMULATOR
#define SIMULATOR 1
#elif TARGET_OS_IPHONE
#define SIMULATOR 0
#endif


static inline NSString *deviceIPAdress() {
    NSString *address;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    
    if (success == 0) { // 0 表示获取成功
        
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    if (!address.length) {
#if TARGET_IPHONE_SIMULATOR
            address = @"10.8.12.24";
#endif
    }
    NSLog(@"手机的IP是：%@", address);
    return address;
}

@implementation IPAddress

+ (NSString *)ip{
    return deviceIPAdress();
}
    
@end
