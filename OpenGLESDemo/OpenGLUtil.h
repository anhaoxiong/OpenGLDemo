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

#define SHADER_STRING(x) #x
#define ARRAY_SIZE(array) sizeof((array))/sizeof((array[0]))

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }
#endif

GLvoid alertError(const char* err);
GLuint loaderShader(const char* strShaderDesc, GLenum shaderType);
GLuint createProgram(const char* strVertexDesc, const char* strFragmentDesc);

#endif /* OpenGLUtil_h */
