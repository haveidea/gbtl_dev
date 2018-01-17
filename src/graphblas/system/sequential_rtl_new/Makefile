# Copyright (C) 2013-2016 Altera Corporation, San Jose, California, USA. All rights reserved.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
# whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# This agreement shall be governed in all respects by the laws of the State of California and
# by the laws of the United States of America.
# This is a GNU Makefile.

# You must configure ALTERAOCLSDKROOT to point the root directory of the Intel(R) FPGA SDK for OpenCL(TM)
# software installation.
# See http://www.altera.com/literature/hb/opencl-sdk/aocl_getting_started.pdf 
# for more information on installing and configuring the Intel(R) FPGA SDK for OpenCL(TM).

ifeq ($(VERBOSE),1)
ECHO := 
else
ECHO := @
endif

# Where is the Intel(R) FPGA SDK for OpenCL(TM) software?
ifeq ($(wildcard $(ALTERAOCLSDKROOT)),)
$(error Set ALTERAOCLSDKROOT to the root directory of the Intel(R) FPGA SDK for OpenCL(TM) software installation)
endif
ifeq ($(wildcard $(ALTERAOCLSDKROOT)/host/include/CL/opencl.h),)
$(error Set ALTERAOCLSDKROOT to the root directory of the Intel(R) FPGA SDK for OpenCL(TM) software installation.)
endif

# OpenCL compile and link flags.
AOCL_COMPILE_CONFIG := $(shell aocl compile-config )
AOCL_LINK_CONFIG := $(shell aocl link-config )

# Compilation flags
ifeq ($(DEBUG),1)
CXXFLAGS += -g
else
CXXFLAGS += -O2
endif

# Compiler
CXX := g++

# Target
TARGET := host
TARGET_DIR := bin

# Directories
INC_DIRS := ../common/inc
LIB_DIRS := 
OBJS_DIR := objs

# Files
vpath %.cpp ../host/src ../common/src/AOCLUtils 
vpath %.o   ./objs
INCS := $(wildcard )
SRCS := $(wildcard ../host/src/*.cpp ../common/src/AOCLUtils/*.cpp)
OBJS :=$(patsubst %.cpp, ${OBJS_DIR}/%.o,$(notdir ${SRCS}))
#OBJS :=$(patsubst %.cpp, objs/%.o,${SRCS})
LIBS := rt pthread
DATE = $(shell date  +_%y_%m_%d_%H)

# Make it all!
all : ${TARGET_DIR} $(TARGET_DIR)/$(TARGET)

# Host executable target.
$(TARGET_DIR)/$(TARGET) : ${OBJS} 
	$(ECHO)$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fPIC $(foreach D,$(INC_DIRS),-I$D) \
			$(AOCL_COMPILE_CONFIG) $(AOCL_LINK_CONFIG) \
			$(foreach D,$(LIB_DIRS),-L$D) \
			$(foreach L,$(LIBS),-l$L) ${OBJS} -o bin/host

${OBJS}:${OBJS_DIR}

${OBJS}:objs/%.o:%.cpp 
	$(ECHO)$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fPIC $(foreach D,$(INC_DIRS),-I$D) \
			$(AOCL_COMPILE_CONFIG) $< $(AOCL_LINK_CONFIG) \
			$(foreach D,$(LIB_DIRS),-L$D) \
			$(foreach L,$(LIBS),-l$L) \
			-c -o $@
	
${OBJS_DIR}:
	$(ECHO)mkdir -p $(OBJS_DIR)

$(TARGET_DIR) :
	$(ECHO)mkdir -p $(TARGET_DIR)
	
# Standard make targets
clean :
	$(ECHO)rm -f $(TARGET_DIR)/$(TARGET) ${OBJS_DIR}; rm -rf *.o

lib:
	ar rcs libopenclgraph.a ${OBJS_DIR}/opencl.o  ${OBJS_DIR}/options.o 
	#ar rcs libopenclgraph.a opencl_mxv.o opencl.o  options.o 

OPENCL_OPTIONS += --seed 1
#OPENCL_OPTIONS += --no-interleaving default
OPENCL_OPTIONS += --fpc --fp-relaxed
OPENCL_OPTIONS += -v
OPENCL_OPTIONS += --report
OPENCL_OPTIONS += --board p510t_sch_ax115
OPENCL_OPTIONS += --const-cache-bytes 65536
CL_NAME   = example2
TARGET_AOCX = example2
SYN_DIR=syn
DEVICE_DIR=../device

fpga_lib:
	${ECHO}mkdir -p ${SYN_DIR}/${CL_NAME}_lib; pushd ${SYN_DIR}/${CL_NAME}_lib; \
  cp -rf ../../${DEVICE_DIR}/lib/* .; \
	aocl library hdl-comp-pkg spmv/rtl_spec.xml -o spmv.aoco;\
	aocl library create -name mem_users spmv.aoco;\
	popd;
	
emu: fpga_lib
	${ECHO}mkdir -p ${SYN_DIR}/${CL_NAME}_emu${DATE}; pushd ${SYN_DIR}/${CL_NAME}_emu${DATE}; \
	aoc -march=emulator ../../${DEVICE_DIR}/${CL_NAME}.cl -o ${CL_NAME}_emu${DATE}.aocx -I ../${CL_NAME}_lib/ -L device -l ../${CL_NAME}_lib/mem_users.aoclib ${OPENCL_OPTIONS} -DDBG ; \
	popd; ln -snf ${SYN_DIR}/${CL_NAME}_emu${DATE}/${CL_NAME}_emu${DATE}.aocx ${TARGET_AOCX}.aocx

fpga: fpga_lib
	${ECHO}mkdir -p ${SYN_DIR}/${CL_NAME}_fpga${DATE}; pushd ${SYN_DIR}/${CL_NAME}_fpga${DATE}; \
	aoc ../../${DEVICE_DIR}/${CL_NAME}.cl -o ${CL_NAME}_emu${DATE}.aocx -I ../${CL_NAME}_lib -L device -l ../${CL_NAME}_lib/mem_users.aoclib --profile ${OPENCL_OPTIONS}; \
	cp ${CL_NAME}_fpga${DATE}.aocx ../../${TARGET_AOCX}.aocx;ln -snf ../${CL_NAME}_fpga${DATE}.source ../../${TARGET_AOCX}.source;  popd 

profile:
	aocl report example2.aocx profile.mon example2.source



.PHONY : all clean host
