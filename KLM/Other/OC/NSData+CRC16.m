//
//  NSData+CRC16.m
//  KLM
//
//  Created by 朱雨 on 2021/4/30.
//

#import "NSData+CRC16.h"

@implementation NSData (CRC16)

- (NSData*)crc16 {
    const uint8_t *byte = (const uint8_t *)self.bytes;
    uint32_t length = (uint32_t)self.length;
    uint16_t res =  gen_crc16(byte, length);
    NSData *val = [NSData dataWithBytes:&res length:sizeof(res)];
    return val;
}

#define PLOY 0X1021

uint16_t gen_crc16(const uint8_t *data, uint32_t size) {
    uint16_t crc = 0xFFFF;
    uint8_t i;    
    for (; size > 0; size--) {
        crc = crc ^ (*data++ <<8);
        for (i = 0; i < 8; i++) {
            if (crc & 0X8000) {
                crc = (crc << 1) ^ PLOY;
            }else {
                crc <<= 1;
            }
        }
        crc &= 0XFFFF;
    }
    return crc;
}


@end
