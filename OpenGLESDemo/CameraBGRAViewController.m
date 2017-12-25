//
//  CameraBGRAViewController.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/19.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "CameraBGRAViewController.h"
#import "HXAVCaptureSession.h"

@interface CameraBGRAViewController ()
<
HXAVCaptureSessionDelegate
>
{
    GLuint _textureIDArray[1];
}
@property (nonatomic, strong) HXAVCaptureSession *captureSession;
@property (nonatomic) GLuint program;
@property (nonatomic) int sample2DVarIndex;
@end

@implementation CameraBGRAViewController

- (void)dealloc {
    
    glDeleteTextures(ARRAY_SIZE(_textureIDArray), _textureIDArray);
    
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
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.captureSession start];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.captureSession stop];
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
    
    CGSize drawableSize = [self drawableSizeWithDataWidth:width dataHeight:height];

    glViewport((GLint)(self.drawView.drawableWidth - drawableSize.width)/2, (GLint)(self.drawView.drawableHeight - drawableSize.height)/2, (GLsizei)drawableSize.width, (GLsizei)drawableSize.height);
    
    //    glScissor(0, 0, (GLsizei)self.drawView.drawableWidth/2, (GLsizei)self.drawView.drawableHeight/2);
    //    glEnable(GL_SCISSOR_TEST);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.program);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), vertexs);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), &vertexs[3]);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[0]);
    glUniform1i(self.sample2DVarIndex, 0);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);

    [self.drawView display];
}

- (void)loadTexture {
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(ARRAY_SIZE(_textureIDArray), _textureIDArray);
    for (int i = 0; i < ARRAY_SIZE(_textureIDArray); i ++) {
        glBindTexture(GL_TEXTURE_2D, _textureIDArray[i]);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR显示效果优于GL_NEAREST，但是GL_LINEAR也消耗更多性能
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}

- (int)setupOpenGL {
    
    GLuint program = createProgram([self vertexShaderDesc], [self fragmentShaderDesc]);
    if (program) {
        glClearColor(0, 0, 0, 1);
        self.sample2DVarIndex = glGetUniformLocation(program, "uniform_textureID");
    }
    return program;
}

- (void)setupSession {
    self.captureSession = [[HXAVCaptureSession alloc] initWithPreview:nil delegate:self pixelFormatType:kCVPixelFormatType_32BGRA preset:AVCaptureSessionPreset640x480 frameRate:25];
}

- (void)videoDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen width:(int)width height:(int)height {
    [self draw:pbuffer width:width height:height];
}

- (void)audioDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen sampleRate:(int)sampleRate channel:(int)channel {
    
}

@end
