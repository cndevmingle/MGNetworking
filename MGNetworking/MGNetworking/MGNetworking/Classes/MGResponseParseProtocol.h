//
//  MGResponseParseProtocol.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

/**
 数据解析协议
 */
@protocol MGResponseParseDelegate <NSObject>

@required
/**
 验证response是否是正确的数据，需要开发者根据接口约定的返回数据重写此方法，否则会一直返回nil
 
 @param response 返回数据
 @return 错误信息，如果为空就说明没有错误，数据是正确的
 */
- (NSError *)validate:(id)response;

/**
 从返回数据中获取内容
 
 @param response 返回数据
 @return 内容
 */
- (id)getContent:(id)response;

@optional

/**
 内容模型的类
 
 @return 模型类
 */
- (Class)modelClass;

@end
