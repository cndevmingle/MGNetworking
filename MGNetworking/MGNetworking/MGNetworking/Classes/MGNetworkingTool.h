//
//  MGNetworkingTool.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifndef kMGDocumentDirPath
#define kMGDocumentDirPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
#endif
#define kMGNetworkingPath [kMGDocumentDirPath stringByAppendingPathComponent:@"MGNetworking"]
#define kMGNetworkingCacheDBName @"MGNetworkingCache.sqlite"
#define KMGNetworkingCachePath [[kMGNetworkingPath stringByAppendingPathComponent:@"Cache"] stringByAppendingPathComponent:kMGNetworkingCacheDBName]
// 下载文件保存目录
#define kMGNetwokringDownloadPath [kMGNetworkingPath stringByAppendingPathComponent:@"Download"]

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

/**
 * 获取已下载的文件大小
 */
+ (unsigned long long)fileLengthForPath:(NSString *)path;

/**
 删除文件

 @param path 路径
 @return 返回是否成功
 */
+ (BOOL)deleteFileAtPath:(NSString * _Nonnull)path;

/**
 获取目录下所有文件的大小

 @param path 目录
 @return 大小(Byte)
 */
+ (unsigned long long)sizeWithPath:(NSString * _Nonnull)path;

/**
 获取目录中所有的文件路径，不包含文件夹

 @param path 指定目录
 @return 文件路径
 */
+ (NSArray<NSString *> * _Nullable)filePathsInPath:(NSString * _Nonnull)path;

/**
 删除目录和下面的文件，也可以删除指定的单个文件

 @param path 路径
 @return 是否成功
 */
+ (BOOL)deleteAtPath:(NSString * _Nonnull)path;

@end
