//
//  MGNetworking.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGHTTPSessionManager.h"
#import "MGNetworkingTool.h"
#import <AFNetworking/AFNetworking.h>
#import <YTKKeyValueStore/YTKKeyValueStore.h>
#import <MJExtension/MJExtension.h>


/// 静态实例
static MGHTTPSessionManager *networking;
/// 静态任务字典
static NSMutableDictionary<NSString *, NSURLSessionTask *> *taskDictionary;

typedef NS_ENUM(NSUInteger, MGNetworkingMethod) {
    MGNetworkingPost,
    MGNetworkingGet
};

@interface MGHTTPSessionManager ()

/**超时时间*/
@property (nonatomic, assign) NSTimeInterval timeout;
/**基本地址*/
@property (nonatomic, copy) NSString *baseURLString;
/**数据接收类型*/
@property (nonatomic, strong) NSSet<NSString *> *contentTypes;
/**缓存管理*/
@property (nonatomic, strong) YTKKeyValueStore *store;

@end

@implementation MGHTTPSessionManager

+ (void)load {
    // 创建单例
    [self shareInstance];
}

#pragma mark - 创建单例
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networking = [[MGHTTPSessionManager alloc] init];
        taskDictionary = [[NSMutableDictionary alloc] init];
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
    
    _timeout = 20;
    
    // 设置缓存信息
    _store = [[YTKKeyValueStore alloc] initDBWithName:kMGNetworkingCacheDBName];
}

+ (AFHTTPSessionManager *)createHttpSessionManager {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:networking.baseURLString?[NSURL URLWithString:networking.baseURLString]:nil];
    manager.requestSerializer.timeoutInterval = networking.timeout;
//    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = networking.contentTypes;
    return manager;
}

+ (void)setTimeout:(NSTimeInterval)timeout {
    networking.timeout = timeout;
}

+ (void)setBaseURLString:(NSString *)baseURLString {
    networking.baseURLString = baseURLString;
}

+ (void)setResponseSerializerAcceptableContentTypes:(NSSet<NSString *> *)contentTypes {
    networking.contentTypes = contentTypes;
}

+ (void)postWithURLString:(NSString *)urlString
                   params:(id)params
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(id<MGResponseParseDelegate>)parser
                  success:(void (^)(id, bool))success
                  failure:(void (^)(NSError *))failure {
    [networking requestWithURLString:urlString params:params method:MGNetworkingPost cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

+ (void)postWithURLString:(NSString *)urlString params:(id)params success:(void (^)(id, bool))success failure:(void (^)(NSError *))failure {
    [self postWithURLString:urlString params:params cachePolicy:MGNetworkingCahchePolicyNone responseParser:nil success:success failure:failure];
}

+ (void)getWithURLString:(NSString *)urlString params:(id)params cachePolicy:(MGNetworkingCahchePolicy)cachePolicy responseParser:(id<MGResponseParseDelegate>)parser success:(void (^)(id, bool))success failure:(void (^)(NSError *))failure {
    [networking requestWithURLString:urlString params:params method:MGNetworkingGet cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

+ (void)getWithURLString:(NSString *)urlString params:(id)params success:(void (^)(id, bool))success failure:(void (^)(NSError *))failure {
    [self getWithURLString:urlString params:params cachePolicy:MGNetworkingCahchePolicyNone responseParser:nil success:success failure:failure];
}

#pragma mark - 核心请求方法
- (void)requestWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
                      method:(MGNetworkingMethod)method
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(nullable id<MGResponseParseDelegate>)parser
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error))failure {
    // 创建缓存表
    NSString *cacheTableName = [NSString stringWithFormat:@"T_%@", [MGNetworkingTool md5WithString:urlString]];
    NSString *cacheId = [MGNetworkingTool md5WithString:[params mj_JSONString]];
    if (cachePolicy != MGNetworkingCahchePolicyNone && urlString) {
        [networking.store createTableWithName:cacheTableName];
    }
    
    // 查询缓存并返回
    id cache = [networking cacheInTable:cacheTableName modelClass:parser.modelClass];
    if (cache) {
        if (success) {
            success(cache, YES);
        }
    }
    
    void (^requestSuccessBlock)(NSURLSessionTask *, id) = ^(NSURLSessionTask * _Nonnull task, id _Nullable responseObject){
        
        NSError *error = nil;
        if ([parser respondsToSelector:@selector(validate:)]) {
            error = [parser validate:responseObject];
        }
        if (error) { // 后台返回错误信息
            if (failure) {
                failure(error);
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
                success(result?:responseObject, NO);
            }
            
            // 缓存工作
            BOOL needCache = NO;
            switch (cachePolicy) {
                case MGNetworkingCahchePolicyRefresh:
                    // 刷新缓存，删除旧缓存数据
                    [networking.store clearTable:cacheTableName];
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
        [taskDictionary  removeObjectForKey:cacheTableName];
    };
    
    void (^failureBlock)(NSURLSessionTask *, NSError *) = ^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        if (failure) {
            failure(error);
        }
        [taskDictionary  removeObjectForKey:cacheTableName];
    };
    AFHTTPSessionManager *manager = [MGHTTPSessionManager createHttpSessionManager];
    NSURLSessionTask *task;
    if (method == MGNetworkingPost) {
        task = [manager POST:urlString parameters:params progress:nil success:requestSuccessBlock failure:failureBlock];
    } else {
        task = [manager GET:urlString parameters:params progress:nil success:requestSuccessBlock failure:failureBlock];
    }
    [taskDictionary  setObject:task forKey:cacheTableName];
}

#pragma mark - 取消网络请求
+ (void)cancelByURLString:(NSString *)urlString {
    [[taskDictionary  objectForKey:[MGNetworkingTool md5WithString:urlString]] cancel];
}

+ (void)cancelAll {
    [taskDictionary  enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSURLSessionTask * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

#pragma mark - 实例方法
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

/**
 设置返回数据接收类型
 */
- (void)setResponseSerializerAcceptableContentTypes:(NSSet<NSString *> *)contentTypes {
    _contentTypes = contentTypes;
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
                  failure:(nullable void (^)(NSError *error))failure {
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
        responseParser:(nullable id<MGResponseParseDelegate>)parser
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error))failure {
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
                 failure:(nullable void (^)(NSError *error))failure {
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
       responseParser:(nullable id<MGResponseParseDelegate>)parser
                 success:(nullable void (^)(id responseObj, bool isCache))success
                 failure:(nullable void (^)(NSError *error))failure {
    [self requestWithURLString:urlString params:params method:MGNetworkingGet cachePolicy:cachePolicy responseParser:parser success:success failure:failure];
}

#pragma mark - 查询缓存
- (id)cacheInTable:(NSString *)table modelClass:(Class)modelClass {
    NSArray<YTKKeyValueItem *> *cacheArr = [networking.store getAllItemsFromTable:table];
    if (cacheArr.count == 0) {
        return nil;
    }
    NSMutableArray *cacheContentArr = [NSMutableArray arrayWithCapacity:cacheArr.count];
    for (YTKKeyValueItem *item in cacheArr) {
        if (modelClass) {
            id subItems = [item.itemObject mj_JSONObject];
            if ([subItems isKindOfClass:[NSArray class]]) {
                for (NSString *itemString in subItems) {
                    NSArray *modelArr = [modelClass mj_objectArrayWithKeyValuesArray:[itemString mj_JSONObject]];
                    if (modelArr) {
                        [cacheContentArr addObjectsFromArray:modelArr];
                    } else {
#if DEBUG
                        NSLog(@"%@ 与缓存数据不匹配", NSStringFromClass(modelClass));
#endif
                    }
                }
            } else {
                
                id model = [modelClass mj_objectWithKeyValues:item.itemObject];
                if (model) {
                    [cacheContentArr addObject:model];
                } else {
#if DEBUG
                    NSLog(@"%@ 与缓存数据不匹配", NSStringFromClass(modelClass));
#endif
                }
            }
        } else {
            [cacheContentArr addObject:[item.itemObject mj_JSONObject]];
        }
    }
    return cacheContentArr;
}

#pragma mark - 缓存数据
+ (void)cacheContent:(id)content cacheId:(NSString *)cacheId inTable:(NSString *)table {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [networking.store putString:[content mj_JSONString] withId:cacheId intoTable:table];
    });
}

@end
