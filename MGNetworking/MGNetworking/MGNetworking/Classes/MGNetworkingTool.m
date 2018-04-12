//
//  MGNetworkingTool.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGNetworkingTool.h"
#import <CommonCrypto/CommonDigest.h>

@implementation MGNetworkingTool

/**
 MD5加密
 
 @param input 输入字符串
 @return md5加密后的字符串
 */
+ (NSString *)md5WithString:(NSString *)input {
    if (!input) {
        return nil;
    }
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}

@end
