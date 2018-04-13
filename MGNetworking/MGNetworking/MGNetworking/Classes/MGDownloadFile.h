//
//  MGDownloadFile.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/13.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGDownloadFile : NSObject

/**文件url*/
@property (nonatomic, copy) NSString *urlString;
/**文件总长度*/
@property (nonatomic, assign) unsigned long long totalLenth;
/**文件已下载长度*/
@property (nonatomic, assign) unsigned long long downloadLength;
/**文件保存路径*/
@property (nonatomic, copy) NSString *savePath;
/**文件操作句柄*/
@property (nonatomic, strong, readonly) NSFileHandle *fileHandle;

@end
