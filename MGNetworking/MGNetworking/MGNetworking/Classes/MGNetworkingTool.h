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

/**
 获取表名

 @param string 字符串
 @return 表名
 */
+ (NSString *)tableNameWithString:(NSString *)string;

/**
 根据时间和随机数生成一个md5的字符串作为名称

 @return 随机名称
 */
+ (NSString *)generateRandomName;

@end
