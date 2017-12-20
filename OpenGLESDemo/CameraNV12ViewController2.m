//
//  CameraNV12ViewController2.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/20.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "CameraNV12ViewController2.h"
#import "HXAVCaptureSession.h"


// 与 CameraNV12ViewController类相比较:
//    1. 本类中使用了VBO/VAO(顶点缓冲区对象/顶点数组对象):
//          优势: 直接将顶点数据缓存到图形内存中，不用每次渲染都从CUP中拷贝，降低内存的同时，性能也会提高，耗电量就小咯
//          扩展: opengl 3 中引入VAO(顶点数组对象)，相当于C语言中函数指针，可以避免重复的写代码（不知道对性能会不会改进，感觉不会，但是书上说会，完了！！！）
//    2. glTexStorage2D创建不可变纹理，可以提高性能，但是没有搞定！！！！
//
//

#define USE_VAO 1


@interface CameraNV12ViewController2 ()
<
HXAVCaptureSessionDelegate
>
{
    GLuint _textureIDArray[2];
    GLuint _vboIDArray[3];
    GLuint _vaoIDArray[1];
}

@property (nonatomic, strong) HXAVCaptureSession *captureSession;
@property (nonatomic) GLuint program;
@property (nonatomic) int sample2DVarIndexY;
@property (nonatomic) int sample2DVarIndexUV;

@end




@implementation CameraNV12ViewController2

- (void)dealloc {

    glDeleteTextures(ARRAY_SIZE(_textureIDArray), _textureIDArray);
    glDeleteBuffers(ARRAY_SIZE(_vboIDArray), _vboIDArray);
    
#if USE_VAO
    glDeleteVertexArrays(ARRAY_SIZE(_vaoIDArray), _vaoIDArray);
#endif
    
    if (self.program) {
        glDeleteProgram(self.program);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.program = [self setupOpenGL];
    if (self.program) {
        [self loadTexture];
        [self loadBuffer];
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
        "#version 300 es                                            \n"
        "precision mediump float;                                   \n"
        "in vec2 v2f_textCoor;                                      \n"
        "uniform sampler2D uniform_textureIDY;                      \n"
        "uniform sampler2D uniform_textureIDUV;                     \n"
        "out vec4 out_color;                                        \n"
        "void main() {                                              \n"
        "   vec4 vec_uv = texture(uniform_textureIDUV, v2f_textCoor);  \n"
        "   float y = texture(uniform_textureIDY, v2f_textCoor).r;  \n"
        "   y = 1.1643 * (y - 0.0625);                              \n"
        "   float u = vec_uv.r - 0.5;                               \n"
        "   float v = vec_uv.g - 0.5;                               \n"
        "   out_color.r = y + 1.5958*v;                             \n"
        "   out_color.g = y - 0.39173*u - 0.81290*v;                \n"
        "   out_color.b = y + 2.017*u;                              \n"
        "   out_color.a = 1.0;                                      \n"
        "}"
    };
    
    return str;
}

- (void)draw:(unsigned char *)buffer width:(int)width height:(int)height {
    
    //在使用buffer的时候，glVertexAttribPointer的最后一个参数将退化为 glBufferData 中设置的 data 的偏移量，就是
    
    CGSize drawableSize = [self drawableSizeWithDataWidth:width dataHeight:height];
    
    glViewport((GLint)(self.drawView.drawableWidth - drawableSize.width)/2, (GLint)(self.drawView.drawableHeight - drawableSize.height)/2, (GLsizei)drawableSize.width, (GLsizei)drawableSize.height);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.program);
    
#if USE_VAO
    glBindVertexArray(_vaoIDArray[0]);
#else
    glBindBuffer(GL_ARRAY_BUFFER, _vboIDArray[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);//最后一个参数在这里退化为 @1 中设置的 vertexs 偏移量
    
    glBindBuffer(GL_ARRAY_BUFFER, _vboIDArray[1]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, 0);//最后一个参数在这里退化为 @2 中设置的 texturePosition 偏移量
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIDArray[2]);
#endif
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[0]);
    
    
//    glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_R11_EAC, width, height, 0, width*height, buffer);//还以为这个会压缩数据，原来这个只是加载压缩的数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, buffer);
    glUniform1i(self.sample2DVarIndexY, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[1]);
//    glCompressedTexImage2D(GL_TEXTURE_2D, 0, GL_COMPRESSED_RG11_EAC, width >> 1, height >> 1, 0, width*height >> 1, buffer + width * height);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG8, width >> 1, height >> 1, 0, GL_RG, GL_UNSIGNED_BYTE, buffer + width * height);
    glUniform1i(self.sample2DVarIndexUV, 1);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);//最后一个参数在这里退化为 @3 中设置的 indices 偏移量
    
    [self.drawView display];//一定要调用display才能将结果显示出来？？？！！！
}

- (void)loadTexture {
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(ARRAY_SIZE(_textureIDArray), _textureIDArray);
    for (int i = 0; i < ARRAY_SIZE(_textureIDArray); i ++) {
        glBindTexture(GL_TEXTURE_2D, _textureIDArray[i]);
//        if (0 == i) {
//            glTexStorage2D(GL_TEXTURE_2D, 0, GL_R8, 480, 640);
//        } else {
//            glTexStorage2D(GL_TEXTURE_2D, 0, GL_RG8, 480 >> 1, 640 >> 1);
//        }
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR显示效果优于GL_NEAREST，但是GL_LINEAR也消耗更多性能
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}

- (void)loadBuffer {
    
    GLfloat vertexsPosition[] = {
        -1.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 0.0f,
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
    };
    
    GLfloat texturePosition[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f
    };
    
    GLushort indices[6] = {0, 1, 2, 1, 2, 3};

    glGenBuffers(ARRAY_SIZE(_vboIDArray), _vboIDArray);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vboIDArray[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * ARRAY_SIZE(vertexsPosition), vertexsPosition, GL_STATIC_DRAW);//flag @1
    
    glBindBuffer(GL_ARRAY_BUFFER, _vboIDArray[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * ARRAY_SIZE(texturePosition), texturePosition, GL_STATIC_DRAW);//flag @2

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIDArray[2]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * ARRAY_SIZE(indices), indices, GL_STATIC_DRAW);//flag @3
    
#if USE_VAO
    glGenVertexArrays(ARRAY_SIZE(_vaoIDArray), _vaoIDArray);
    glBindVertexArray(_vaoIDArray[0]);

    glBindBuffer(GL_ARRAY_BUFFER, _vboIDArray[0]);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);//最后一个参数在这里退化为 @1 中设置的 vertexs 偏移量

    glBindBuffer(GL_ARRAY_BUFFER, _vboIDArray[1]);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, 0);//最后一个参数在这里退化为 @2 中设置的 texturePosition 偏移量
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vboIDArray[2]);
    
    glBindVertexArray(0);
#endif
}

- (int)setupOpenGL {
    
    GLuint program = createProgram([self vertexShaderDesc], [self fragmentShaderDesc]);
    if (program) {
        glClearColor(0, 0, 0, 1);
        self.sample2DVarIndexY    = glGetUniformLocation(program, "uniform_textureIDY");
        self.sample2DVarIndexUV   = glGetUniformLocation(program, "uniform_textureIDUV");
    }
    
    return program;
}

// void bindFrameBuffer(int textureId, int frameBuffer, int width, int height) {
//
//    glBindTexture(GL_TEXTURE_2D, textureId);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
//                        GL_RGBA, GL_UNSIGNED_BYTE, NULL);
//    glTexParameterf(GL_TEXTURE_2D,
//                           GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D,
//                           GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameterf(GL_TEXTURE_2D,
//                           GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D,
//                           GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
//    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
//                                  GL_TEXTURE_2D,textureId, 0);
//
//    glBindTexture(GL_TEXTURE_2D, 0);
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
//}
//
//void initFrameBuffers(int width, int height) {
////    destroyFrameBuffers();
//
//    if (mFrameBuffers == null) {
//        mFrameBuffers = new int[2];
//        mFrameBufferTextures = new int[2];
//
//        glGenFramebuffers(2, mFrameBuffers, 0);
//        glGenTextures(2, mFrameBufferTextures, 0);
//
//        bindFrameBuffer(mFrameBufferTextures[0], mFrameBuffers[0], width, height);
//        bindFrameBuffer(mFrameBufferTextures[1], mFrameBuffers[1], width, height);
//    }
//}

- (void)setupSession {
    self.captureSession = [[HXAVCaptureSession alloc] initWithPreview:nil delegate:self pixelFormatType:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange preset:AVCaptureSessionPreset640x480 frameRate:25];
    self.captureSession.isNeedI420 = NO;
}

- (void)videoDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen width:(int)width height:(int)height {
    [self draw:pbuffer width:width height:height];
}

- (void)audioDataCallBack:(unsigned char *)pbuffer len:(int)bufferLen sampleRate:(int)sampleRate channel:(int)channel {
    
}

@end
