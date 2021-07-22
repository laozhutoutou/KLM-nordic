//
//  NSData+CRC16.h
//  KLM
//
//  Created by 朱雨 on 2021/4/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (CRC16)


///Nsdata  CRC 校验 ，返回data
- (NSData*)crc16 ;

@end

NS_ASSUME_NONNULL_END
