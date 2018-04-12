//
//  MGFileUploadProtocol.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

@protocol MGFileUploadDelegate <NSObject>

@required

/**
 文件data
 */
- (NSData *)fileData;

/**
 服务器接收的文件字段名称
 */
- (NSString *)fieldName;

/**
 服务器保存的文件名称
 */
- (NSString *)fileSaveName;

/**
 文件的mimeType
 */
- (NSString *)mimeType;

@end
