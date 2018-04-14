//
//  FileUploadParser.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "FileUploadParser.h"

@implementation FileUploadParser

+ (NSError *)validate:(id)response {
    NSInteger code = [response[@"code"] integerValue];
    if (code == 200) {
        return nil;
    }
    NSError *err = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{NSLocalizedFailureReasonErrorKey : response[@"message"]?:@"上传错误"}];
    return err;
}

+ (id)getContent:(id)response {
    return response[@"path"];
}

@end
