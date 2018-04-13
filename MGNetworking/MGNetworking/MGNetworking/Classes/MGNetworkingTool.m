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

+ (NSString *)tableNameWithString:(NSString *)string {
    return [NSString stringWithFormat:@"T_%@", [self md5WithString:string]];
}

+ (NSString *)generateRandomName {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyyMMddHHmmss";
    NSString *dateString = [fmt stringFromDate:[NSDate date]];
    NSInteger randomNum = arc4random()%900 + 100;
    return [self md5WithString:[NSString stringWithFormat:@"%@%@", dateString, @(randomNum)]];
}

/**
 * 获取已下载的文件大小
 */
+ (unsigned long long)fileLengthForPath:(NSString *)path {
    unsigned long long fileLength = 0;
    NSFileManager *fileManager = [[NSFileManager alloc] init]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileLength = [fileDict fileSize];
        }
    }
    return fileLength;
}

+ (BOOL)deleteFileAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL result = [fileManager removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%s\nLine:%@\nError:%@", __FUNCTION__, @(__LINE__), error.localizedDescription);
    }
    return result;
}

+ (unsigned long long)sizeWithPath:(NSString *)path {
    unsigned long long totalSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            NSArray *pathArr = [fileManager contentsOfDirectoryAtPath:path error:nil];
            for (NSString *name in pathArr) {
                NSString *subPath = [path stringByAppendingPathComponent:name];
                [fileManager fileExistsAtPath:subPath isDirectory:&isDir];
                if (isDir) {
                    totalSize += [self sizeWithPath:subPath];
                } else {
                    totalSize += [[fileManager attributesOfItemAtPath:subPath error:nil] fileSize];
                }
            }
        } else {
            totalSize += [[fileManager attributesOfItemAtPath:path error:nil] fileSize];
        }
    }
    return totalSize;
}

+ (NSArray<NSString *> *)filePathsInPath:(NSString *)path {
    NSMutableArray *filePathArr = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        filePathArr = [[NSMutableArray alloc] init];
        if (isDir) {
            NSArray *pathArr = [fileManager contentsOfDirectoryAtPath:path error:nil];
            for (NSString *name in pathArr) {
                NSString *subPath = [path stringByAppendingPathComponent:name];
                [fileManager fileExistsAtPath:subPath isDirectory:&isDir];
                if (isDir) {
                    NSArray *arr = [self filePathsInPath:subPath];
                    if (arr) {
                        [filePathArr addObjectsFromArray:arr];
                    }
                } else {
                    [filePathArr addObject:subPath];
                }
            }
        } else {
            [filePathArr addObject:path];
        }
    }
    return filePathArr;
}

+ (BOOL)deleteAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        BOOL result = [fileManager removeItemAtPath:path error:&error];
#if DEBUG
        if (error) {
            NSLog(@"删除失败：%@\n%s\nLine:%@", path, __FUNCTION__, @(__LINE__));
        }
#endif
        return result;
    }
    return NO;
}

@end
