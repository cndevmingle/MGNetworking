//
//  MGNetworkingErrorExplainer.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGNetworkingErrorExplainer.h"

@implementation MGNetworkingErrorExplainer

+ (NSString *)errorMessageInChineseWithError:(NSError *)error {
    NSString *errMsg = nil;
    switch (error.code) {
        case NSURLErrorBadURL:
            errMsg = @"无效的请求地址";
            break;
        case NSURLErrorTimedOut:
            errMsg = @"请求超时";
            break;
        case NSURLErrorUnsupportedURL:
            errMsg = @"不支持的请求地址";
            break;
        case NSURLErrorCannotFindHost:
            errMsg = @"未找到服务器";
            break;
        case NSURLErrorCannotConnectToHost:
            errMsg = @"不能连接到服务器";
            break;
        case NSURLErrorNetworkConnectionLost:
            errMsg = @"网络连接中断";
            break;
        case NSURLErrorCancelled:
            errMsg = @"请求已取消";
            break;
        default:
            errMsg = @"请求失败";
            break;
    }
    return errMsg;
}

@end
