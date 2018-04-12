//
//  File.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFileUploadProtocol.h"

@interface File : NSObject <MGFileUploadDelegate>

- (NSData *)fileData;
- (NSString *)fieldName;
- (NSString *)fileSaveName;
- (NSString *)mimeType;

@end
