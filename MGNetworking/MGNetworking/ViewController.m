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

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)requestAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    
    /*
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
     */
    MGFileUploader *uploader = [MGFileUploader shareInstance];
    uploader.responseContentType = [NSSet setWithObjects:@"text/html", nil];
    uploader.showErrCode = YES;
    uploader.needCancelCallback = YES;
    [uploader uploadWithURLString:@"http://125.65.108.22:8080/fileUpload/upload3" params:nil files:@[[File new]] flag:@"flag1" responseParser:[FileUploadParser new] progress:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
           weakSelf.textView.text = [NSString stringWithFormat:@"progress:%@", @(progress.completedUnitCount*1.0/progress.totalUnitCount)];
        });
    } success:^(id responseObject) {
        weakSelf.textView.text = [NSString stringWithFormat:@"%@", responseObject];
    } failure:^(NSError *error, bool isCancel) {
        weakSelf.textView.text = [NSString stringWithFormat:@"%@%@\n", isCancel?@"取消上传：":@"", error.localizedFailureReason];
    }];
    [uploader cancelByFlag:@"flag1"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"%s------Line:%@", __FUNCTION__, @(__LINE__));
}

@end
