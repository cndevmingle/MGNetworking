//
//  MGFileDownloader.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "MGDownloadFile.h"
#import "MGResponseParseProtocol.h"

typedef NS_ENUM(NSUInteger, MGFileDownloadPolicy) {
    /// 如果本地存在会覆盖下载
    MGFileDownloadPolicyCover,
    /// 断点续传
    MGFileDownloadPolicyResume,
    /// 如果已经存在则直接使用，不会重新下载
    MGFileDownloadPolicyUseOlderFile
};

/**
 文件下载器
 */
@interface MGFileDownloader : NSObject

/**下载会话管理*/
@property (nonatomic, strong, readonly) AFURLSessionManager *sessionManager;

/**是否显示错误码*/
@property (nonatomic, assign) BOOL showErrorCode;

/**
 获取单例

 @return 单例对象
 */
+ (instancetype)shareInstance;

/**
 下载

 @param urlString 文件地址
 @param downloadPolicy 下载策略
 @param parser 数据解析器
 @param progress 进度
 @param success 成功
 @param failure 失败
 */
- (void)downloadWithURLString:(NSString * _Nonnull)urlString
               downloadPolicy:(MGFileDownloadPolicy)downloadPolicy
               responseParser:(nullable Class<MGResponseParseDelegate>)parser
                     progress:(nullable void(^)(NSProgress * _Nullable progress, MGDownloadFile * _Nonnull fileObj))progress
                      success:(nullable void(^)(MGDownloadFile *file, id _Nullable response))success
                      failure:(nullable void(^)(NSError *error, BOOL isCancel))failure;

/**
 取消某个地址的文件下载

 @param urlString 下载地址
 @param deleteData 删除已下载文件部分
 */
- (void)cancelByURLString:(NSString * _Nonnull)urlString deleteFileData:(BOOL)deleteData;

@end
