//
//  MGFileUploader.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFileUploadProtocol.h"
#import "MGResponseParseProtocol.h"

/**
 文件上传器
 */
@interface MGFileUploader : NSObject

/**设置响应的contentType*/
@property (nonatomic, strong) NSSet<NSString *> *responseContentType;
/**显示错误码*/
@property (nonatomic, assign) BOOL showErrCode;
/**是否需要取消的回调*/
@property (nonatomic, assign) BOOL needCancelCallback;

/**
 创建单例

 @return 单例对象
 */
+ (instancetype)shareInstance;

/**
 上传

 @param urlString 接口
 @param params 参数
 @param files 文件
 @param flag 上传任务记号
 @param progress 进度
 @param parser 成功回调解析器
 @param success 成功
 @param failure 失败
 */
- (void)uploadWithURLString:(nonnull NSString *)urlString
                     params:(nullable id)params
                      files:(nonnull NSArray<id<MGFileUploadDelegate>> *)files
                       flag:(nullable NSString *)flag
             responseParser:(nullable id<MGResponseParseDelegate>)parser
                   progress:(nullable void (^)(NSProgress * _Nonnull progress))progress
                    success:(nullable void (^)(id responseObject))success
                    failure:(nullable void (^)(NSError *error, bool isCancel))failure;

/**
 取消上传

 @param flag 上传标记
 */
- (void)cancelByFlag:(nonnull NSString *)flag;

/**
 取消全部上传任务
 */
+ (void)cancelAll;

@end
