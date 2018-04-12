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

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)requestAction:(id)sender {
    //    http://192.168.0.231/zx_UMP/IMobieApiHandler.ashx?action=GetOpenCityList
    [MGHTTPSessionManager setBaseURLString:@"http://39.108.184.186/zxump/WebApi/"];
    //    sign = "pt2S5p2Z7VnjrNwFIW7V7neo+ZFXauqZ78ApP9n97QEysoAr14n+xLydwl9f3DyI";
    //    sn = YUNXIAOWEI;
    NSDictionary *params;
    params = @{@"sign":@"pt2S5p2Z7VnjrNwFIW7V7neo+ZFXauqZ78ApP9n97QEysoAr14n+xLydwl9f3DyI", @"sn":@"YUNXIAOWEI"};
    [MGHTTPSessionManager postWithURLString:@"IMobieApiHandler.ashx?action=GetOpenCityList" params:params cachePolicy:MGNetworkingCahchePolicyAppend responseParser:[CityParser new] success:^(id responseObj, bool isCache) {
        NSLog(@"%@ : %@", isCache?@"缓存数据":@"后端数据", [CityModel mj_keyValuesArrayWithObjectArray:responseObj]);
        NSString *text = [NSString stringWithFormat:@"%@\n%@：\n%@", isCache?@"缓存数据":@"后端数据", [CityModel mj_keyValuesArrayWithObjectArray:responseObj], _textView.text];
        _textView.text = text;
    } failure:^(NSError *error) {
        NSLog(@"error : %@", error.localizedFailureReason);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
