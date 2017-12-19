//
//  OpenGLUtil.h
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/18.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#ifndef OpenGLUtil_h
#define OpenGLUtil_h

#include <stdio.h>
#include <OpenGLES/ES3/gl.h>

typedef struct UserContext UserContext;

struct UserContext {
    GLuint  program;
    void    *userData;
};

GLvoid alertError(const char* err);
GLuint loaderShader(const char* strShaderDesc, GLenum shaderType);
GLuint createProgram(const char* strVertexDesc, const char* strFragmentDesc);

#endif /* OpenGLUtil_h */
