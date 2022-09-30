/********************************************************************************************************
 * @file     LibTools.h 
 *
 * @brief    for TLSR chips
 *
 * @author   Telink, 梁家誌
 * @date     2018/10/12
 *
 * @par     Copyright (c) [2021], Telink Semiconductor (Shanghai) Co., Ltd. ("TELINK")
 *
 *          Licensed under the Apache License, Version 2.0 (the "License");
 *          you may not use this file except in compliance with the License.
 *          You may obtain a copy of the License at
 *
 *              http://www.apache.org/licenses/LICENSE-2.0
 *
 *          Unless required by applicable law or agreed to in writing, software
 *          distributed under the License is distributed on an "AS IS" BASIS,
 *          WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *          See the License for the specific language governing permissions and
 *          limitations under the License.
 *******************************************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibTools : NSObject

#pragma mark - CRC相关
unsigned short crc16 (unsigned char *pD, int len);

+ (NSData *)getOTAData:(NSData *)data index:(int)index;
+ (NSData *)getReadFirmwareVersion;
+ (NSData *)getStartOTA;
+ (NSData *)getOTAEndData:(NSData *)data index:(int)index;

@end

NS_ASSUME_NONNULL_END
