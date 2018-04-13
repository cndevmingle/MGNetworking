//
//  MGDownloadFile.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/13.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGDownloadFile.h"

@interface MGDownloadFile ()

@property (nonatomic, strong, readwrite) NSFileHandle *fileHandle;

@end

@implementation MGDownloadFile

- (NSFileHandle *)fileHandle {
    if (!_fileHandle && _savePath) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_savePath];
    }
    return _fileHandle;
}

#if DEBUG
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
#endif

@end
