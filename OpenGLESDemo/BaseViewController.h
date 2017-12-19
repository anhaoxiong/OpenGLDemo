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

@interface BaseViewController : UIViewController

@property (nonatomic, strong) GLKView   * _Nonnull drawView;
@property (nonnull, strong) EAGLContext *context;

- (const char*_Nullable)vertexShaderDesc;
- (const char*_Nonnull)fragmentShaderDesc;

@end
