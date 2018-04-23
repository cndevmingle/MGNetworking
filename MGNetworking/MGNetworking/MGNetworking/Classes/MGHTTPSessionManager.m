//
//  MGNetworking.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGHTTPSessionManager.h"
#import "MGNetworkingTool.h"
#import "MGNetworkingErrorExplainer.h"
#import <YTKKeyValueStore/YTKKeyValueStore.h>
#import <MJExtension/MJExtension.h>

typedef NS_ENUM(NSUInteger, MGNetworkingMethod) {
    MGNetworkingPost,
    MGNetworkingGet
};

@interface MGHTTPSessionManager ()

/**默认网络请求*/
@property (nonatomic, strong, readwrite) AFHTTPSessionManager *defaultManager;
/**任务字典*/
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionTask *> *taskDictionary;
/**超时时间*/
@property (nonatomic, assign) NSTimeInterval timeout;
/**基本地址*/
@property (nonatomic, copy) NSString *baseURLString;
/**数据接收类型*/
@property (nonatomic, strong) NSSet<NSString *> *responseContentType;
/**缓存管理*/
@property (nonatomic, strong) YTKKeyValueStore *store;
/**是否显示错误码*/
@property (nonatomic, assign) BOOL showErrCode;
/**是否需要取消的回调*/
@property (nonatomic, assign) BOOL needCancelCallback;

@end

@implementation MGHTTPSessionManager

#pragma mark - 创建单例
+ (instancetype)shareInstance {
    static MGHTTPSessionManager *networking;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networking = [[MGHTTPSessionManager alloc] init];
    });
    return networking;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

#pragma mark - 初始化配置信息
- (void)setup {
    
    _taskDictionary = [[NSMutableDictionary alloc] init];
    
    _responseContentType = [NSSet setWithObject:@"text/html"];
    
    _needCancelCallback = YES;
    
    _showErrCode = NO;
    
    _timeout = 20;
    
    // 设置缓存信息
    [self createCacheDirectory];
    _store = [[YTKKeyValueStore alloc] initWithDBWithPath:KMGNetworkingCachePath];
}

- (NSString *)createCacheDirectory {
    NSString *cacheDirPath = [KMGNetworkingCachePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exists = [fileManager fileExistsAtPath:cacheDirPath isDirectory:&isDir];
    if (!exists || !isDir) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:cacheDirPath withIntermediateDirectories:YES attributes:nil error:&error];
#if DEBUG
        if (error) {
            NSLog(@"创建缓存目录失败：%@\n%s\nLine:%@", cacheDirPath, __FUNCTION__, @(__LINE__));
        }
#endif
    }
    return cacheDirPath;
}

- (AFHTTPSessionManager *)defaultManager {
    if (!_defaultManager) {
        _defaultManager = [MGHTTPSessionManager createHttpSessionManager];
    }
    return _defaultManager;
}

+ (void)configHTTPSessionManager:(void (^)(AFHTTPSessionManager * _Nonnull))block {
    block([MGHTTPSessionManager shareInstance].defaultManager);
}

+ (AFHTTPSessionManager *)createHttpSessionManager {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[MGHTTPSessionManager shareInstance].baseURLString?[NSURL URLWithString:[MGHTTPSessionManager shareInstance].baseURLString]:nil];
    manager.requestSerializer.timeoutInterval = [MGHTTPSessionManager shareInstance].timeout;
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    AFJSONResponseSerializer *jsonRS = [AFJSONResponseSerializer serializer];
    jsonRS.removesKeysWithNullValues = YES;
    jsonRS.acceptableContentTypes = [MGHTTPSessionManager shareInstance].responseContentType;
    manager.responseSerializer = jsonRS;
    return manager;
}

+ (void)setTimeout:(NSTimeInterval)timeout {
    [MGHTTPSessionManager shareInstance].timeout = timeout;
}

+ (void)setBaseURLString:(NSString *)baseURLString {
    [MGHTTPSessionManager shareInstance].baseURLString = baseURLString;
}

+ (void)showErrorCode:(BOOL)showErrCode {
    [MGHTTPSessionManager shareInstance].showErrCode = showErrCode;
}

+ (void)needCancelCallback:(BOOL)need {
    [MGHTTPSessionManager shareInstance].needCancelCallback = need;
}

+ (void)setResponseContentTypes:(NSSet<NSString *> *)contentTypes {
    [MGHTTPSessionManager shareInstance].responseContentType = contentTypes;
}

+ (void)postWithURLString:(NSString *)urlString
                   params:(id)params
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(Class<MGResponseParseDelegate>)parser
                  success:(void (^)(id, bool))success
                  failure:(void (^)(NSError *, BOOL))failure {
    [[MGHTTPSessionManager shareInstance] requestWithURLString:urlString params:params method:MGNetworkingPost cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

+ (void)postWithURLString:(NSString *)urlString params:(id)params success:(void (^)(id, bool))success failure:(void (^)(NSError *, BOOL))failure {
    [self postWithURLString:urlString params:params cachePolicy:MGNetworkingCahchePolicyNone responseParser:nil success:success failure:failure];
}

+ (void)getWithURLString:(NSString *)urlString params:(id)params cachePolicy:(MGNetworkingCahchePolicy)cachePolicy responseParser:(Class<MGResponseParseDelegate>)parser success:(void (^)(id, bool))success failure:(void (^)(NSError *, BOOL))failure {
    [[MGHTTPSessionManager shareInstance] requestWithURLString:urlString params:params method:MGNetworkingGet cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

+ (void)getWithURLString:(NSString *)urlString params:(id)params success:(void (^)(id, bool))success failure:(void (^)(NSError *, BOOL))failure {
    [self getWithURLString:urlString params:params cachePolicy:MGNetworkingCahchePolicyNone responseParser:nil success:success failure:failure];
}

#pragma mark - 核心请求方法
- (void)requestWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
                      method:(MGNetworkingMethod)method
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(nullable Class<MGResponseParseDelegate>)parser
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure {
    // 创建缓存表
    NSString *cacheTableName = [MGNetworkingTool tableNameWithString:urlString];
    NSString *cacheId = [MGNetworkingTool md5WithString:[params mj_JSONString]];
    if (cachePolicy != MGNetworkingCahchePolicyNone && urlString) {
        [[MGHTTPSessionManager shareInstance].store createTableWithName:cacheTableName];
    }
    
    // 查询缓存并返回
    id cache = [[MGHTTPSessionManager shareInstance] cacheInTable:cacheTableName modelClass:[parser respondsToSelector:@selector(modelClass)]?[parser modelClass]:nil];
    if (cache) {
        if (success) {
            success(cache, YES);
        }
    }
    
    __weak typeof(self) weakSelf = self;
    void (^requestSuccessBlock)(NSURLSessionTask *, id) = ^(NSURLSessionTask * _Nonnull task, id _Nullable responseObject){
        
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
                    result = [[parser modelClass] mj_objectArrayWithKeyValuesArray:content];
                } else if ([content isKindOfClass:[NSDictionary class]]) {
                    result = [[parser modelClass] mj_objectWithKeyValues:content];
                } else if ([content isKindOfClass:[NSString class]] || [content isKindOfClass:[NSData class]]) {
                    result = [[parser modelClass] mj_objectWithKeyValues:[content mj_JSONObject]];
                } else {
                    result = content;
                }
            } else {
                result = content;
            }
            
            if (success) {
                success(result?:responseObject, NO);
            }
            
            // 缓存工作
            BOOL needCache = NO;
            switch (cachePolicy) {
                case MGNetworkingCahchePolicyRefresh:
                    // 刷新缓存，删除旧缓存数据
                    [[MGHTTPSessionManager shareInstance].store clearTable:cacheTableName];
                    needCache = YES;
                    break;
                case MGNetworkingCahchePolicyAppend:
                    // 追加缓存
                    needCache = YES;
                    break;
                default:
                    // 不缓存
                    needCache = NO;
                    break;
            }
            if (needCache) {
                [MGHTTPSessionManager cacheContent:content cacheId:cacheId inTable:cacheTableName];
            }
            
        }
        [weakSelf.taskDictionary  removeObjectForKey:cacheTableName];
    };
    
    void (^failureBlock)(NSURLSessionTask *, NSError *) = ^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        if (weakSelf.needCancelCallback || error.code != NSURLErrorCancelled) {
            NSError *explainErr = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@%@%@", [MGNetworkingErrorExplainer errorMessageInChineseWithError:error], weakSelf.showErrCode?@" Code:":@"", weakSelf.showErrCode?@(error.code):@""]}];
            if (failure) {
                failure(explainErr, explainErr.code == NSURLErrorCancelled);
            }
        }
        [weakSelf.taskDictionary  removeObjectForKey:cacheTableName];
    };
    AFHTTPSessionManager *manager = self.defaultManager;
    NSURLSessionTask *task;
    if (method == MGNetworkingPost) {
        task = [manager POST:urlString parameters:params progress:nil success:requestSuccessBlock failure:failureBlock];
    } else {
        task = [manager GET:urlString parameters:params progress:nil success:requestSuccessBlock failure:failureBlock];
    }
    [weakSelf.taskDictionary setObject:task forKey:cacheTableName];
}

#pragma mark - 取消网络请求
+ (void)cancelByURLString:(NSString *)urlString {
    [[[MGHTTPSessionManager shareInstance].taskDictionary objectForKey:[MGNetworkingTool tableNameWithString:urlString]] cancel];
}

+ (void)cancelAll {
    [[MGHTTPSessionManager shareInstance].taskDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSURLSessionTask * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

#pragma mark - 实例方法
- (void)configHTTPSessionManager:(void (^)(AFHTTPSessionManager * _Nonnull))block {
    block(self.defaultManager);
}

/**
 设置baseURL，后面调用接口时就不用再加服务器地址，可以不设置，但是调用接口时必须拼上服务器地址
 
 @param baseURLString 服务器接口地址
 */
- (void)setBaseURLString:(NSString *)baseURLString {
    _baseURLString = baseURLString;
}

/**
 设置超时时间，默认20s
 
 @param timeout 时间
 */
- (void)setTimeout:(NSTimeInterval)timeout {
    _timeout = timeout;
}

- (void)showErrorCode:(BOOL)showErrCode {
    _showErrCode = showErrCode;
}

- (void)needCancelCallback:(BOOL)need {
    _needCancelCallback = need;
}

/**
 设置返回数据接收类型
 */
- (void)setResponseContentTypes:(NSSet<NSString *> *)contentTypes {
    _responseContentType = contentTypes;
}

/**
 post请求
 
 @param urlString 接口
 @param params 参数
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
- (void)postWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure {
    [self postWithURLString:urlString params:params cachePolicy:MGNetworkingCahchePolicyNone responseParser:nil success:success failure:failure];
}

/**
 post请求
 
 @param urlString 接口
 @param params 参数
 @param cachePolicy 缓存策略
 @param parser 数据解析器
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
- (void)postWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(nullable Class<MGResponseParseDelegate>)parser
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure {
    [self requestWithURLString:urlString params:params method:MGNetworkingPost cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

/**
 get请求
 
 @param urlString 接口
 @param params 参数
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
- (void)getWithURLString:(nonnull NSString *)urlString
                  params:(nullable id)params
                 success:(nullable void (^)(id responseObj, bool isCache))success
                 failure:(nullable void (^)(NSError *error, BOOL isCancel))failure {
    [self getWithURLString:urlString params:params cachePolicy:MGNetworkingCahchePolicyNone responseParser:nil success:success failure:failure];
}

/**
 get请求
 
 @param urlString 接口
 @param params 参数
 @param cachePolicy 缓存策略
 @param parser 数据解析器
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
- (void)getWithURLString:(nonnull NSString *)urlString
                  params:(nullable id)params
             cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
       responseParser:(nullable Class<MGResponseParseDelegate>)parser
                 success:(nullable void (^)(id responseObj, bool isCache))success
                 failure:(nullable void (^)(NSError *error, BOOL isCancel))failure {
    [self requestWithURLString:urlString params:params method:MGNetworkingGet cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

#pragma mark - 查询缓存
- (id)cacheInTable:(NSString *)table modelClass:(Class)modelClass {
    NSArray<YTKKeyValueItem *> *cacheArr = [[MGHTTPSessionManager shareInstance].store getAllItemsFromTable:table];
    if (cacheArr.count == 0) {
        return nil;
    }
    NSMutableArray *cacheContentArr = [NSMutableArray arrayWithCapacity:cacheArr.count];
    for (YTKKeyValueItem *item in cacheArr) {
            id subItems = [item.itemObject mj_JSONObject];
            if ([subItems isKindOfClass:[NSArray class]]) {
                for (NSString *itemString in subItems) {
                    NSArray *modelArr = [modelClass?:[NSArray class] mj_objectArrayWithKeyValuesArray:[itemString mj_JSONObject]];
                    if (modelArr) {
                        [cacheContentArr addObjectsFromArray:modelArr];
                    } else {
#if DEBUG
                        NSLog(@"%@ 与缓存数据不匹配", NSStringFromClass(modelClass));
#endif
                    }
                }
            } else {
                
                id model = [modelClass?:[NSArray class] mj_objectArrayWithKeyValuesArray:[item.itemObject mj_JSONObject]];
                if (model) {
                    [cacheContentArr addObjectsFromArray:model];
                } else {
#if DEBUG
                    NSLog(@"%@ 与缓存数据不匹配", NSStringFromClass(modelClass));
#endif
                }
            }
    }
    return cacheContentArr;
}

#pragma mark - 缓存数据
+ (void)cacheContent:(id)content cacheId:(NSString *)cacheId inTable:(NSString *)table {
    [[MGHTTPSessionManager shareInstance].store putString:[content mj_JSONString] withId:cacheId intoTable:table];
}

@end
