//
//  CityModel.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CityModel : NSObject
//{"CityName":"德阳市","CityCode":"510600"}
/**城市名*/
@property (nonatomic, copy) NSString *CityName;
/**城市编号*/
@property (nonatomic, copy) NSString *CityCode;
@end
