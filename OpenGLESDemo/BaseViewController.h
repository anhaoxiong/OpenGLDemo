//
//  BaseViewController.h
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/18.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@interface BaseViewController : UIViewController{
    
}

@property (nonatomic, strong)   GLKView     *drawView;
@property (nonatomic, strong)   EAGLContext *context;
@property (nonatomic)           BOOL        isFit;

- (const char*)vertexShaderDesc;
- (const char*)fragmentShaderDesc;
- (void)rightItemClick;
@end
