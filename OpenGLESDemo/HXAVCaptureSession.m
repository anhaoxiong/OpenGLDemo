//
//  HXAVCaptureSession.m
//  HXPlayer
//
//  Created by anhaoxiong(安浩雄) on 2017/7/13.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "HXAVCaptureSession.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

#ifndef SAFE_FREE
#define SAFE_FREE(p) if((p)){free(p);(p)=NULL;}
#endif

@interface HXAVCaptureSession ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    dispatch_queue_t _captureQueue;
    AVCaptureVideoDataOutput* _videoOutput;
    AVCaptureAudioDataOutput* _audioOutput;
    
    uint8_t *_yuv420buffer;
    
    size_t _width;
    size_t _height;
    int _frameRate;
    NSString* _preset;
    NSInteger _pixelFormat;
}

@property(nonatomic, strong)NSString* test;

@end

@implementation HXAVCaptureSession

+(NSArray<NSNumber *> *)avalibeVideoPixelFormatTypes {
    return [[[AVCaptureVideoDataOutput alloc] init] availableVideoCVPixelFormatTypes];
}

-(void)dealloc{
    [self stop];
    SAFE_FREE(_yuv420buffer);
    printf("\n\n [dealloc] %s\n\n", [NSStringFromClass(self.class) UTF8String]);
}

-(instancetype)initWithPreview:(UIView *)preview delegate:(id<HXAVCaptureSessionDelegate>)delegate pixelFormatType:(NSInteger)pixelFormat preset:(NSString *)AVCaptureSessionPreset frameRate:(int)frameRate {
    
    self = [super init];
    if (self) {
        _pixelFormat    = pixelFormat;
        _preset         = AVCaptureSessionPreset;
        _frameRate      = frameRate;
        self.delegate   = delegate;
        
        _session = [[AVCaptureSession alloc] init];
        _captureQueue = dispatch_queue_create("ahx.capture.queue", DISPATCH_QUEUE_SERIAL);
        
        [self setupSession];

        if (preview && _session) {
            AVCaptureVideoPreviewLayer* layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            layer.frame = preview.layer.bounds;

            [preview.layer addSublayer:layer];
            
//            Class cla = object_setClass(layer, [UIView class]);
//            UIView* view = (UIView*)layer;
//            view.frame = preview.bounds;
//            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//            [preview addSubview:view];
        }
    }
    return self;
}



-(AVCaptureDevice*)videoDeviceWithPosition:(BOOL)isBackDevice{
    
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDevicePosition position = isBackDevice ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice* device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

-(AVCaptureDevice*)audioDevice{
    
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    for (AVCaptureDevice* device in devices) {
        return device;
    }
    return nil;
}


-(void)setupSession{
    
    [self addVideoDevice:true];
    [self addAudioDevice];
    
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *d = nil;
    NSArray* array = [_videoOutput availableVideoCVPixelFormatTypes];
    
    for (NSNumber *format in array) {
        NSLog(@"Support format : %@", [self pixelFormatNameWithValue:format.longValue]);
    }
    if ([array containsObject:[NSNumber numberWithInteger:_pixelFormat]]) {
        d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:_pixelFormat], (id)kCVPixelBufferPixelFormatTypeKey, /*[NSNumber numberWithInt:720], (id)kCVPixelBufferWidthKey, [NSNumber numberWithInt:1280], (id)kCVPixelBufferHeightKey, */nil];
    } else {
        alertError([[NSString stringWithFormat:@"unSupport format : %@", [self pixelFormatNameWithValue:_pixelFormat ]] UTF8String]);
        return;
    }
    
//    if ([array containsObject:[NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]]) {
//        d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, /*[NSNumber numberWithInt:720], (id)kCVPixelBufferWidthKey, [NSNumber numberWithInt:1280], (id)kCVPixelBufferHeightKey, */nil];
//    } else if ([array containsObject:[NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]]) {
//        d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], (id)kCVPixelBufferPixelFormatTypeKey, /*[NSNumber numberWithInt:720], (id)kCVPixelBufferWidthKey, [NSNumber numberWithInt:1280], (id)kCVPixelBufferHeightKey, */nil];
//    }
//    else if ([array containsObject:[NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]){
//        d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], (id)kCVPixelBufferPixelFormatTypeKey,/* [NSNumber numberWithInt:720], (id)kCVPixelBufferWidthKey, [NSNumber numberWithInt:1280], (id)kCVPixelBufferHeightKey, */nil];
//    }
//    else if ([array containsObject:[NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8PlanarFullRange]]){
//        d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8Planar], (id)kCVPixelBufferPixelFormatTypeKey,/* [NSNumber numberWithInt:720], (id)kCVPixelBufferWidthKey, [NSNumber numberWithInt:1280], (id)kCVPixelBufferHeightKey, */nil];
//    }
//    else if ([array containsObject:[NSNumber numberWithInteger:kCVPixelFormatType_420YpCbCr8Planar]]) {
//        d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8PlanarFullRange], (id)kCVPixelBufferPixelFormatTypeKey,/* [NSNumber numberWithInt:720], (id)kCVPixelBufferWidthKey, [NSNumber numberWithInt:1280], (id)kCVPixelBufferHeightKey, */nil];
//    }
    
    
    [_videoOutput setVideoSettings:d];
    
    [_videoOutput setSampleBufferDelegate:self queue:_captureQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
        AVCaptureConnection* cont = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([cont isVideoOrientationSupported]) {
            cont.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    } else {
        [_session commitConfiguration];
        return;
    }
    
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_captureQueue];
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];
    } else {
        [_session commitConfiguration];
        return;
    }
    
    
    if ([_session canSetSessionPreset:_preset]) {
        [_session setSessionPreset:_preset];
    } else {
        NSLog(@"unsupport preset = %@, will using AVCaptureSessionPreset1280x720", _preset);
        if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            [_session setSessionPreset:AVCaptureSessionPreset1280x720];
        }
    }
}


-(void)start{
    if (![_session isRunning]) {
        [_session startRunning];
    }
}

-(void)stop{
    if ([_session isRunning]) {
        [_session stopRunning];
    }
}

-(BOOL)isFlashLightOn{
    NSArray *inputs = _session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            return AVCaptureTorchModeOn == device.torchMode;
        }
    }
    return false;
}

-(BOOL)openFlash{
    NSArray *inputs = _session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            if (AVCaptureTorchModeOn != device.torchMode && [device isTorchModeSupported:(AVCaptureTorchModeOn)]) {
                [_session beginConfiguration];
                [device lockForConfiguration:nil];
                [device setTorchMode:AVCaptureTorchModeOn];
                [device unlockForConfiguration];
                [_session commitConfiguration];
                return true;
            }
        }
    }
    return false;
}

-(void)closeFlash{
    
    NSArray *inputs = _session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            if (AVCaptureTorchModeOff != device.torchMode) {
                [_session beginConfiguration];
                [device lockForConfiguration:nil];
                [device setTorchMode:AVCaptureTorchModeOff];
                [device unlockForConfiguration];
                [_session commitConfiguration];
            }
            break;
        }
    }
}

-(void)addAudioDevice{
    NSError* error;
    AVCaptureDevice* audioDevice = [self audioDevice];
    assert(audioDevice);
    
    AVCaptureDeviceInput* audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!audioDevice) {
        [_session commitConfiguration];
        NSLog(@"error = %@", error);
        return;
    }
    
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput];
    } else {
        NSLog(@"add audio device error");
        return;
    }
}

-(void)addVideoDevice:(BOOL)isBackground{
    
    AVCaptureDevice* videoDevice = [self videoDeviceWithPosition:isBackground];
    assert(videoDevice);
    
    [videoDevice lockForConfiguration:nil];
    [videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, _frameRate)];
    [videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, _frameRate)];
    [videoDevice unlockForConfiguration];
    
    NSError* error;
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!videoDevice) {
        NSLog(@"error : %@", error);
        return;
    }
    
    if ([_session canAddInput:videoInput]) {
        [_session addInput:videoInput];
    }
}

-(void)switchCamera{
    
    NSArray *inputs = _session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            
            BOOL isBackground;
            if (device.position == AVCaptureDevicePositionFront) {
                isBackground = true;
            } else {
                isBackground = false;
            }
            [_session beginConfiguration];
            [_session removeInput:input];
            [self addVideoDevice:isBackground];
            
            AVCaptureConnection* cont = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([cont isVideoOrientationSupported]) {
                cont.videoOrientation = AVCaptureVideoOrientationPortrait;
            }
            cont.automaticallyAdjustsVideoMirroring = true;
            [_session commitConfiguration];
            break; 
        } 
    }
}


//kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
-(void)sampleNV12ToI420Buffer:(CMSampleBufferRef)sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    NSUInteger offset = 0;
    
    CVPixelBufferLockBaseAddress(imageBuffer,kCVPixelBufferLock_ReadOnly);
    
    
    //注意 planeWidth 很有可能是 !=  perRowLen, so...
    size_t planeWidth   = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    size_t planeHeight  = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    size_t perRowLen    = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    unsigned char *address  = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bufferWidth = CVPixelBufferGetWidth(imageBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(imageBuffer);
    if (bufferWidth != _width || bufferHeight != _height) {
        _width   = bufferWidth;
        _height  = bufferHeight;
        SAFE_FREE(_yuv420buffer);
        size_t size = _width * _height * 3 / 2;
        _yuv420buffer = malloc(size);
    }
    
    for (int i = 0; i < planeHeight; i ++) {
        memcpy(_yuv420buffer + i * planeWidth, address + perRowLen * i, planeWidth);
    }
    offset += (planeWidth * planeHeight);
    
    planeWidth      = CVPixelBufferGetWidthOfPlane(imageBuffer, 1);
    planeHeight     = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
    perRowLen       = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    address         = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    
    uint8_t* u = _yuv420buffer + offset;
    uint8_t* v = _yuv420buffer + offset + offset / 4;
    
    for (int i = 0; i < planeHeight; i ++) {
        for (int j = 0; j < planeWidth ; j ++) {
            u[(i*planeWidth + j)] = address[i * perRowLen + j * 2];
            v[(i*planeWidth + j)] = address[i * perRowLen + j * 2  + 1];
        }
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
}


-(void)sampleNV12ToNV12Buffer:(CMSampleBufferRef)sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer,kCVPixelBufferLock_ReadOnly);
    
    size_t planeWidth   = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    size_t planeHeight  = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    size_t perRowLen    = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    unsigned char *address  = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bufferWidth = CVPixelBufferGetWidth(imageBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(imageBuffer);
    if (bufferWidth != _width || bufferHeight != _height) {
        _width   = bufferWidth;
        _height  = bufferHeight;
        SAFE_FREE(_yuv420buffer);
        size_t size = _width * _height * 3 / 2;
        _yuv420buffer = malloc(size);
    }
    
    for (int i = 0; i < planeHeight; i ++) {
        memcpy(_yuv420buffer + i * planeWidth, address + i * perRowLen, planeWidth);
    }
    
    planeWidth   = CVPixelBufferGetWidthOfPlane(imageBuffer, 1);
    planeHeight  = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
    perRowLen    = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    address      = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    
    
    for (int i = 0; i < planeHeight; i ++) {
        memcpy(_yuv420buffer + _width * _height + i * planeWidth * 2, address + i * perRowLen, planeWidth * 2);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
}


-(void)sampleRGB32ToRGB32Buffer:(CMSampleBufferRef)sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer,kCVPixelBufferLock_ReadOnly);
    
    size_t perRowLen    = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    unsigned char *address  = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bufferWidth = CVPixelBufferGetWidth(imageBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(imageBuffer);
    if (bufferWidth != _width || bufferHeight != _height) {
        _width   = bufferWidth;
        _height  = bufferHeight;
        SAFE_FREE(_yuv420buffer);
        size_t size = _width * _height * 4;
        _yuv420buffer = malloc(size);
    }
    
    for (int i = 0; i < bufferHeight; i ++) {
        memcpy(_yuv420buffer + i * bufferWidth * 4, address + i * perRowLen, perRowLen);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (!CMSampleBufferDataIsReady(sampleBuffer)) return;
    
    if (captureOutput == _audioOutput) {
        
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        char *dataPointer = NULL;
        size_t lengthAtOffset, totalLength;
        OSStatus err = CMBlockBufferGetDataPointer(blockBuffer, 0,  &lengthAtOffset, &totalLength, &dataPointer);
        if (0 == err) {
            [self.delegate audioDataCallBack:(unsigned char*)dataPointer len:(int)totalLength sampleRate:44100 channel:1];
        }
        
    } else if (captureOutput == _videoOutput) {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        OSType pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
        switch (pixelFormat) {
            case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:{
                //source buffer format is nv12
#if 1
                [self sampleNV12ToI420Buffer:sampleBuffer];
                [self.delegate videoDataCallBack:_yuv420buffer len:(int)_width*(int)_height*3/2 width:(int)_width height:(int)_height];
#else
                [self sampleNV12ToNV12Buffer:sampleBuffer];
                [self.delegate videoDataCallBack:_yuv420buffer len:(int)_width*(int)_height*3/2 width:(int)_width height:(int)_height];
#endif
            }
                break;
                
                
            case kCVPixelFormatType_420YpCbCr8Planar:
            case kCVPixelFormatType_420YpCbCr8PlanarFullRange:{
                //source buffer format is i420
                //这里提取数据就比较简单了
            }
                break;
                
            case kCVPixelFormatType_32BGRA: {
                [self sampleRGB32ToRGB32Buffer:sampleBuffer];
                [self.delegate videoDataCallBack:_yuv420buffer len:(int)_width*(int)_height*4 width:(int)_width height:(int)_height];
            }
            default:
                break;
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
#if 0
    static int i = 0;
    NSLog(@"didDropSampleBuffer = %d", ++i);
#endif
}



-(NSString*)pixelFormatNameWithValue:(long)format{
    
    switch (format) {
        case kCVPixelFormatType_1Monochrome:{
            return @"kCVPixelFormatType_1Monochrome";
        }
        case kCVPixelFormatType_2Indexed:{
            return @"kCVPixelFormatType_2Indexed";
        }
        case kCVPixelFormatType_4Indexed:{
            return @"kCVPixelFormatType_4Indexed";
        }
        case kCVPixelFormatType_8Indexed:{
            return @"kCVPixelFormatType_8Indexed";
        }
        case kCVPixelFormatType_1IndexedGray_WhiteIsZero:{
            return @"kCVPixelFormatType_1IndexedGray_WhiteIsZero";
        }
        case kCVPixelFormatType_2IndexedGray_WhiteIsZero:{
            return @"kCVPixelFormatType_2IndexedGray_WhiteIsZero";
        }
        case kCVPixelFormatType_4IndexedGray_WhiteIsZero:{
            return @"kCVPixelFormatType_4IndexedGray_WhiteIsZero";
        }
        case kCVPixelFormatType_8IndexedGray_WhiteIsZero:{
            return @"kCVPixelFormatType_8IndexedGray_WhiteIsZero";
        }
        case kCVPixelFormatType_16LE555:{
            return @"kCVPixelFormatType_16LE555";
        }
        case kCVPixelFormatType_16LE5551:{
            return @"kCVPixelFormatType_16LE5551";
        }
        case kCVPixelFormatType_16BE565:{
            return @"kCVPixelFormatType_16BE565";
        }
        case kCVPixelFormatType_16LE565:{
            return @"kCVPixelFormatType_16LE565";
        }
        case kCVPixelFormatType_24RGB:{
            return @"kCVPixelFormatType_24RGB";
        }
        case kCVPixelFormatType_24BGR:{
            return @"kCVPixelFormatType_24BGR";
        }
        case kCVPixelFormatType_32ARGB:{
            return @"kCVPixelFormatType_32ARGB";
        }
        case kCVPixelFormatType_32BGRA:{
            return @"kCVPixelFormatType_32BGRA";
        }
        case kCVPixelFormatType_32ABGR:{
            return @"kCVPixelFormatType_32ABGR";
        }
        case kCVPixelFormatType_32RGBA:{
            return @"kCVPixelFormatType_32RGBA";
        }
        case kCVPixelFormatType_64ARGB:{
            return @"kCVPixelFormatType_64ARGB";
        }
        case kCVPixelFormatType_48RGB:{
            return @"kCVPixelFormatType_48RGB";
        }
        case kCVPixelFormatType_32AlphaGray:{
            return @"kCVPixelFormatType_32AlphaGray";
        }
        case kCVPixelFormatType_16Gray:{
            return @"kCVPixelFormatType_16Gray";
        }
        case kCVPixelFormatType_30RGB:{
            return @"kCVPixelFormatType_30RGB";
        }
        case kCVPixelFormatType_422YpCbCr8:{
            return @"kCVPixelFormatType_422YpCbCr8";
        }
        case kCVPixelFormatType_4444YpCbCrA8:{
            return @"kCVPixelFormatType_4444YpCbCrA8";
        }
        case kCVPixelFormatType_4444YpCbCrA8R:{
            return @"kCVPixelFormatType_4444YpCbCrA8R";
        }
        case kCVPixelFormatType_4444AYpCbCr8:{
            return @"kCVPixelFormatType_4444AYpCbCr8";
        }
        case kCVPixelFormatType_4444AYpCbCr16:{
            return @"kCVPixelFormatType_4444AYpCbCr16";
        }
        case kCVPixelFormatType_444YpCbCr8:{
            return @"kCVPixelFormatType_444YpCbCr8";
        }
        case kCVPixelFormatType_422YpCbCr16:{
            return @"kCVPixelFormatType_422YpCbCr16";
        }
        case kCVPixelFormatType_422YpCbCr10:{
            return @"kCVPixelFormatType_422YpCbCr10";
        }
        case kCVPixelFormatType_444YpCbCr10:{
            return @"kCVPixelFormatType_444YpCbCr10";
        }
        case kCVPixelFormatType_420YpCbCr8Planar:{
            return @"kCVPixelFormatType_420YpCbCr8Planar";
        }
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:{
            return @"kCVPixelFormatType_420YpCbCr8PlanarFullRange";
        }
        case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:{
            return @"kCVPixelFormatType_422YpCbCr_4A_8BiPlanar";
        }
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:{
            return @"kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange";
        }
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:{
            return @"kCVPixelFormatType_420YpCbCr8BiPlanarFullRange";
        }
        case kCVPixelFormatType_422YpCbCr8_yuvs:{
            return @"kCVPixelFormatType_422YpCbCr8_yuvs";
        }
        case kCVPixelFormatType_422YpCbCr8FullRange:{
            return @"kCVPixelFormatType_422YpCbCr8FullRange";
        }
        case kCVPixelFormatType_OneComponent8:{
            return @"kCVPixelFormatType_OneComponent8";
        }
        case kCVPixelFormatType_TwoComponent8:{
            return @"kCVPixelFormatType_TwoComponent8";
        }
        case kCVPixelFormatType_30RGBLEPackedWideGamut:{
            return @"kCVPixelFormatType_30RGBLEPackedWideGamut";
        }
        case kCVPixelFormatType_ARGB2101010LEPacked:{
            return @"kCVPixelFormatType_ARGB2101010LEPacked";
        }
        case kCVPixelFormatType_OneComponent16Half:{
            return @"kCVPixelFormatType_OneComponent16Half";
        }
        case kCVPixelFormatType_OneComponent32Float:{
            return @"kCVPixelFormatType_OneComponent32Float";
        }
        case kCVPixelFormatType_TwoComponent16Half:{
            return @"kCVPixelFormatType_TwoComponent16Half";
        }
        case kCVPixelFormatType_TwoComponent32Float:{
            return @"kCVPixelFormatType_TwoComponent32Float";
        }
        case kCVPixelFormatType_64RGBAHalf:{
            return @"kCVPixelFormatType_64RGBAHalf";
        }
        case kCVPixelFormatType_128RGBAFloat:{
            return @"kCVPixelFormatType_128RGBAFloat";
        }
        case kCVPixelFormatType_14Bayer_GRBG:{
            return @"kCVPixelFormatType_14Bayer_GRBG";
        }
        case kCVPixelFormatType_14Bayer_RGGB:{
            return @"kCVPixelFormatType_14Bayer_RGGB";
        }
        case kCVPixelFormatType_14Bayer_BGGR:{
            return @"kCVPixelFormatType_14Bayer_BGGR";
        }
        case kCVPixelFormatType_14Bayer_GBRG:{
            return @"kCVPixelFormatType_14Bayer_GBRG";
        }
            
        default:
            return @"ERROR FORMAT";
    }
}

@end
