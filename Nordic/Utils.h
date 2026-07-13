//
//  Utils.h
//
//  Created by NXP on 10/25/15.
//  Copyright (c) 2015 NXP. All rights reserved.
//

///#import "FUIButton.h"
/// #import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "Utils.h"

#define UNKNOWN_SEQUENCE        @"UNKNOWN_SEQUENCE"
#define LAUNCHED_KEY            @"LAUNCHED_KEY"
#define IS_SUBORDINATE          @"IS_SUBORDINATE"

#define CONTROL_OPERATION       LK_OP_CONTROL_COMMAND

@interface Utils : NSObject{
    
}
 

//+ (void)initUITabBarItem:(UIViewController *)viewController title:(NSString *)title imageName:(NSString *)imageName tag:(NSInteger)tag;
//
//
//+ (void)initCSStyleButton:(FUIButton *)button;
//
//+ (NSString *)createUnkownDeviceName;
//
//+ (BOOL)isLaunched;
//+ (void)setLaunched;
//
//+ (BOOL)isSubordinate;
//+ (void)setSubordinate:(BOOL)isSubordinate;

-(NSData*)channelSwitchOnCommand:(int)channel;
-(NSData*)channelSwitchOffCommand:(int)channel;
    
-(NSData*)sendProfileCodec:(int)profileSelected;
-(NSData*)sendVolumeCodec:(int)volumeSelected;
-(NSData*)viewProfileCodec;

-(NSData*)fourSecondsPPG;
-(NSData*)startBioMetricGraph;
-(NSData*)stopBioMetricGraph;

-(NSData*)sendReadGain;
-(NSData*)sendWriteGain:(int)value1 value2:(int)value2;


-(NSData*)startECGPPGGraph;
-(NSData*)stopECGPPGGraph;

-(NSData*)startBpmGraph;
-(NSData*)stopBpmGraph;

-(NSData*)startHRM;
-(NSData*)stopHRM;

-(NSData*)startHRV;
-(NSData*)stopHRV;

-(NSData*)hardwareStatus;
-(NSData*)firmwareStatus;
-(NSData*)systemStatus;
-(NSData*)systemSerial;

-(NSData*)startBioMetricGraphLND;
-(NSData*)startBioMetricGraphDiscOpt;
-(NSData*)startBioMetricGraphDigiOpt;

-(NSData*)stopBioMetricGraphLND;
-(NSData*)stopBioMetricGraphDigiOpt;
-(NSData*)stopBioMetricGraphDiscOpt;

-(NSData*)sendReadGainLND;
-(NSData*)sendReadGainDigiOpt;
-(NSData*)sendReadGainDiscOpt;

-(NSDictionary*)sendWriteGainLND:(int)value;
-(NSDictionary*)sendWriteGainDiscOpt:(int)value;
-(NSDictionary*)sendWriteGainDigiOpt:(int)value;

-(NSData*)sendWriteGainChannel:(int)value;
-(NSData*)sendreadGainChannel;

-(NSData*)sendReadCurrentLND;
-(NSData*)sendReadCurrentDiscOpt;
-(NSData*)sendReadCurrentDigiOpt;

-(NSDictionary*)sendWriteCurrentLND:(int)value;
-(NSDictionary*)sendWriteCurrentDiscOpt:(int)value;
-(NSDictionary*)sendWriteCurrentDigiOpt:(int)value;

-(NSData *)hexStrToBytes : (NSString *)hexString
              withStrFreq : (NSString*)withStrFreq
              withStrAmp : (NSString*)withStrAmp ;

-(NSData *)writePacketLED : (NSString *)redString
withBlueString : (NSString*)blueString
       withStrGreenString : (NSString*)greenString withStrIntensityString : (NSString*)intensityString;

-(NSData *)changeBluetoothName : (NSArray *)name;
-(NSData *)changeBluetoothAddress : (NSArray *)name;

-(NSData*)readConnectedBLEName;
-(NSData*)readBatteryPercentage;
-(NSData*)readBLEName;
-(NSData*)enableLaser;
-(NSData*)enableLaserCodec;
-(NSData*)disableLaser;
-(NSData*)systemReset;

-(NSData*)startCount;
-(NSData*)stopCount;

-(uint32_t)decStrToDec : (NSString *)decString
        withStrMin : (int)strMin
        withStrMax : (int)strMax;

-(NSData *)bytesReversed : (char *)hexData
              withLength : (int)dataLength;

/// -(NSString *)stringByReversed:(NSString *)_strToReverse withSegLength:(int)_segLeng;

-(NSString *)bytesToString : (uint8_t *)_inBytes
                withLength : (uint8_t)_length;

-(NSData*)intiateBootload;
-(NSData*)loadBootload:(NSArray*)hexArray withstring255:(NSString*)string255 packetCountHexTotal:(int)value  packetCount:(int)value;
-(NSData*)completeBootload;


-(NSData*)intiateBootloadRight;
-(NSData*)loadBootloadRight:(NSArray*)hexArray withstring255:(NSString*)string255 packetCountHexTotal:(int)value  packetCount:(int)value;
-(NSData*)completeBootloadRight;


-(NSData*)intiateBootloadCodec;
-(NSData*)loadCodecBootload:(NSString*)hexString hexArr:(NSArray*)hexArray packetIndex:(int)packetIndex  profileIndex:(int)profileIndex;
-(NSData*)completeBootloadCodec;

-(NSData*)deviceStatus;

-(void)restartTimer:(NSTimer*)timer;
-(void)pauseTimer:(NSTimer*)timer;
-(void)cancelTimer:(NSTimer*)timer;

-(u_int64_t)getCurenntTime;


//-(NSDictionary *)getAllKeysAndCmdsFromFile : (NSString *)_srcString;

-(NSArray *)getKeysFromCasesFileString : (NSString *)_srcString;

//-(NSDictionary *)getDictFromDefaultCases : (NSArray *)_input;
-(NSArray *)getKeysFromDefaultCases : (NSArray *)_defCases;

-(NSString *)getLocalDate;

-(NSString *)getLocalDateAndTime;

+ (NSString *) appleDeviceString;

//// e.g. "My iPhone"
//+(NSString *)getDevName;
//
//// e.g. @"iPhone", @"iPod touch"
//+(NSString *)getDevModel;

// e.g. @"4.0"
+(NSString *)getDevSysVersion;

+ (Utils *)sharedInst;

//+ (void)updateGroupsOperationAccordingDeviceOperation:(DeviceOperationTable *)deviceOperation;


@end
