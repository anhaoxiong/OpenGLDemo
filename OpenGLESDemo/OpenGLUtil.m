//
//  OpenGLUtil.c
//  OpenGLESDemo
//
//  Created by hxiongan on 2017/12/18.
//  Copyright © 2017年 hxiongan. All rights reserved.
//

#include "OpenGLUtil.h"
#import <UIKit/UIKit.h>

GLvoid alertError(const char* err) {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:[NSString stringWithUTF8String:err] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

GLuint loaderShader(const char* strShaderDesc, GLenum shaderType) {
    
    GLuint shader    = 0;
    GLint compiled   = 0;
    
    shader = glCreateShader(shaderType);
    if (0 == shader) {
        return 0;
    }
    
    glShaderSource(shader, 1, &strShaderDesc, NULL);
    glCompileShader(shader);
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 0) {
            char* info = malloc(infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, info);
            alertError(info);
            free(info);
        }
        glDeleteShader(shader);
        shader = 0;
    }
    
    return shader;
}

GLuint createProgram(const char* strVertexDesc, const char* strFragmentDesc) {
    
    if (!(strVertexDesc && strFragmentDesc)) return 0;
    
    Boolean bSucceed = false;
    
    GLuint program          = 0;
    GLuint vertexShader     = 0;
    GLuint fragmentShader   = 0;
    GLint linked            = 0;
    
    do {
        vertexShader = loaderShader(strVertexDesc, GL_VERTEX_SHADER);
        if (!vertexShader) break;
        
        fragmentShader = loaderShader(strFragmentDesc, GL_FRAGMENT_SHADER);
        if (!fragmentShader) break;
        
        program = glCreateProgram();
        if (!program) break;
        
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
        glLinkProgram(program);
        
        glGetProgramiv(program, GL_LINK_STATUS, &linked);
        if (!linked) {
            GLint infoLen = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen > 0) {
                char* info = malloc(infoLen);
                glGetProgramInfoLog(program, infoLen, NULL, info);
                alertError(info);
                free(info);
            }
            break;
        }
        
        bSucceed = true;
        
    } while (0);
    
    if (!bSucceed) {
        if (vertexShader) {
            glDeleteShader(vertexShader);
        }
        if (fragmentShader) {
            glDeleteShader(fragmentShader);
        }
        if (program) {
            glDeleteProgram(program);
        }
        program = 0;
    }
    
    return program;
}
