#
# Copyright (c) 2017 Carnegie Mellon University.
# All Rights Reserved.
#
# THIS SOFTWARE IS PROVIDED "AS IS," WITH NO WARRANTIES WHATSOEVER. CARNEGIE
# MELLON UNIVERSITY EXPRESSLY DISCLAIMS TO THE FULLEST EXTENT PERMITTED BY
# LAW ALL EXPRESS, IMPLIED, AND STATUTORY WARRANTIES, INCLUDING, WITHOUT
# LIMITATION, THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE, AND NON-INFRINGEMENT OF PROPRIETARY RIGHTS.
#
# This Program is distributed under a BSD license.  Please see LICENSE file or
# permission@sei.cmu.edu for more information.  DM-0002659
#

cmake_minimum_required(VERSION 2.8)

#find_package(OpenCL )

find_program(CMAKE_C_COMPILER NAMES $ENV{CC} gcc PATHS ENV PATH NO_DEFAULT_PATH)
find_program(CMAKE_CXX_COMPILER NAMES $ENV{CXX} g++ PATHS ENV PATH NO_DEFAULT_PATH)

project(SPIRALGRAPH)

# https://stackoverflow.com/questions/14306642/adding-multiple-executables-in-cmake

# For debugging
#message("CMake SRC: ${CMAKE_SOURCE_DIR}")
#message("Project Name: ${PROJECT_NAME}")
#message("Bin Directory: ${CMAKE_BINARY_DIR}")
#message("Project Name: ${CMAKE_SOURCE_DIR}")
#message("PProject Bin Directory: ${PROJECT_BINARY_DIR}")

# This seems hokey that we need to include the root as our directory
include_directories(${CMAKE_SOURCE_DIR} $ENV{ALTERAOCLSDKROOT}/host/include ${CMAKE_SOURCE_DIR}/graphblas/system/sequential/common/inc)

set(CMAKE_CXX_STANDARD 11)

#set link directories
link_directories($ENV{ALTERAOCLSDKROOT}/board/nalla_pcie/linux64/lib $ENV{ALTERAOCLSDKROOT}/host/linux64/lib)
# Compiler flags
#set(CMAKE_STATIC_LINKER_FLAGS "-fPIC -Wl,--no-as-needed -lalteracl -lnalla_pcie_mmd -lelf  -lrt -lpthread -L/afs/ece.cmu.edu/usr/jingh1 -lopenclgraph")
#set(CMAKE_SHARED_LINKER_FLAGS "-fPIC -I/afs/ece.cmu.edu/usr/jingh1/exm_opencl_matrix_mult/matrix_mult/host/inc -I/afs/ece.cmu.edu/usr/jingh1/exm_opencl_matrix_mult/common/inc -I/afs/ece.cmu.edu/usr/jingh1/edatools/intelFPGA_pro_17.0.0/hld/host/include -L/afs/ece.cmu.edu/usr/jingh1/edatools/intelFPGA_pro_17.0.0/hld/board/nalla_pcie/linux64/lib -L/afs/ece.cmu.edu/usr/jingh1/edatools/intelFPGA_pro_17.0.0/hld/host/linux64/lib -Wl,--no-as-needed -lalteracl -lnalla_pcie_mmd -lelf  -lrt -lpthread -L/afs/ece.cmu.edu/usr/jingh1 -lopenclgraph")


# Build a list of all the graphblas headers.
file(GLOB GRAPHBLAS_HEADERS graphblas/*.hpp)

# Build tests and demos into a separate bin directory so it doesn't get mixed in
# with settings and config files. Note the library dependency is not in here.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

add_library(openclgraph ${CMAKE_SOURCE_DIR}/graphblas/system/sequential/common/src/AOCLUtils/opencl.cpp  ${CMAKE_SOURCE_DIR}/graphblas/system/sequential/common/src/AOCLUtils/options.cpp)
target_link_libraries(openclgraph elf rt pthread alteracl nalla_pcie_mmd)
target_compile_options(openclgraph PRIVATE -fPIC -Wl,--no-as--needed)

### Make basic tests
file( GLOB TEST_SOURCES LIST_DIRECTORIES false ${CMAKE_SOURCE_DIR}/test/*.cpp )
foreach( testsourcefile ${TEST_SOURCES} )
    get_filename_component(justname ${testsourcefile} NAME)
    string( REPLACE ".cpp" "" testname ${justname} )
    message("Adding: ${testname}")
    add_executable( ${testname} ${testsourcefile} ${GRAPHBLAS_HEADERS} )
    #target_link_libraries(${testname} ${CMAKE_SOURCE_DIR}/graphblas/system/sequential/openclgraph.a elf rt pthread alteracl)
    target_link_libraries(${testname} openclgraph )
endforeach( testsourcefile ${TEST_SOURCES} )

###HJHJ### Make extra sequential tests
###HJHJfile( GLOB TEST_SOURCES LIST_DIRECTORIES false ${CMAKE_SOURCE_DIR}/test/sequential/*.cpp )
###HJHJforeach( testsourcefile ${TEST_SOURCES} )
###HJHJ    get_filename_component(justname ${testsourcefile} NAME)
###HJHJ    string( REPLACE ".cpp" "" testname ${justname} )
###HJHJ    message("Adding: ${testname}_sequential ")
###HJHJ    add_executable( ${testname}_sequential ${testsourcefile} ${GRAPHBLAS_HEADERS})
###HJHJ    target_link_libraries(${testname}_sequential openclgraph)
###HJHJendforeach( testsourcefile ${TEST_SOURCES} )

## Make demos
file( GLOB TEST_SOURCES LIST_DIRECTORIES false ${CMAKE_SOURCE_DIR}/demo/*.cpp )
foreach( testsourcefile ${TEST_SOURCES} )
    get_filename_component(justname ${testsourcefile} NAME)
    string( REPLACE ".cpp" "" testname ${justname} )
    message("Adding: ${testname}")
    add_executable( ${testname} ${testsourcefile} ${GRAPHBLAS_HEADERS})
    target_link_libraries(${testname} openclgraph)
endforeach( testsourcefile ${TEST_SOURCES} )

option(OC_EMU  "Option OpenCL EMU"  ON)
option(OC_FPGA "Option OpenCL FPGA" OFF)
if(OC_EMU)
file( GLOB DEVICE_OC_SOURCES LIST_DIRECTORIES false ${CMAKE_SOURCE_DIR}/graphblas/system/sequential/device/*.cl)
foreach( testsourcefile ${DEVICE_OC_SOURCES} )
    get_filename_component(justname ${testsourcefile} NAME)
    string( REPLACE ".cl" "_emu.aocx" testname ${justname} )
    message("Adding: ${testname}")
    add_custom_command( OUTPUT ${testname}
                    COMMAND aoc -march=emulator -v --board p510t_sch_ax115 ${testsourcefile} --seed 1  --no-interleaving default --fpc --fp-relaxed -o ${testname}
                    DEPENDS ${testsourcefile} )
    add_custom_target( ${testname}.target ALL DEPENDS ${testsourcefile}  ${testname} )
endforeach( testsourcefile ${DEVICE_OC_SOURCES} )
endif(OC_EMU)

if(OC_FPGA)
file( GLOB DEVICE_OC_SOURCES LIST_DIRECTORIES false ${CMAKE_SOURCE_DIR}/graphblas/system/sequential/device/*.cl)
foreach( testsourcefile ${DEVICE_OC_SOURCES} )
    get_filename_component(justname ${testsourcefile} NAME)
    string( REPLACE ".cl" "_fpga.aocx" testname ${justname} )
    message("Adding: ${testname}")
    add_custom_command( OUTPUT ${testname}
                    COMMAND aoc --profile ${testsourcefile} -v --board p510t_sch_ax115  --seed 1  --no-interleaving default --fpc --fp-relaxed -o ${testname}
                    DEPENDS ${testsourcefile} )
    add_custom_target( ${testname}.target ALL DEPENDS ${testsourcefile}  ${testname} )
endforeach( testsourcefile ${DEVICE_OC_SOURCES} )
endif(OC_FPGA)
# TODO: Make capi tests
#add_executable(bcc_demo capi/bcc_demo.c capi/bcc.c capi/bcc.h ${GRAPHBLAS} capi/graphblas.cpp capi/TypeAdapter.hpp capi/UnaryAdapter.hpp capi/graphblas_private.h capi/BinaryAdapter.xhpp capi/TypeUnion.hpp capi/SemiringAdapter.hpp capi/FunctionInvocation.cpp capi/FunctionInvocation.h capi/MonoidAdapter.hpp)
