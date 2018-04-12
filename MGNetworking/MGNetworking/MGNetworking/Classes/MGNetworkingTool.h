//
//  MGNetworkingTool.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMGNetworkingCacheDBName @"MGNetworkingCache.sqlite"

@interface MGNetworkingTool : NSObject

/**
 md5加密字符串

 @param originString 原始字符串
 @return md5加密后的字符串
 */
+ (NSString *)md5WithString:(NSString *)originString;

@end
