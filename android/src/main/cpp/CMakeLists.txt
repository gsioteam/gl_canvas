cmake_minimum_required(VERSION 3.5)

set(CMAKE_CXX_STANDARD 14)

project(gl_canvas)

set(
        SRC 

        gl_canvas.cpp)


add_library(
        gl_canvas
        SHARED

        ${SRC}
)

target_link_libraries(
        gl_canvas

        EGL
        GLESv2
        GLESv1_CM
        android
        log
)