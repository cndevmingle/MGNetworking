//
//  MGFileUploader.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGFileUploader.h"
#import "MGNetworkingTool.h"
#import "MGNetworkingErrorExplainer.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <MJExtension/MJExtension.h>

/**上传任务*/
static NSMutableDictionary<NSString *, NSURLSessionTask *> *taskDictionary;

@interface MGFileUploader ()

/**网络请求对象*/
@property (nonatomic, strong) AFHTTPSessionManager *uploaderManager;

@end

@implementation MGFileUploader

+ (instancetype)shareInstance {
    static MGFileUploader *uploader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uploader = [[MGFileUploader alloc] init];
    });
    return uploader;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _needCancelCallback = YES;
    taskDictionary = [NSMutableDictionary dictionary];
    _uploaderManager = [AFHTTPSessionManager manager];
    AFJSONResponseSerializer *jsonRS = [AFJSONResponseSerializer serializer];
    jsonRS.removesKeysWithNullValues = YES;
    _uploaderManager.responseSerializer = jsonRS;
}

- (void)setResponseContentType:(NSSet<NSString *> *)responseContentType {
    _uploaderManager.responseSerializer.acceptableContentTypes = responseContentType;
}

- (void)uploadWithURLString:(nonnull NSString *)urlString
                     params:(nullable id)params
                      files:(nonnull NSArray<id<MGFileUploadDelegate>> *)files
                       flag:(nullable NSString *)flag
             responseParser:(nullable id<MGResponseParseDelegate>)parser
                   progress:(nullable void (^)(NSProgress * _Nonnull))progress
                    success:(nullable void (^)(id responseObject))success
                    failure:(nullable void (^)(NSError *error, bool isCancel))failure {
    
    NSString *taskKey = flag?:[MGNetworkingTool generateRandomName];
    __weak typeof(self) weakSelf = self;
    NSURLSessionTask *task = [_uploaderManager POST:urlString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (id<MGFileUploadDelegate> file in files) {
            [formData appendPartWithFileData:file.fileData name:file.fieldName fileName:file.fileSaveName mimeType:file.mimeType];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error = nil;
        if ([parser respondsToSelector:@selector(validate:)]) {
            error = [parser validate:responseObject];
        }
        if (error) { // 后台返回错误信息
            NSError *explainErr = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@%@%@", error.localizedFailureReason, weakSelf.showErrCode?@" Code:":@"", weakSelf.showErrCode?@(error.code):@""]}];
            if (failure) {
                failure(explainErr, NO);
            }
        } else { // 没有错误
            // 获取内容
            id content;
            if ([parser respondsToSelector:@selector(getContent:)]) {
                content = [parser getContent:responseObject];
            } else {
                content = responseObject;
            }
            
            // 将内容转换成model返回
            id result = nil;
            if ([parser respondsToSelector:@selector(modelClass)]) {
                if ([content isKindOfClass:[NSArray class]]) {
                    result = [parser.modelClass mj_objectArrayWithKeyValuesArray:content];
                } else if ([content isKindOfClass:[NSDictionary class]]) {
                    result = [parser.modelClass mj_objectWithKeyValues:content];
                } else if ([content isKindOfClass:[NSString class]] || [content isKindOfClass:[NSData class]]) {
                    result = [parser.modelClass mj_objectWithKeyValues:[content mj_JSONObject]];
                } else {
                    result = content;
                }
            } else {
                result = content;
            }
            
            if (success) {
                success(result?:responseObject);
            }
        }
        [taskDictionary removeObjectForKey:taskKey];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (weakSelf.needCancelCallback || error.code != NSURLErrorCancelled) {
            NSError *explainErr = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@%@%@", [MGNetworkingErrorExplainer errorMessageInChineseWithError:error], weakSelf.showErrCode?@" Code:":@"", weakSelf.showErrCode?@(error.code):@""]}];
            if (failure) {
                failure(explainErr, explainErr.code == NSURLErrorCancelled);
            }
        }
        [taskDictionary removeObjectForKey:taskKey];
    }];
    [taskDictionary setObject:task forKey:taskKey];
}

- (void)cancelByFlag:(nonnull NSString *)flag {
    [[taskDictionary objectForKey:flag] cancel];
}

+ (void)cancelAll {
    [taskDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSURLSessionTask * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

@end
