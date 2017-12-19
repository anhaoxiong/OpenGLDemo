//
//  CameraBGRAViewController.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/19.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "CameraBGRAViewController.h"
#import "HXAVCaptureSession.h"
#import <AVFoundation/AVFoundation.h>

@interface CameraBGRAViewController ()
<
HXAVCaptureSessionDelegate
>

@property (nonatomic, strong)HXAVCaptureSession *captureSession;
@property (nonatomic)GLuint program;
@property (nonatomic)GLuint textureID;
@property (nonatomic)int textureVarIndex;
@property (nonatomic)BOOL isFit;
@end

@implementation CameraBGRAViewController

- (void)dealloc {
    
    [self.captureSession stop];
    
    if (self.textureID) {
        glDeleteTextures(1, &_textureID);
    }
    
    if (self.program) {
        glDeleteProgram(self.program);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.program = [self setupOpenGL];
    if (self.program) {
        [self loadTexture];
    }
    
    [self setupSession];
    
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
    
    static const char str[] = {
        "#version 300 es                                    \n"
        "layout(location = 0)in vec4 in_position;           \n"
        "layout(location = 1)in vec2 in_textCoor;           \n"
        "out vec2 v2f_textCoor;                             \n"
        "void main() {                                      \n"
        "   gl_Position = in_position;                      \n"
        "   v2f_textCoor = in_textCoor;                     \n"
        "}"
    };
    
    return str;
}

- (const char *)fragmentShaderDesc {
    
    static const char str[] = {
        "#version 300 es                                        \n"
        "precision mediump float;                               \n"
        "in vec2 v2f_textCoor;                                  \n"
        "uniform sampler2D uniform_textureID;                   \n"
        "out vec4 out_color;                                    \n"
        "void main() {                                          \n"
        "   vec4 tempColor = texture(uniform_textureID, v2f_textCoor);\n"
        "   out_color.r = tempColor.b;                          \n"
        "   out_color.g = tempColor.g;                          \n"
        "   out_color.b = tempColor.r;                          \n"
        "   out_color.a = tempColor.a;                          \n"
        "}"
    };
    
    return str;
}

- (void)draw:(unsigned char *)buffer width:(int)width height:(int)height {
    
    static GLfloat vertexs[] = {
        -1.0f, 1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f, 0.0f,
        1.0f, 0.0f,
        -1.0f, -1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, -1.0f, 0.0f,
        1.0f, 1.0f
    };
    
    GLushort indices[6] = {0, 1, 2, 1, 2, 3};
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    if (self.isFit) {
        int drawableWidth   = self.drawView.drawableWidth;
        int drawableHeight  = self.drawView.drawableHeight;
        float value = (float)width / (float)height;
        float value2 = (CGFloat)self.drawView.drawableWidth / (CGFloat)self.drawView.drawableHeight;
        if (value > value2) {
            drawableHeight = drawableWidth * (CGFloat)height / (CGFloat)width;
        } else {
            drawableWidth = drawableHeight * (CGFloat)width / (CGFloat)height;
        }
        glViewport((self.drawView.drawableWidth - drawableWidth)/2, (self.drawView.drawableHeight - drawableHeight)/2, (GLsizei)drawableWidth, (GLsizei)drawableHeight);
    } else {
        glViewport(0, 0, (GLsizei)self.drawView.drawableWidth, (GLsizei)self.drawView.drawableHeight);
    }
    
    //    glScissor(0, 0, (GLsizei)self.drawView.drawableWidth/2, (GLsizei)self.drawView.drawableHeight/2);
    //    glEnable(GL_SCISSOR_TEST);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.program);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), vertexs);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), &vertexs[3]);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    glUniform1i(self.textureVarIndex, 0);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
    
    //    glDisableVertexAttribArray(0);
    //    glDisableVertexAttribArray(1);
    
    [self.drawView display];//一定要调用display才能将结果显示出来？？？！！！
}

- (void)loadTexture {
    
    GLuint texture;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    self.textureID = texture;
}

- (int)setupOpenGL {
    
    GLuint program = createProgram([self vertexShaderDesc], [self fragmentShaderDesc]);
    if (program) {
        glClearColor(0, 0, 0, 1);
        self.textureVarIndex = glGetUniformLocation(program, "uniform_textureID");
    }
    return program;
}

- (void)setupSession {
    self.captureSession = [[HXAVCaptureSession alloc] initWithPreview:nil delegate:self pixelFormatType:kCVPixelFormatType_32BGRA preset:AVCaptureSessionPreset640x480 frameRate:25];
    [self.captureSession start];
}

- (void)videoDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen width:(int)width height:(int)height {
    [self draw:pbuffer width:width height:height];
}

- (void)audioDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen sampleRate:(int)sampleRate channel:(int)channel {
    
}

@end
