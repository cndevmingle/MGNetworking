//
//  MGFileDownloader.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "MGFileDownloader.h"
#import "MGNetworkingTool.h"
#import "MGNetworkingErrorExplainer.h"
#import <AFNetworking/AFURLSessionManager.h>
#import <MJExtension/MJExtension.h>

@interface MGFileDownloader ()

/**下载会话管理*/
@property (nonatomic, strong, readwrite) AFURLSessionManager *sessionManager;
/**下载任务*/
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDataTask *> *taskDictionary;
/**下载中的文件*/
@property (nonatomic, strong) NSMutableDictionary<NSString *, MGDownloadFile *> *fileDictionary;

@end

@implementation MGFileDownloader

+ (instancetype)shareInstance {
    static MGFileDownloader *downloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[MGFileDownloader alloc] init];
    });
    return downloader;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

#pragma mark - 创建下载文件保存目录，如果不存在才创建
- (void)createDownloaderDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exists = [fileManager fileExistsAtPath:kMGNetwokringDownloadPath isDirectory:&isDir];
    if ((exists && !isDir) || !exists) {
        // 如果不存在这个文件夹就创建
        NSError *error = nil;
        BOOL createResult = [fileManager createDirectoryAtPath:kMGNetwokringDownloadPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!createResult || error) {
            NSLog(@"创建%@目录失败\n%s\nLine:%@\nerror:%@", kMGNetwokringDownloadPath, __FUNCTION__, @(__LINE__), error.localizedDescription);
        }
    }
}

- (void)setup {
    
    _showErrorCode = YES;
    
    // 创建目录
    [self createDownloaderDirectory];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    // 创建会话管理者
    _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    _sessionManager.responseSerializer = serializer;
    
    _taskDictionary = [[NSMutableDictionary alloc] init];
    _fileDictionary = [[NSMutableDictionary alloc] init];
}

- (void)downloadWithURLString:(NSString * _Nonnull)urlString
               downloadPolicy:(MGFileDownloadPolicy)downloadPolicy
               responseParser:(nullable Class<MGResponseParseDelegate>)parser
                     progress:(nullable void(^)(NSProgress * _Nullable, MGDownloadFile * _Nonnull))progress
                      success:(nullable void(^)(MGDownloadFile *, id _Nullable response))success
                      failure:(nullable void(^)(NSError *, BOOL isCancel))failure {
    
    NSString *taskKey = [MGNetworkingTool md5WithString:urlString];
    
    if ([_taskDictionary objectForKey:taskKey]) {
        // 如果这个文件正在下载就不进行任何操作
        if (failure) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedFailureReasonErrorKey : @"此文件正在下载"}];
            failure(error, NO);
        }
        return;
    }
    
    MGDownloadFile *file = [[MGDownloadFile alloc] init];
    file.urlString = urlString;
    if (downloadPolicy == MGFileDownloadPolicyCover) {
        file.downloadLength = 0;
    } else {
        file.downloadLength = [MGNetworkingTool fileLengthForPath:[self filePathWithURLString:urlString]];
    }
    file.savePath = [self filePathWithURLString:urlString];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 创建request请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // 设置HTTP请求头中的Range
    NSString *range = [NSString stringWithFormat:@"bytes=%llu-", file.downloadLength];
    [request setValue:range forHTTPHeaderField:@"Range"];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress, file);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (![weakSelf.fileDictionary.allValues containsObject:file]) {
            // 如果下载中的文件中不包含这个文件，说明这个任务已经被停掉了，这个时候返回的东西不需要处理
            return;
        }
        if ((downloadPolicy == MGFileDownloadPolicyUseOlderFile || downloadPolicy == MGFileDownloadPolicyResume) && file.totalLenth == file.downloadLength && error.code == NSURLErrorCancelled) {
            // 用户选择了使用本地文件的策略，并且文件已经下载完整，这时自动调用任务取消，直接回调成功，这里是没有打开文件句柄的
            if (success) {
                success(file, nil);
            }
        } else {
            if (error) {
#if DEBUG
                NSLog(@"%@",error);
#endif
                if (failure) {
                    NSError *explainErr = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@%@%@", [MGNetworkingErrorExplainer errorMessageInChineseWithError:error], weakSelf.showErrorCode?@" Code:":@"", weakSelf.showErrorCode?@(error.code):@""]}];
                    failure(explainErr, error.code == NSURLErrorCancelled);
                }
            } else {
                NSError *diyError = nil;
                if ([parser respondsToSelector:@selector(validate:)]) {
                    diyError = [parser validate:responseObject];
                }
                if (diyError) {
                    if (failure) {
                        NSError *explainErr = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@%@%@", [MGNetworkingErrorExplainer errorMessageInChineseWithError:error], weakSelf.showErrorCode?@" Code:":@"", weakSelf.showErrorCode?@(error.code):@""]}];
                        failure(explainErr, error.code == NSURLErrorCancelled);
                    }
                } else {
                    if (success) {
                        id content = nil;
                        if ([parser respondsToSelector:@selector(getContent:)]) {
                            content = [parser getContent:responseObject];
                        } else {
                            content = responseObject;
                        }
                        id result = nil;
                        if ([parser respondsToSelector:@selector(modelClass)]) {
                            if ([content isKindOfClass:[NSArray class]]) {
                                result = [[parser modelClass] mj_objectArrayWithKeyValuesArray:content];
                            } else if ([content isKindOfClass:[NSDictionary class]]) {
                                result = [[parser modelClass] mj_objectWithKeyValues:content];
                            } else {
                                result = content;
                            }
                        } else {
                            result = content;
                        }
                        success(file, result);
                    }
                }
            }
            [file.fileHandle closeFile];
        }
        [weakSelf.taskDictionary removeObjectForKey:taskKey];
        [weakSelf.fileDictionary removeObjectForKey:taskKey];
    }];
    
    [_taskDictionary setObject:task forKey:taskKey];
    [_fileDictionary setObject:file forKey:taskKey];
    
    [self.sessionManager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        
        // 获得下载文件的总长度：请求下载的文件长度 + 当前已经下载的文件长度
        file.totalLenth = response.expectedContentLength + file.downloadLength;
#if DEBUG
        NSLog(@"File downloaded to: %@", file.savePath);
#endif
        if (file.totalLenth == file.downloadLength && (downloadPolicy == MGFileDownloadPolicyUseOlderFile || downloadPolicy == MGFileDownloadPolicyResume)) {
            [task cancel];
        } else {
            // 创建一个空的文件到沙盒中
            NSFileManager *manager = [NSFileManager defaultManager];
            
            if (![manager fileExistsAtPath:file.savePath] || downloadPolicy == MGFileDownloadPolicyCover) {
                // 如果没有下载文件或者下载策略是覆盖的话，就创建一个文件
                [manager createFileAtPath:file.savePath contents:nil attributes:nil];
            }
        }
        // 允许处理服务器的响应，才会继续接收服务器返回的数据
        return NSURLSessionResponseAllow;
    }];
    
    [self.sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        // 指定数据的写入位置 -- 文件内容的最后面
        [file.fileHandle seekToEndOfFile];
        
        // 向沙盒写入数据
        [file.fileHandle writeData:data];
        
        // 拼接文件总长度
        file.downloadLength += data.length;
    }];
    
    [task resume];
}

- (void)cancelByURLString:(NSString *)urlString deleteFileData:(BOOL)deleteData {
    if (urlString) {
        NSString *taskKey = [MGNetworkingTool md5WithString:urlString];
        [[_taskDictionary objectForKey:taskKey] suspend];
        [_taskDictionary removeObjectForKey:taskKey];
        [_fileDictionary removeObjectForKey:taskKey];
        if (deleteData) {
            [MGNetworkingTool deleteFileAtPath:[self filePathWithURLString:urlString]];
        }
    }
}

#pragma mark - 根据url生成一个文件保存路径
- (NSString *)filePathWithURLString:(NSString *)urlString {
    // 文件名后缀
    NSString *extension = urlString.pathExtension?:@"";
    // 文件名
    NSString *fileName = [[MGNetworkingTool md5WithString:urlString] stringByAppendingPathExtension:extension];
    // 文件路径
    NSString *filePath = [kMGNetwokringDownloadPath stringByAppendingPathComponent:fileName];
    return filePath;
}

@end
