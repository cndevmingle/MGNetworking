//
//  MGNetworking.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGResponseParseProtocol.h"

typedef NS_ENUM(NSUInteger, MGNetworkingCahchePolicy) {
    /// 不缓存
    MGNetworkingCahchePolicyNone,
    /// 刷新缓存
    MGNetworkingCahchePolicyRefresh,
    /// 追加缓存(如果接口参数相同则会替换旧的缓存)
    MGNetworkingCahchePolicyAppend
};


NS_ASSUME_NONNULL_BEGIN

/**
 网络请求，缓存回调都是以NSArray返回数据，即使请求本身返回的是NSDictionary，因为缓存可能存在多条的情况
 */
@interface MGHTTPSessionManager : NSObject

// ***********************************************************************************************
//                                              类方法
// ***********************************************************************************************

/**
 设置baseURL，后面调用接口时就不用再加服务器地址，可以不设置，但是调用接口时必须拼上服务器地址

 @param baseURLString 服务器接口地址
 */
+ (void)setBaseURLString:(nullable NSString *)baseURLString;

/**
 设置超时时间，默认20s

 @param timeout 时间
 */
+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 设置返回数据接收类型
 */
+ (void)setResponseContentTypes:(nullable NSSet<NSString *> *)contentTypes;

/**
 在错误信息后面显示错误码

 @param showErrCode 是否显示
 */
+ (void)showErrorCode:(BOOL)showErrCode;

/**
 网络请求取消后是否需要回调（默认YES）

 @param need 是否需要
 */
+ (void)needCancelCallback:(BOOL)need;

/**
 post请求
 
 @param urlString 接口
 @param params 参数
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
+ (void)postWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

/**
 post请求
 
 @param urlString 接口
 @param params 参数
 @param cachePolicy 缓存策略
 @param parser 数据解析器
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
+ (void)postWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(nullable Class<MGResponseParseDelegate>)parser
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

/**
 get请求
 
 @param urlString 接口
 @param params 参数
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
+ (void)getWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

/**
 get请求
 
 @param urlString 接口
 @param params 参数
 @param cachePolicy 缓存策略
 @param parser 数据解析器
 @param success 成功/缓存 的回调
 @param failure 失败的回调
 */
+ (void)getWithURLString:(nonnull NSString *)urlString
                   params:(nullable id)params
              cachePolicy:(MGNetworkingCahchePolicy)cachePolicy
        responseParser:(nullable Class<MGResponseParseDelegate>)parser
                  success:(nullable void (^)(id responseObj, bool isCache))success
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

/**
 取消指定的网络接口

 @param urlString 接口（请求方法后面的urlString参数）
 */
+ (void)cancelByURLString:(NSString *)urlString;

/**
 取消全部的网络请求
 */
+ (void)cancelAll;

// ***********************************************************************************************
//                                              实例方法
// ***********************************************************************************************

/**
 设置baseURL，后面调用接口时就不用再加服务器地址，可以不设置，但是调用接口时必须拼上服务器地址
 
 @param baseURLString 服务器接口地址
 */
- (void)setBaseURLString:(nullable NSString *)baseURLString;

/**
 设置超时时间，默认20s
 
 @param timeout 时间
 */
- (void)setTimeout:(NSTimeInterval)timeout;

/**
 设置返回数据接收类型
 */
- (void)setResponseContentTypes:(nullable NSSet<NSString *> *)contentTypes;

/**
 在错误信息后面显示错误码
 
 @param showErrCode 是否显示
 */
- (void)showErrorCode:(BOOL)showErrCode;

/**
 网络请求取消后是否需要回调（默认YES）
 
 @param need 是否需要
 */
- (void)needCancelCallback:(BOOL)need;

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
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

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
                  failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

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
                 failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

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
                 failure:(nullable void (^)(NSError *error, BOOL isCancel))failure;

@end
NS_ASSUME_NONNULL_END
