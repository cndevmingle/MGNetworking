//
//  ViewController.m
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import "ViewController.h"
#import "MGHTTPSessionManager.h"
#import <MJExtension/MJExtension.h>
#import "CityModel.h"
#import "CityParser.h"
#import "MGFileUploader.h"
#import "File.h"
#import "FileUploadParser.h"
#import "MGFileDownloader.h"
#import "DownloadParser.h"
#import "MGNetworkingTool.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    double sizeMB = [MGNetworkingTool sizeWithPath:kMGNetworkingPath] / 1000.0 / 1000.0;
    _textView.text = [NSString stringWithFormat:@"缓存大小：%.2lfMB\nfilePath:\n%@", sizeMB, [MGNetworkingTool filePathsInPath:kMGNetworkingPath].mj_JSONString];
}

- (IBAction)requestAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    
    if (_type == 1) {
        //    http://192.168.0.231/zx_UMP/IMobieApiHandler.ashx?action=GetOpenCityList
        NSString *api = @"IMobieApiHandler.ashx?action=GetOpenCityList";
        api = [NSString stringWithFormat:@"http://39.108.184.186/zxump/WebApi/%@", api];
        //    [MGHTTPSessionManager setBaseURLString:@"http://39.108.184.186/zxump/WebApi/"];
        [MGHTTPSessionManager showErrorCode:YES];
        [MGHTTPSessionManager needCancelCallback:YES];
        //    sign = "pt2S5p2Z7VnjrNwFIW7V7neo+ZFXauqZ78ApP9n97QEysoAr14n+xLydwl9f3DyI";
        //    sn = YUNXIAOWEI;
        NSDictionary *params;
        params = @{@"sign":@"pt2S5p2Z7VnjrNwFIW7V7neo+ZFXauqZ78ApP9n97QEysoAr14n+xLydwl9f3DyI", @"sn":@"YUNXIAOWEI"};
        [MGHTTPSessionManager postWithURLString:api params:params cachePolicy:MGNetworkingCahchePolicyAppend responseParser:[CityParser new] success:^(id responseObj, bool isCache) {
            NSLog(@"%@ : %@", isCache?@"缓存数据":@"后端数据", [CityModel mj_keyValuesArrayWithObjectArray:responseObj]);
            NSString *text = [NSString stringWithFormat:@"%@\n%@\n\n%@", isCache?@"缓存数据：":@"后端数据：", [CityModel mj_keyValuesArrayWithObjectArray:responseObj], weakSelf.textView.text];
            weakSelf.textView.text = text;
        } failure:^(NSError *error, BOOL isCancel) {
            NSLog(@"error : %@", error.localizedFailureReason);
            NSString *text = [NSString stringWithFormat:@"错误信息：\n%@\n\n%@", error.localizedFailureReason, weakSelf.textView.text];
            weakSelf.textView.text = text;
        }];
        //    [MGHTTPSessionManager cancelByURLString:api];
    } else if (_type == 2) {
        
        MGFileUploader *uploader = [MGFileUploader shareInstance];
        uploader.responseContentType = [NSSet setWithObjects:@"text/html", nil];
        uploader.showErrCode = YES;
        uploader.needCancelCallback = YES;
        [uploader uploadWithURLString:@"http://125.65.108.22:8080/fileUpload/upload3" params:nil files:@[[File new]] flag:@"flag1" responseParser:[FileUploadParser new] progress:^(NSProgress * _Nonnull progress, NSString *flag) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.textView.text = [NSString stringWithFormat:@"progress:%.3lf\n%@", progress.completedUnitCount*1.0/progress.totalUnitCount, weakSelf.textView.text];
            });
        } success:^(id responseObject, NSString *flag) {
            weakSelf.textView.text = [NSString stringWithFormat:@"上传成功：\n%@\n\n%@", responseObject, weakSelf.textView.text];
        } failure:^(NSError *error, bool isCancel, NSString *flag) {
            weakSelf.textView.text = [NSString stringWithFormat:@"%@%@\n\n%@", isCancel?@"取消上传：":@"", error.localizedFailureReason, weakSelf.textView.text];
        }];
        //    [uploader cancelByFlag:@"flag1"];
    } else if (_type == 3) {
        [self beginDownload];
    }
}

- (void)beginDownload {
    __weak typeof(self) weakSelf = self;
    NSString *urlStr = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg";
//    urlStr = @"http://b.hiphotos.baidu.com/image/pic/item/00e93901213fb80ebacae5ae3ad12f2eb93894b4.jpg";
    [[MGFileDownloader shareInstance] downloadWithURLString:urlStr downloadPolicy:MGFileDownloadPolicyResume responseParser:[DownloadParser new] progress:^(NSProgress * _Nullable progress, MGDownloadFile * _Nonnull file) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.textView.text = [NSString stringWithFormat:@"progress:%.3lf\n%@", file.downloadLength*1.0/file.totalLenth, weakSelf.textView.text];
        });
    } success:^(MGDownloadFile *file, id  _Nullable response) {
        weakSelf.textView.text = [NSString stringWithFormat:@"fileSavePath:%@\n\n%@",file.savePath, weakSelf.textView.text];
    } failure:^(NSError *error, BOOL isCancel) {
        weakSelf.textView.text = [NSString stringWithFormat:@"%@%@\n\n%@", isCancel?@"取消上传：":@"", error.localizedFailureReason, weakSelf.textView.text];
    }];
}

- (IBAction)clean:(id)sender {
    double sizeMB = [MGNetworkingTool sizeWithPath:kMGNetworkingPath] / 1000.0 / 1000.0;
    NSArray *filePaths = [MGNetworkingTool filePathsInPath:kMGNetworkingPath];
    for (NSString *path in filePaths) {
        [MGNetworkingTool deleteAtPath:path];
    }
    double sizeMBAfter = [MGNetworkingTool sizeWithPath:kMGNetworkingPath] / 1000.0 / 1000.0;
    if (sizeMBAfter < sizeMB) {
        
        _textView.text = [NSString stringWithFormat:@"清理缓存：%.2lfMB", sizeMB - sizeMBAfter];
    } else {
        _textView.text = @"清理失败";
    }
}

- (IBAction)pause:(id)sender {
    NSString *urlStr = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg";
    [[MGFileDownloader shareInstance] cancelByURLString:urlStr deleteFileData:NO];
}

- (IBAction)resume:(id)sender {
    [self beginDownload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"%s------Line:%@", __FUNCTION__, @(__LINE__));
}

@end
