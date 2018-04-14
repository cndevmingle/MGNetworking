//
//  CityParser.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "CityParser.h"
#import "CityModel.h"

@implementation CityParser

+ (NSError *)validate:(id)response {
    int code = [response[@"ProResult"] intValue];
    if (code == 0) {
        return nil;
    } else {
        NSError *diyErr = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{NSLocalizedFailureReasonErrorKey : response[@"Msg"]?:@"未知错误"}];
        return diyErr;
    }
}

+ (id)getContent:(id)response {
    return response[@"Msg"];
}

+ (Class)modelClass {
    return [CityModel class];
}

@end
