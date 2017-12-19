//
//  Camerai420ViewController.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/19.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "Camerai420ViewController.h"
#import "HXAVCaptureSession.h"

@interface Camerai420ViewController ()
<
HXAVCaptureSessionDelegate
>
{
    GLuint _textureIDArray[3];
}
@property (nonatomic, strong)HXAVCaptureSession *captureSession;
@property (nonatomic)GLuint program;
@property (nonatomic)int sampleVarIndexY;
@property (nonatomic)int sampleVarIndexU;
@property (nonatomic)int sampleVarIndexV;
@end

@implementation Camerai420ViewController


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
        "#version 300 es                                          \n"
        "precision highp float;                                   \n"
        "in vec2 v2f_textCoor;                                    \n"
        "uniform sampler2D uniform_textureIDY;                    \n"
        "uniform sampler2D uniform_textureIDU;                    \n"
        "uniform sampler2D uniform_textureIDV;                    \n"
        "out vec4 out_color;                                      \n"
        "void main() {                                            \n"
        "   float y = texture(uniform_textureIDY, v2f_textCoor).r;\n"
        "   y = 1.1643 * (y - 0.0625);                            \n"
        "   float u = texture(uniform_textureIDU, v2f_textCoor).r - 0.5;\n"
        "   float v = texture(uniform_textureIDV, v2f_textCoor).r - 0.5;\n"
        "   out_color.r = y + 1.5958*v;                           \n"
        "   out_color.g = y - 0.39173*u - 0.81290*v;              \n"
        "   out_color.b = y + 2.017*u;                            \n"
        "   out_color.a = 1.0;                                    \n"
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
    
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.program);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), vertexs);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), &vertexs[3]);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[0]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, buffer);
    glUniform1i(self.sampleVarIndexY, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width / 2, height / 2, 0, GL_RED, GL_UNSIGNED_BYTE, buffer + width * height);
    glUniform1i(self.sampleVarIndexU, 1);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[2]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width / 2, height / 2, 0, GL_RED, GL_UNSIGNED_BYTE, buffer + width * height * 5 / 4);
    glUniform1i(self.sampleVarIndexV, 2);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
    
    [self.drawView display];//一定要调用display才能将结果显示出来？？？！！！
}

- (void)loadTexture {
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(ARRAY_SIZE(_textureIDArray), _textureIDArray);
    for (int i = 0; i < ARRAY_SIZE(_textureIDArray); i ++) {
        glBindTexture(GL_TEXTURE_2D, _textureIDArray[i]);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }
}


- (int)setupOpenGL {
    
    GLuint program = createProgram([self vertexShaderDesc], [self fragmentShaderDesc]);
    if (program) {
        glClearColor(0, 0, 0, 1);
        self.sampleVarIndexY    = glGetUniformLocation(program, "uniform_textureIDY");
        self.sampleVarIndexU   = glGetUniformLocation(program, "uniform_textureIDU");
        self.sampleVarIndexV   = glGetUniformLocation(program, "uniform_textureIDV");
    }
    
    return program;
}

- (void)setupSession {
    self.captureSession = [[HXAVCaptureSession alloc] initWithPreview:nil delegate:self pixelFormatType:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange preset:AVCaptureSessionPreset640x480 frameRate:25];
}

- (void)videoDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen width:(int)width height:(int)height {
    [self draw:pbuffer width:width height:height];
}

- (void)audioDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen sampleRate:(int)sampleRate channel:(int)channel {
    
}


@end
