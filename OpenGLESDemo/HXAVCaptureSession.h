//
//  HXAVCaptureSession.h
//  HXPlayer
//
//  Created by anhaoxiong(安浩雄) on 2017/7/13.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVCaptureVideoPreviewLayer;

@class HXAVCaptureSession;
@protocol HXAVCaptureSessionDelegate <NSObject>

-(void)videoDataCallBack:(unsigned char*)pbuffer len:(int)bufferLen width:(int)width height:(int)height;
-(void)audioDataCallBack:(unsigned char*)pbuffer len:(int)bufferLen sampleRate:(int)sampleRate channel:(int)channel;

@end

@interface HXAVCaptureSession : NSObject

@property(nonatomic, weak)id<HXAVCaptureSessionDelegate>delegate;

@property(nonatomic, readonly, getter=isFlashLightOn)BOOL flashLightOn;

-(instancetype)initWithPreview:(UIView*)preview
                      delegate:(id<HXAVCaptureSessionDelegate>)delegate
               pixelFormatType:(NSInteger)pixelFormat
                        preset:(NSString*)AVCaptureSessionPreset 
                     frameRate:(int)frameRate;

+(NSArray<NSNumber*>*)avalibeVideoPixelFormatTypes;

-(void)switchCamera;

-(BOOL)openFlash;

-(void)closeFlash;

-(void)start;

-(void)stop;

@end
