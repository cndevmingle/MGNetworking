//
//  MGNetworkingErrorExplainer.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGNetworkingErrorExplainer : NSObject

/**
 错误的中文描述

 @param error 网络错误
 @return 中文信息
 */
+ (NSString *)errorMessageInChineseWithError:(NSError *)error;

@end
