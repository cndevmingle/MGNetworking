//
//  FileUploadParser.h
//  MGNetworking
//
//  Created by Mingle on 2018/4/12.
//  Copyright © 2018年 Mingle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGResponseParseProtocol.h"

@interface FileUploadParser : NSObject<MGResponseParseDelegate>

- (NSError *)validate:(id)response;
- (id)getContent:(id)response;

@end
