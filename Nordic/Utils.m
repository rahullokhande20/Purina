//
//  Utils.m
//
//  Created by NXP on 8/5/14.
//  Copyright (c) 2015 NXP. All rights reserved.
//

#import "sys/utsname.h"
#import "Utils.h"
#import <UIKit/UIKit.h>
//#import "UIColor+Additions.h"
//#import "UIColor+FlatUI.h"

@implementation Utils




/// form comUtils
+ (Utils *)sharedInst
{
    static Utils *_sharedInstance = nil;
    
    if (_sharedInstance == nil) {
        _sharedInstance = [[Utils alloc] init];
    }
    
    return _sharedInstance;
}

-(u_int64_t)getCurenntTime{
    ///     u_int64_t preTimeMs;
    NSDate *  currentTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    return [self getDateTimeTOMilliSeconds : currentTime];
}



/// pickup device number.
-(NSString *)bytesToString : (uint8_t *)_inBytes withLength : (uint8_t)_length{
    NSData *aData = [[NSData alloc] initWithBytes : _inBytes length : _length];
      /// Byte array­> Hex
    Byte *bytes = (Byte *)[aData bytes];
    
    NSString *hexStr = @"";
    
    for(int i=0;i<[aData length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];/// Hex
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    
    return hexStr;
}

-(NSString *)toBinary:(NSUInteger)input
{
     NSMutableString *string = [NSMutableString string];
       while (input)
      {
       [string insertString:(input & 1)? @"1": @"0" atIndex:0];
       input /= 2;
      }
      return string;
}

-(NSData*)startECGPPGGraph{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x01;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"start PPG graph data packet %@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)channelSwitchOffCommand:(int)channel{
    
    uint16_t byte1 = 0x06;
    uint16_t byte2 = 0xB3;
    uint16_t byte3 = 0x0A;
    uint16_t byte4 = 0x02;
    uint16_t byte5 = 0x04;
    uint16_t byte6 = channel;
    uint16_t byte7 = 0x00;
    uint16_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6+byte7;
    
    
    NSLog(@"sumbyte %04x",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum&0xFF;
    
    NSLog(@"checksum21 %02x",hexCheckSum);

    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"B3"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command =  [NSString stringWithFormat:@"%@ %02x",command,channel];
    command =  [NSString stringWithFormat:@"%@ %@",command,@"00"];
    command =  [NSString stringWithFormat:@"%@ %02x",command,hexCheckSum];
   
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"channel packet off : %@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)channelSwitchOnCommand:(int)channel{
    
    uint16_t byte1 = 0x06;
    uint16_t byte2 = 0xB3;
    uint16_t byte3 = 0x0A;
    uint16_t byte4 = 0x02;
    uint16_t byte5 = 0x04;
    uint16_t byte6 = channel;
    uint16_t byte7 = 0x01;
    uint16_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6+byte7;
    
    
    NSLog(@"sumbyte %04x",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum&0xFF;
    
    NSLog(@"checksum21 %02x",hexCheckSum);

    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"B3"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command =  [NSString stringWithFormat:@"%@ %02x",command,channel];
    command =  [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command =  [NSString stringWithFormat:@"%@ %02x",command,hexCheckSum];
   
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"channel packet off : %@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)stopECGPPGGraph{
    
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x05;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"stop PPG graph data packet: %@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)startBioMetricGraphLND{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x01;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"start LND graph data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)startBioMetricGraphDiscOpt{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x01;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"start LND graph data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)startBioMetricGraphDigiOpt{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x01;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"start LND graph data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)stopBioMetricGraphLND{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x05;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)stopBioMetricGraphDigiOpt{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x05;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
 
    return commandToSend;
    
}

-(NSData*)stopBioMetricGraphDiscOpt{
 
    unsigned int byte1=0x02;
    unsigned int byte2=0x02;
    unsigned int byte3=0x05;
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)sendReadGainLND{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x01;
   
   
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}
-(NSData*)sendReadGainDiscOpt{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x01;
   
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}
-(NSData*)sendReadGainDigiOpt{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x01;
   
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}
-(NSData*)sendWriteGainChannel:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0xB3;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x01;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"B3"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    return commandToSend;
    
}
- (NSData *)sendreadGain
{
    
    unsigned int byte1=0x04;
    unsigned int byte2=0xB3;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x01;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"B3"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send read gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
  
    return commandToSend;
    
}

- (NSData *)sendreadGainChannel
{
    
    unsigned int byte1=0x04;
    unsigned int byte2=0xB3;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x01;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"B3"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send read gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
  
    return commandToSend;
    
}


-(NSDictionary*)sendWriteGainLND:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0x02;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x01;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    
    return @{@"Data":commandToSend,@"Packet":hexVal};
    
}

-(NSDictionary*)sendWriteGainDiscOpt:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0x02;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x01;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    return @{@"Data":commandToSend,@"Packet":hexVal};
    
}


-(NSDictionary*)sendWriteGainDigiOpt:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0x02;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x01;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    return @{@"Data":commandToSend,@"Packet":hexVal};
    
}



-(NSData*)sendReadCurrentLND{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x02;
   
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}

-(NSData*)sendReadCurrentDiscOpt{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x02;
   
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}


-(NSData*)sendReadCurrentDigiOpt{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x0A;
    unsigned int byte4=0x01;
    unsigned int byte5=0x02;
   
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}


-(NSDictionary*)sendWriteCurrentLND:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0x02;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x02;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    return @{@"Data":commandToSend,@"Packet":hexVal};
    
}
-(NSDictionary*)sendWriteCurrentDigiOpt:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0x02;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x02;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    return @{@"Data":commandToSend,@"Packet":hexVal};
    
}
-(NSDictionary*)sendWriteCurrentDiscOpt:(int)value{
    
    unsigned int byte1=0x05;
    unsigned int byte2=0x02;
    unsigned int byte3=0x0A;
    unsigned int byte4=0x02;
    unsigned int byte5=0x02;
    unsigned int byte6=value;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    NSString *hexVal = [NSString stringWithFormat:@"%02X",value];
    return @{@"Data":commandToSend,@"Packet":hexVal};
    
}


-(NSData*)hardwareStatus{
    
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x01; // operation packet

    uint8_t sumByte = byte1+byte2+byte3;
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
  
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"device info st hardware status packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    return commandToSend;
    
}
-(NSData*)firmwareStatus{
    
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x02; // operation packet

    uint8_t sumByte = byte1+byte2+byte3;
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
  
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"device info st firmware status packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    return commandToSend;
    
}
-(NSData*)systemStatus{
    
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x03; // operation packet

    uint8_t sumByte = byte1+byte2+byte3;
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
  
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"device info st system status packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    return commandToSend;
    
}

-(NSData*)systemSerial{
    
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x04; // operation packet

    uint8_t sumByte = byte1+byte2+byte3;
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
  
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"device info st system serial packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    return commandToSend;
    
}


-(NSData*)startBioMetricGraph{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x01; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}



-(NSData*)fourSecondsPPG{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x06; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"four seconds data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)stopBioMetricGraph{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x05; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)startBpmGraph{
    
    unsigned int byte1=0x02; //
    unsigned int byte2=0x03; // Packet type
    unsigned int byte3=0x03; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)stopBpmGraph{
    
    unsigned int byte1=0x02; //
    unsigned int byte2=0x03; // Packet type
    unsigned int byte3=0x05; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)startCount{
    
    unsigned int byte1=0x02; //
    unsigned int byte2=0x0B; //
    unsigned int byte3=0x01; //
  

    uint8_t sumByte = byte1+byte2+byte3;
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"0B"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)stopCount{
    
    unsigned int byte1=0x02; //
    unsigned int byte2=0x0B; //
    unsigned int byte3=0x01; //
  

    uint8_t sumByte = byte1+byte2+byte3;
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"0B"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)startHRV{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x03; // operation packet
  
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)stopHRV{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x05; // operation packet
  
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)startHRM{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x04; // operation packet
  
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)stopHRM{
 
    unsigned int byte1=0x02; //
    unsigned int byte2=0x03; // Packet type
    unsigned int byte3=0x05; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

//Left PCB Bootload code

-(NSData*)intiateBootload{
 
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x07; // Packet type
    unsigned int byte3=0x10; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"10"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)completeBootload{
 
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x07; // Packet type
    unsigned int byte3=0x11; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"11"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

-(NSData*)intiateBootloadCodec{
 
    unsigned int byte1=0x03; // length
    unsigned int byte2=0x06;
    unsigned int byte3=0x07;
    unsigned int byte4=0x01;

    uint8_t sumByte = byte1+byte2+byte3+byte4;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   //
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   //
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];   //
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   //
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; //
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)loadCodecBootload:(NSString*)hexString hexArr:(NSArray*)hexArray packetIndex:(int)packetIndex  profileIndex:(int)profileIndex{
    
    
    
    uint16_t byte1 = 0x25;
    
    uint16_t byte2 = 0x06;
    
    uint16_t byte3 = 0x01;
  
    uint16_t byte4 = (uint16_t)profileIndex;
    
    uint16_t byte5 = (uint16_t)packetIndex;

    uint16_t byte6 = 0x20;
    
    uint16_t byte7 = 0;
    
    for (int i=0; i<hexArray.count; i++) {
        
        unsigned int outVal ;
         NSScanner* scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"0x%@",hexArray[i]]];
         [scanner scanHexInt:&outVal];
        
       // NSLog(@"byteval %02x",(uint16_t)outVal);
        byte7=byte7+(uint16_t)outVal;
        

    }
    
    uint16_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6+byte7;
    
    
    NSLog(@"sumbyte %04x",sumByte);
    //unsigned int byte255 = sumByte & 0xF

    uint8_t hexCheckSum = ~sumByte+1;
  //  hexCheckSum = hexCheckSum+1;
    hexCheckSum = hexCheckSum&0xFF;
   // NSLog(@"checksum %04x",hexCheckSum);
 

    

    //uint16_t serial = (uint16_t)packetIndex;
    
    NSLog(@"checksum21 %02x",hexCheckSum);
    
   /* NSString *byteCommad;
   
    
     byteCommad = [NSString stringWithFormat:@"%04x", serial];
    byteCommad = [byteCommad stringByReplacingOccurrencesOfString:@" " withString:@"0"];
    */
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"25"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command =  [NSString stringWithFormat:@"%@ %02x",command,profileIndex];
    command =  [NSString stringWithFormat:@"%@ %02x",command,packetIndex];
    command =  [NSString stringWithFormat:@"%@ %@",command,@"20"];
    command =  [NSString stringWithFormat:@"%@ %@",command,hexString];
    
    
  
   // command = [NSString stringWithFormat:@"%@ %s",command,"080808080808080808080808080808080808080808080808080808"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
  //  NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}



-(NSData*)completeBootloadCodec{
 
    unsigned int byte1=0x03; // length
    unsigned int byte2=0x06; //
    unsigned int byte3=0x07; //
    unsigned int byte4=0x00; //

    uint8_t sumByte = byte1+byte2+byte3+byte4;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];   // operation Packet
        command = [NSString stringWithFormat:@"%@ %@",command,@"00"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)loadBootload:(NSArray*)hexArray withstring255:(NSString*)string255 packetCountHexTotal:(int)value  packetCount:(int)pacetSerial{
    
    uint16_t length =   (string255.length/2)+3;
    
    uint16_t byte1 = length;
    uint16_t byte2 = 0x08;
    uint16_t byte3 = (uint16_t)value;
    uint16_t byte4 = 0;
    
    for (int i=0; i<hexArray.count; i++) {
        
        unsigned int outVal ;
         NSScanner* scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"0x%@",hexArray[i]]];
         [scanner scanHexInt:&outVal];
        byte4=byte4+(uint16_t)outVal;
        
    }
    
    uint16_t sumByte = byte1+byte2+byte3+byte4;
    
    
    NSLog(@"sumbyte %04x",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum&0xFF;


    uint16_t serial = (uint16_t)pacetSerial;
    
    NSLog(@"checksum21 %02x",hexCheckSum);
    
    NSString *byteCommad;
 
    
     byteCommad = [NSString stringWithFormat:@"%04x", serial];
    byteCommad = [byteCommad stringByReplacingOccurrencesOfString:@" " withString:@"0"];
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %02x",command,length];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"08"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,byteCommad];   // operation Packet
    command =  [NSString stringWithFormat:@"%@ %@",command,string255];
    
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"PPPacket %@",command);
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)intiateBootloadRight{
 
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x03; // Packet type
    unsigned int byte3=0x01; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"intiate bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)deviceStatus{
    
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x0A; // Packet type
    unsigned int byte3=0x01; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
  

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"0A"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload status packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}
-(NSData*)completeBootloadRight{
 
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x03; // Packet type
    unsigned int byte3=0x02; // operation packet
  

    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"bootload data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)loadBootloadRight:(NSArray*)hexArray withstring255:(NSString*)string255 packetCountHexTotal:(int)value  packetCount:(int)pacetSerial{
    
    uint16_t length =   (string255.length/2)+3;
    
    uint16_t byte1 = length;
    uint16_t byte2 = 0x04;
    uint16_t byte3 = (uint16_t)value;
    uint16_t byte4 = 0;
    
    for (int i=0; i<hexArray.count; i++) {
        
        unsigned int outVal ;
        NSScanner* scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"0x%@",hexArray[i]]];
        [scanner scanHexInt:&outVal];
        byte4=byte4+(uint16_t)outVal;

     }
    
    uint16_t sumByte = byte1+byte2+byte3+byte4;
    
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum&0xFF;

    uint16_t serial = (uint16_t)pacetSerial;
    
    NSString *byteCommad;

    
    byteCommad = [NSString stringWithFormat:@"%04x", serial];
    byteCommad = [byteCommad stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %0x",command,length];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,byteCommad];   // operation Packet
    command =  [NSString stringWithFormat:@"%@ %@",command,string255];
    
   // command = [NSString stringWithFormat:@"%@ %s",command,"080808080808080808080808080808080808080808080808080808"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"hex arr packet%@", command);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}

//Enable Laser

-(NSData *)enableLaser{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x01; // operation packet
    unsigned int byte4=0x01; // enable laser
    unsigned int byte5=0x02; // control laser parameter
    
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // enable laser
   command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // control laser
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"write data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData *)enableLaserCodec{
 
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x01; // operation packet
    unsigned int byte4=0x01; // enable laser codec
    unsigned int byte5=0x01; // control laser parameter
     

    
     uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);

  
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // enable laser
   command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // control laser
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"write data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)disableLaser{
    
    unsigned int byte1=0x04; // length
    unsigned int byte2=0x01; // Packet type
    unsigned int byte3=0x01; // operation packet
    unsigned int byte4=0x00; // disable laser
    unsigned int byte5=0x00; // control laser parameter
    
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %@",command,@"00"];   // disable laser
    command = [NSString stringWithFormat:@"%@ %@",command,@"00"];   // control laser
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"write data packet%@", command);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}


-(NSData*)viewProfileCodec{
    
    unsigned int byte1=0x02; // length
    unsigned int byte2=0x06; // Packet type
    unsigned int byte3=0x06; // operation packet

    
    
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"view profile data packet%@", command);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}

-(NSData *)writePacketLED : (NSString *)redString
withBlueString : (NSString*)blueString
       withStrGreenString : (NSString*)greenString withStrIntensityString : (NSString*)intensityString{
    
    unsigned int byte1=0x07; // length
    unsigned int byte2=0x02; // Packet type
    unsigned int byte3=0x01; // operation packet
    unsigned int byte4=0x00; // write packet
    unsigned int byteRed=[redString intValue];
    unsigned int byteGreen=[greenString intValue];
    unsigned int byteBlue=[blueString intValue];
    unsigned int byteIntensity=[intensityString intValue];
    
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byteRed+byteGreen+byteBlue+byteIntensity;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // operation Packet
    command = [NSString stringWithFormat:@"%@ %@",command,@"00"];   // write packet
    command = [NSString stringWithFormat:@"%@ %02X",command,byteRed];   // Red
    command = [NSString stringWithFormat:@"%@ %02X",command,byteGreen];  // Green
    command = [NSString stringWithFormat:@"%@ %02X",command,byteBlue];  // Blue
    command = [NSString stringWithFormat:@"%@ %02X",command,byteIntensity]; // Intensity
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"write data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}

-(NSData *)sendProfileCodec:(int)profileSelected{
    
    unsigned int byte1=0x03; // length
    unsigned int byte2=0x06; // Packet type
    unsigned int byte3=0x04;
    unsigned int byteProfile=profileSelected;
    
    uint8_t sumByte = byte1+byte2+byte3+byteProfile;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
     
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // volume booster
    command = [NSString stringWithFormat:@"%@ %02X",command,profileSelected];   // profile selcted
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"profile codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}

-(NSData*)sendVolumeCodec:(int)volumeSelected{
    
    unsigned int byte1=0x03; // length
    unsigned int byte2=0x06; // Packet type
    unsigned int byte3=0x05;
    unsigned int byteProfile=volumeSelected;
    
    uint8_t sumByte = byte1+byte2+byte3+byteProfile;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"06"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];   // volume booster
    command = [NSString stringWithFormat:@"%@ %02X",command,volumeSelected];   // profile selcted
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}

-(NSData*)sendReadGain{
    
    unsigned int byte1=0x03; // length
    unsigned int byte2=0x07; // Packet type
    unsigned int byte3=0x01;
    unsigned int byte4=0x02;
   
    
    uint8_t sumByte = byte1+byte2+byte3+byte4;
    
    NSLog(@"sumByte %02X",sumByte);
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
            
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" volume codec data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}
-(NSData*)sendWriteGain:(int)value1 value2:(int)value2{
    
    unsigned int byte1=0x05; // length
    unsigned int byte2=0x07; // Packet type
    unsigned int byte3=0x02;
    unsigned int byte4=0x02;
    unsigned int byte5=value1;
    unsigned int byte6=value2;
    
    uint8_t sumByte = byte1+byte2+byte3+byte4+byte5+byte6;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
        
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"07"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];
    command = [NSString stringWithFormat:@"%@ %02X",command,value1];
    command = [NSString stringWithFormat:@"%@ %02X",command,value2];
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum];
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@" send write gain packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}
-(NSData *)systemReset{
 
//    unsigned int byte1=0x02; // length
//    unsigned int byte2=0x04; // Packet type
//    unsigned int byte3=0x0A; // operation packet
//    unsigned int byte4=0xF0; // enable laser
   // unsigned int byte5=0x01; // control laser parameter
     

    
 //  uint8_t sumByte = byte1+byte2+byte3+byte4+byte5;
//
//    NSLog(@"sumByte %02X",sumByte);
//    //unsigned int byte255 = sumByte & 0xF
//    uint8_t hexCheckSum = ~sumByte+1;
//    hexCheckSum = hexCheckSum & 0xFF;
//    NSLog(@"sumByte %02X",hexCheckSum);

  
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"05"];   // packet Type
    command = [NSString stringWithFormat:@"%@ %@",command,@"FA"];   // enable laser
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"system reset data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    
    return commandToSend;
    
}


-(NSData*)readBatteryPercentage{
    

    unsigned int byte1=0x02;
    unsigned int byte2=0x04;
    unsigned int byte3=0x09;

    
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = 0;
    hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    

    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,[NSString stringWithFormat:@"%02X",byte1]];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"]; //Bluetooth
    command = [NSString stringWithFormat:@"%@ %@",command,@"09"]; // read name
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"read ble data packet%@", commandToSend);

    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    return commandToSend;
   
}


-(NSData*)readConnectedBLEName{
    

    unsigned int byte1=0x02;
    unsigned int byte2=0x04;
    unsigned int byte3=0x08;

    
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = 0;
    hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    

    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,[NSString stringWithFormat:@"%02X",byte1]];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"]; //Bluetooth
    command = [NSString stringWithFormat:@"%@ %@",command,@"08"]; // read name
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"read ble data packet%@", commandToSend);

    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];

    return commandToSend;
   
}
-(NSData*)readBLEName{
    

    unsigned int byte1=0x02;
    unsigned int byte2=0x04;
    unsigned int byte3=0x01;

    
    uint8_t sumByte = byte1+byte2+byte3;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = 0;
    hexCheckSum = ~sumByte+1;
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    

    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,[NSString stringWithFormat:@"%02X",byte1]];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"]; //Bluetooth
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"]; // read name
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"read ble data packet%@", commandToSend);

    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
   
}
-(NSData * )changeBluetoothAddress : (NSArray*) asciiArray{
    
    
    int nameLength = asciiArray.count;
    unsigned int byte1=nameLength+2;
    unsigned int byte2=0x04;
    unsigned int byte3=0x03;
    
    unsigned int byteName=0;
    
    for (int i=0;i<asciiArray.count;i++){
        
        unsigned int value = (int)[asciiArray[i] intValue];
        NSLog(@"hex 0x%02x",(unsigned int)value);
        uint8_t hexVal = (unsigned int)value;
        NSLog(@"hex1 0x%02x",hexVal);
        byteName = byteName+hexVal;
        
    }
    
    uint8_t sumByte = byte1+byte2+byte3+byteName;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = 0;
    if (nameLength>7){
        hexCheckSum = ~sumByte-1;
    }else{
        hexCheckSum = ~sumByte;
    }
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
   
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,[NSString stringWithFormat:@"%02X",byte1]];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"]; //Bluetooth
    command = [NSString stringWithFormat:@"%@ %@",command,@"03"]; // address change
    for (int i=0;i<asciiArray.count;i++){
          
          unsigned int value = (int)[asciiArray[i] intValue];

          uint8_t hexVal = (unsigned int)value;

        command = [NSString stringWithFormat:@"%@ %02X",command,hexVal];
          
      }
     
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"write data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
     
    return [NSData new];
}


-(NSData *)changeBluetoothName : (NSArray *)asciiArray{
    
    
    int nameLength = asciiArray.count;
    unsigned int byte1=nameLength+2;
    unsigned int byte2=0x04;
    unsigned int byte3=0x02;
     
    
    unsigned int byteName=0;
    
    for (int i=0;i<asciiArray.count;i++){
        
        unsigned int value = (int)[asciiArray[i] intValue];
        NSLog(@"hex 0x%02x",(unsigned int)value);
        uint8_t hexVal = (unsigned int)value;
        NSLog(@"hex1 0x%02x",hexVal);
        byteName = byteName+hexVal;
        
    }
    
    uint8_t sumByte = byte1+byte2+byte3+byteName;
    
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexCheckSum = 0;
    if (nameLength>7){
        hexCheckSum = ~sumByte-1;
    }else{
        hexCheckSum = ~sumByte;
    }
    hexCheckSum = hexCheckSum & 0xFF;
    NSLog(@"sumByte %02X",hexCheckSum);
    
    
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,[NSString stringWithFormat:@"%02X",byte1]];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];  //Bluetooth
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];  // Name
    for (int i=0;i<asciiArray.count;i++){
          
          unsigned int value = (int)[asciiArray[i] intValue];

          uint8_t hexVal = (unsigned int)value;

        command = [NSString stringWithFormat:@"%@ %02X",command,hexVal];
          
      }
     
    command = [NSString stringWithFormat:@"%@ %02X",command,hexCheckSum]; // CHecksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"write data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
     
    return [NSData new];
}



-(NSData *)hexStrToBytes : (NSString *)hexString
              withStrFreq : (NSString*)freqString
              withStrAmp : (NSString*)amplitudeString
{

    unsigned int byte1=0x04;
    unsigned int byte2=0x01;
    unsigned int byte3=0x02;
    unsigned int byteFreq=[freqString intValue];
    unsigned int byteAmp=[amplitudeString intValue];
    
    
    
    uint8_t sumByte = byte1+byte2+byte3+byteFreq+byteAmp;
    NSLog(@"sumByte %02X",sumByte);
    //unsigned int byte255 = sumByte & 0xF
    uint8_t hexbyte = ~sumByte+1;
    hexbyte = hexbyte & 0xFF;
    
    NSLog(@"hexbyte %02X",hexbyte);
    NSString *binaryInput = [NSString stringWithFormat:@"0x%X",sumByte];
    
    
    int hexAsInt;
    [[NSScanner scannerWithString:binaryInput] scanHexInt:&hexAsInt];
    NSString *binary = [NSString stringWithFormat:@"%@", [self toBinary:hexAsInt]];
    NSLog(@"Binary value%@",binary);

    NSMutableArray *binaryArray = [NSMutableArray new];
    for (NSUInteger i = 0; i < [binary length]; i++) {
        unichar c = [binary characterAtIndex:i];
        [binaryArray addObject:[NSString stringWithCharacters:&c length:1]];
    }
    
    
    
    int length = binaryArray.count;
    int n, a[length], i;
    bool flag = false;
    //printf("Enter number of binary numbers: ");
    n=length;
    //printf("Enter %d binary numbers:", n);
    
    for (int i=0; i<binaryArray.count; i++) {
        int value = [binaryArray[i] intValue];
        a[i]=value;
    }
    
    //Scanning from right side i.e from last entered binary number
    for(i=n-1;i>=0;i--)
    {
        if(a[i]==1 && flag==false)
        {
            flag = true;
            continue;
        }
        if(a[i]==0 && flag==false)
        {
            continue;
        }
        if(a[i]==1)
            a[i]=0;
        else
            a[i]=1;
    }
    printf("2's complement is: \n");
    
    NSString *binary2sString = [NSString new];
    
    for(i=0;i<8;i++)
    {
        if (binary2sString == nil){
            binary2sString = [NSString stringWithFormat:@"%d",a[i]];
        }else{
            binary2sString = [NSString stringWithFormat:@"%@%d",binary2sString,a[i]];
        }
        
        printf(" %d",a[i]);
    }
     
    NSLog(@"binary checksum %@",binary2sString);
    
    /* Binary to Hex*/
    NSString *hexChecksum = [NSString stringWithFormat:@"%2lX", (unsigned long)strtol([binary2sString UTF8String], NULL, 2)];
 
    NSLog(@"hex checksum %@",hexChecksum);
    
    NSString *command = [NSString new];
    command = [NSString stringWithFormat:@"%@",@"AB"];              // Header
    command = [NSString stringWithFormat:@"%@ %@",command,@"04"];   // Length
    command = [NSString stringWithFormat:@"%@ %@",command,@"01"];   // Laser
    command = [NSString stringWithFormat:@"%@ %@",command,@"02"];   // sub command
    command = [NSString stringWithFormat:@"%@ %02X",command,byteFreq];   // parameter1
    command = [NSString stringWithFormat:@"%@ %02X",command,byteAmp];   // parameter2
    command = [NSString stringWithFormat:@"%@ %02X",command,hexbyte];   // Checksum
    
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'}; 
    for (int i = 0; i < ([command length] / 2); i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1]; 
    }
    NSLog(@"data packet%@", commandToSend);
    
    NSDictionary* userInfo = @{@"Packet": command};
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"Packet" object:self userInfo:userInfo];
    
    return commandToSend;
    
}
  /*  let header = "0xAB"
    let length = "0x04"
    let laser = strEdited
    let subCommand = "0x02"
    let parameter1 = 10
    let parameter2 = 20
    let checkSUm = ""
    */
    
    
    /*
    NSMutableArray *dataArray = [NSMutableArray new];
    [dataArray addObject:@"0xAB"]; // header
    [dataArray addObject:@"0x04"]; // length
    [dataArray addObject:@"0x01"]; // Laser
    [dataArray addObject:@"0x01"]; // sub parameter
    [dataArray addObject:@"0x0e"];
    [dataArray addObject:@"0x7d"];
    [dataArray addObject:[NSString stringWithFormat:@"0x%@",hexChecksum]]; // checksum
    

    
    
    NSString *strSub = NULL;
    NSString *strRef = @"1234567890ABCDEF";
    
    NSRange strRange;
    
    for(int i = 0; i <strEditedUpper.length; i++)
    {
        unichar cStr = [strEditedUpper characterAtIndex : i];
        
        /// NSLog(@"cStr : %c", cStr);
        strSub = [NSString stringWithFormat:@"%c", cStr ];
        
        strRange = [strRef rangeOfString:strSub];
        
        if(strRange.length <= 0)
        {
            // NSLog(@"illegal str!");
            strValid = true;
            break;
        }
    }
    
    if(strValid)
        return NULL;
    
    /// strEdited = null
    if(strEditedUpper.length < strMin){
        return NULL;
    }
    
    /// odd string
    if(strEditedUpper.length % 2)
    {
        [strEditedUpper insertString:@"0" atIndex:0];
        /// NSLog(@"strEditedUpper:%@", strEditedUpper);
    }
    
    Byte j=0;
    
    Byte bytes[100];
    
    for(int i=0;i<[strEditedUpper length];i++)
    {
        Byte int_ch;  ///
        
        char hex_char1 = [strEditedUpper characterAtIndex:i]; //// high nibble
        Byte int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48) << 4;   //// 0 's Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55) << 4; //// A's Ascll - 65
        else
            int_ch1 = (hex_char1-87) << 4; //// a's Ascll - 97
        i++;
        
        
        char hex_char2 = [strEditedUpper characterAtIndex:i]; /// low nibble
        Byte int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48)&0x0f; //// 0 µÄAscll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = (hex_char2-55)&0x0f; //// A µÄAscll - 65
        else
            int_ch2 = (hex_char2-87)&0x0f; //// a µÄAscll - 97
        
        int_ch = int_ch1 | int_ch2 ;
        
        /// NSLog(@"int_ch=%x",int_ch);
        bytes[j] = int_ch;
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:[strEditedUpper length]>>1];
    
    NSData *modifiedData = [NSKeyedArchiver archivedDataWithRootObject:dataArray];
    
    //debug_packet(dataArray)
 
    uint8_t laserPacket[5];
    uint8_t checksumCheck;
    
    generate_control_laserpacket(0x02, (uint16_t)strEditedUpper, &laserPacket[0]);
    checksumCheck = calculate_checksum(&laserPacket[0], &laserPacket[3]);
    
    printf("Packet \n %02x",laserPacket[0]);
    
        if(checksumCheck  == laserPacket[4])
        {
            printf("\n CheckSum: %02x \n", checksumCheck);
            printf("Packet matches \n");
            send_acknowledgement_event(laserPacket[2], 0x00);
        }
        else
        {
            printf("Packet Not matched \n");
        }

        NSData *newData1 = [[NSData alloc] initWithBytes:laserPacket length:sizeof(laserPacket)];
*/
    
  //  return modifiedData;
//}
/*
void generate_control_laserpacket(uint8_t command1, uint16_t command2,char checksum, uint16_t *command)
{
    command[0] = 0xAB; //Header
    command[1] = 0x04; //Pakcet length
    command[2] = 0x01; // Packet type (laser)
    command[3] = 0x01; //sub parameter
    command[4] = 0x0e; // freq
    command[5] = 0x7d; // amp
    command[6] = 0x6f;
    
}
*/
/*
void send_acknowledgement_event(uint8_t eventID, uint8_t status)
{
    uint8_t command[6];
    int i;
    
    command[0] = 0xAb;
    command[1] = 0x03;
    command[2] = 0xA1;
    command[3] = eventID;
    command[4] = status;
    command[5] = calculate_checksum(&command[1], &command[4]);
    
    printf("\n ACK : \n");
    for(i=0; i<5; i++)
    {
        printf("cch %02x   ", command[i]);
    }
    printf("\n %02x",command);
    // BM64STATE.currState = BM64COM_GET_UARTVER;
    
}

*/
/*
static uint8_t calculate_checksum ( uint8_t * startByte , uint8_t * endByte )
{
    uint8_t checkSum = 0;
    while (startByte <= endByte )
    {
        checkSum += *startByte ;
        startByte++ ;
    }
    checkSum = ~checkSum + 1 ;
    return checkSum;
}
*/
-(uint32_t)decStrToDec : (NSString *)decString
            withStrMin : (int)strMin
            withStrMax : (int)strMax
{
    BOOL strValid = false;
    
    /// check length
    if(decString.length >= strMax){
        decString = [decString substringToIndex : strMax];
    }
    
    /// check illegal edit
    NSMutableString *strEditedUpper = [[NSMutableString alloc ]initWithCapacity : strMax];
    /// NSLog(@"hexString : %@", hexString);
    
    [strEditedUpper setString: [decString uppercaseString]];
    
    /// NSLog(@"strEditedUpper : %@", strEditedUpper);
    
    
    NSString *strSub = NULL;
    NSString *strRef = @"1234567890ABCDEF";
    
    NSRange strRange;
    
    for(int i = 0; i < strEditedUpper.length; i++)
    {
        unichar cStr = [strEditedUpper characterAtIndex : i];
        
        /// NSLog(@"cStr : %c", cStr);
        strSub = [NSString stringWithFormat:@"%c", cStr ];
        
        strRange = [strRef rangeOfString:strSub];
        
        if(strRange.length <= 0)
        {
            // NSLog(@"illegal str!");
            strValid = true;
            break;
        }
    }
    
    if(strValid)
        return 0;
    
    /// strEdited = null
    if(strEditedUpper.length < strMin){
        return 0;
    }
    
    /// odd string
    if(strEditedUpper.length % 2)
    {
        [strEditedUpper insertString:@"0" atIndex:0];
        /// NSLog(@"strEditedUpper:%@", strEditedUpper);
    }
    
    uint32_t retData=0;
    
    for(int i=0;i<[strEditedUpper length];i++)
    {
        /// Byte int_ch=0;  ///
        
        char hex_char1 = [strEditedUpper characterAtIndex:i]; //// high nibble
        
        Byte int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48);   //// 0 's Ascll - 48
        else
            return 0; //// a's Ascll - 97
        
        /// NSLog(@"int_ch=%x",int_ch);
        retData = retData*10 + int_ch1;
    }
    
    
    return retData;
}
/*
void debug_packet(uint8_t *dataPacket)
{
    int length;
    int checksumCheck;
    uint8_t packetType=0x00;
    int status=0;
    if(*dataPacket  == 0xAB)
    {
        dataPacket++;
        length = *dataPacket;
        checksumCheck = calculate_checksum(dataPacket, dataPacket+length);
        //printf("%02x ---- %02x", *dataPacket, *(dataPacket+length));
        //printf("\n CheckSum: %02x", *(dataPacket+length+1));

        if(checksumCheck  == *(dataPacket+length+1))  // first make sure checksum is ok
        {
            dataPacket++;
            packetType = *dataPacket;
            printf("\n Packet Type: %02x \n", packetType);

        }
        else
        {
           // status = CHECKSUMERROR; // checksum error
            NSLog(@"checks usm error");
            
        }

    }
    else
    {
        //status = DISALLOW;
        printf("\n Wrong Header \n");
    }

    //send_acknowledgement_event(packetType, status);

}
*/


-(NSData *)bytesReversed : (char *)hexData
              withLength : (int)dataLength{
    
    Byte tempBytes[100];
    
    for(int i=0; i<dataLength;i++){
        tempBytes[i]=hexData[dataLength-i-1];
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:tempBytes length:dataLength];
    
    return  newData;
}

//-(NSString *)stringByReversed:(NSString *)_strToReverse withSegLength:(int)_segLeng{
//    NSString *strRevesed;
//    
//    if(_segLeng==2){
//        //        int length=(int)([_strToReverse length])>>1;
//        //        unsigned char p=0;
//        //        unsigned char *pBuffer=&p;
//        //
//        //        pBuffer=(unsigned char *)[[self hexStrToBytes:_strToReverse withStrMin:0 withStrMax:100] bytes];
//        //
//        //        NSMutableString *strToReverse=[[NSMutableString alloc] init];
//        //
//        //        for(int i=length-1;i>=0;i--){
//        //            [strToReverse appendString:[NSString stringWithFormat:@"%02x",pBuffer[i]]];
//        //        }
//        //
//        //        strRevesed=[strToReverse uppercaseString];
//        
//        unsigned char pBuffer[6];
//        [[_strToReverse hexToBytes] getBytes:pBuffer length:6];
//        strRevesed=[NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
//                    pBuffer[5], pBuffer[4], pBuffer[3], pBuffer[2], pBuffer[1], pBuffer[0]];
//    }
//    
//    return strRevesed;
//}

+ (NSString *) appleDeviceString
{
    // need #import "sys/utsname.h"
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    /// NSLog(@"deviceString: %@", deviceString);
    
    if([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    //
    if([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    //
    if([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    //
    if([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    //
    if([deviceString isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
    //
    if([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    //
    if([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    //
    if([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5C";
    //
    if([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5C";
    //
    if([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5";
    if([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    
    if([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6+";
    
    if([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    
    if([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    //
    if([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    //
    if([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    //
    if([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    //
    if([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    //
    if([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    //
    if([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    //
    if([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    //
    if([deviceString isEqualToString:@"iPad2,5"])      return @"iPad mini";
    //
    if([deviceString isEqualToString:@"i386"])         return @"Simulator";
    //
    if([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    else return @"Unknown Apple device";
    //
    //    NSLog(@"NOTE: Unknown device type: %@", deviceString);
    
    return deviceString;
}


-(void)restartTimer:(NSTimer*)timer{
    [timer setFireDate:[NSDate distantPast]];
}

-(void)pauseTimer:(NSTimer*)timer{
    [timer setFireDate:[NSDate distantFuture]];
}

-(void)cancelTimer:(NSTimer*)timer{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
}
/*
-(NSDictionary *)getDictFromDefaultCases : (NSArray *)_arrInput{
    NSMutableDictionary *dictRet=[[NSMutableDictionary alloc] init];
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    
    //    NSArray *arrfileData = [_strInput componentsSeparatedByString:NSLocalizedString(@"<B R/>", nil)];
    //    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([_arrInput count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[_arrInput objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        
        /// pickup cmd code
        NSString *cmdValue=[[_arrInput objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *arrCmdStr = [cmdValue componentsSeparatedByString:NSLocalizedString(@",", nil)];
        
        /// NSMutableArray *arrCmd0=[[NSMutableArray alloc] init];
        NSMutableData *dataCmd=[[NSMutableData alloc] init];
        
        for(int j=0;j<[arrCmdStr count];j++){
            NSString *aCmd=[arrCmdStr objectAtIndex:j];
            [aCmd stringByReplacingOccurrencesOfString:@"," withString:@""];
            NSData *subDataCmd=[[Utils sharedInst] hexStrToBytes:aCmd withStrMin:0 withStrMax:10];
            [dataCmd appendData:subDataCmd];
        }
        
        [dictRet setObject:dataCmd forKey:cmdKey];
        [arrRet addObject:cmdKey];
    }
    
    return dictRet;
}
 */
-(NSArray *)getKeysFromDefaultCases : (NSArray *)_defCmds{
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    //
    //    NSArray *arrfileData = [_srcString componentsSeparatedByString:NSLocalizedString(@"<B R/>", nil)];
    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([_defCmds count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[_defCmds objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        [arrRet addObject:cmdKey];
    }
    
    return arrRet;
}
/*
-(NSDictionary *)getAllKeysAndCmdsFromFile : (NSString *)_strInput{
    NSMutableDictionary *dictRet=[[NSMutableDictionary alloc] init];
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    
    NSArray *arrfileData = [_strInput componentsSeparatedByString:NSLocalizedString(@"<BR/>", nil)];
    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([arrfileData count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[arrfileData objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        
        /// pickup cmd code
        NSString *cmdValue=[[arrfileData objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        cmdValue=[cmdValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *arrCmdStr = [cmdValue componentsSeparatedByString:NSLocalizedString(@",", nil)];
        
        /// NSMutableArray *arrCmd0=[[NSMutableArray alloc] init];
        NSMutableData *dataCmd=[[NSMutableData alloc] init];
        
        for(int j=0;j<[arrCmdStr count];j++){
            NSString *aCmd=[arrCmdStr objectAtIndex:j];
            [aCmd stringByReplacingOccurrencesOfString:@"," withString:@""];
            NSData *subDataCmd=[[Utils sharedInst] hexStrToBytes:aCmd withStrMin:0 withStrMax:10];
            [dataCmd appendData:subDataCmd];
        }
        
        [dictRet setObject:dataCmd forKey:cmdKey];
        
        [arrRet addObject:cmdKey];
    }
    
    return dictRet;
}
*/
-(NSArray *)getKeysFromCasesFileString : (NSString *)_srcString{
    NSMutableArray *arrRet=[[NSMutableArray alloc] init];
    
    NSArray *arrfileData = [_srcString componentsSeparatedByString:NSLocalizedString(@"<BR/>", nil)];
    /// NSLog(@"%@ : %lu",arrfileData, (unsigned long)[arrfileData count]);
    
    for(int i=0; i<([arrfileData count]-1);i++){
        /// pickup key.
        NSString *cmdKey=[[arrfileData objectAtIndex:i] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cmdKey=[cmdKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        i++;
        [arrRet addObject:cmdKey];
    }
    
    return arrRet;
}


/**********************************************************
 @breif : convert time with NSDate format into NSInteger,
 from 1970/1/1
 **********************************************************/
-(NSString *)getLocalDateAndTime{
    NSString *retStr=[self getLocalDate];
    retStr=[retStr stringByReplacingOccurrencesOfString:@" +0000" withString:@""];
    return retStr;
}

-(NSString *)getLocalDate{
    NSDate *  localTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    return [NSString stringWithFormat: @"%@",[self getNowDateFromatAnyDate:localTime]];
}

- (uint64_t)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    
    uint64_t totalMilliseconds = interval*1000 ;
    
    return totalMilliseconds;
}

-(NSDate *)getNowDateFromatAnyDate:(NSDate *)anyDate{
    NSTimeZone *srcTimeZone=[NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSTimeZone *destTimeZone=[NSTimeZone localTimeZone];
    NSInteger srcGMTOffset=[srcTimeZone secondsFromGMTForDate:anyDate];
    NSInteger destGMTOffset=[destTimeZone secondsFromGMTForDate:anyDate];
    
    NSTimeInterval interval=destGMTOffset-srcGMTOffset;
    
    NSDate *destDateNow=[[NSDate alloc] initWithTimeInterval:interval sinceDate:anyDate];
    
    /// NSLog(@"destDateNow:%@",destDateNow);
    
    return destDateNow;
}

//
//// e.g. "My iPhone"
//+(NSString *)getDevName{
//    return [[UIDevice currentDevice] name];
//}
//
//// e.g. @"iPhone", @"iPod touch"
//+(NSString *)getDevModel{
//    return [[UIDevice currentDevice] model];
//}
//
// e.g. @"4.0"
+(NSString *)getDevSysVersion{
    // return [NSString stringWithFormat:@"%d", gestaltVersion];
    
    return [[UIDevice currentDevice] systemVersion];
    /// return [[[UIDevice currentDevice] systemVersion] floatValue];
}
@end


