/********************************************************************************************************
 * @file     LibTools.m 
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

#import "LibTools.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation LibTools

extern unsigned short crc16 (unsigned char *pD, int len) {
    static unsigned short poly[2]={0, 0xa001};
    unsigned short crc = 0xffff;
    int i,j;
    for(j=len; j>0; j--) {
        unsigned char ds = *pD++;
        for(i=0; i<8; i++) {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
    }
    return crc;
}

+ (NSData *)getOTAData:(NSData *)data index:(int)index {
    BOOL isEnd = data.length == 0;
    int countIndex = index;
    Byte *tempBytes = (Byte *)[data bytes];
    Byte resultBytes[20];
    
    memset(resultBytes, 0xff, 20);
    memcpy(resultBytes, &countIndex, 2);
    memcpy(resultBytes+2, tempBytes, data.length);
    uint16_t crc = crc16(resultBytes, isEnd ? 2 : 18);
    memcpy(isEnd ? (resultBytes + 2) : (resultBytes+18), &crc, 2);
    NSData *writeData = [NSData dataWithBytes:resultBytes length:isEnd ? 4 : 20];
    return  writeData;
}

+ (NSData *)getReadFirmwareVersion {
    uint8_t buf[2] = {0x00,0xff};
    NSData *writeData = [NSData dataWithBytes:buf length:2];
    NSLog(@"sendReadFirmwareVersion -> length:%lu,%@",(unsigned long)writeData.length,writeData);
    return writeData;
}

+ (NSData *)getStartOTA {
    uint8_t buf[2] = {0x01,0xff};
    NSData *writeData = [NSData dataWithBytes:buf length:2];
    NSLog(@"sendStartOTA -> length:%lu,%@",(unsigned long)writeData.length,writeData);
    return writeData;
}

+ (NSData *)getOTAEndData:(NSData *)data index:(int)index {
    int negationIndex = ~index;
    Byte *tempBytes = (Byte *)[data bytes];
    Byte resultBytes[6];
    
    memset(resultBytes, 0xff, 6);
    memcpy(resultBytes, tempBytes, data.length);
    memcpy(resultBytes+2, &index, 2);
    memcpy(resultBytes+4, &negationIndex, 2);
    NSData *writeData = [NSData dataWithBytes:resultBytes length:6];
    NSLog(@"sendOTAEndData -> %04x ,length:%lu,%@", index,(unsigned long)writeData.length,writeData);
    NSLog(@"\n\n==========GATT OTA:end\n\n");
    return writeData;
}

@end
