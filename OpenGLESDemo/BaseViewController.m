//
//  BaseViewController.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/18.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()
@end

@implementation BaseViewController


-(void)dealloc{
    [self.drawView deleteDrawable];
    if (self.context == [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:nil];
    }
    printf("\n [dealloc] %s\n", [NSStringFromClass(self.class) UTF8String]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    [EAGLContext setCurrentContext:self.context];
    
    self.drawView = [[GLKView alloc] initWithFrame:self.view.frame context:self.context];
    self.drawView.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [self.view addSubview:self.drawView];
    self.drawView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"click to fit" style:(UIBarButtonItemStylePlain) target:self action:@selector(rightItemClick)];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)rightItemClick {
    self.isFit = !self.isFit;
    if (self.isFit) {
        self.navigationItem.rightBarButtonItem.title = @"click to fill";
    } else {
        self.navigationItem.rightBarButtonItem.title = @"click to fit";
    }
}

- (const char *)vertexShaderDesc {
    return NULL;
}

- (const char *)fragmentShaderDesc {
    return NULL;
}

@end
