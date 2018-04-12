//
//  File.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "File.h"

@implementation File

- (NSData *)fileData {
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"file" ofType:@"jpg"]];
    return data;
}

- (NSString *)fieldName {
    return @"upload1";
}

- (NSString *)fileSaveName {
    return @"file.jpg";
}

- (NSString *)mimeType {
    return @"image/jpeg";
}

@end
