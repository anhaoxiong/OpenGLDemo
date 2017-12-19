//
//  RGB24ImageViewController.m
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/18.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#import "RGB24ImageViewController.h"

@interface RGB24ImageViewController ()
{
    GLuint _textureIDArray[1];
}
@property (nonatomic)GLuint program;
@property (nonatomic)int sampleVarIndex;
@property (nonatomic, strong) NSData *fileData;
@end

@implementation RGB24ImageViewController

- (void)dealloc {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

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
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self draw];
}

- (void)rightItemClick {
    [super rightItemClick];
    [self draw];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        "   out_color = texture(uniform_textureID, v2f_textCoor);\n"
        "}"
    };
    
    return str;
}


- (void)draw {
    
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

    static GLushort indices[6] = {0, 1, 2, 1, 2, 3};
    
    GLint width = 480;
    GLint height = 288;
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"rgb24"];
    NSData* data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, [data bytes]);

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
    glBindTexture(GL_TEXTURE_2D, _textureIDArray[0]);
    glUniform1i(self.sampleVarIndex, 0);

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
    
    [self.drawView display];
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
        self.sampleVarIndex = glGetUniformLocation(program, "uniform_textureID");
    }
    return program;
}

@end
