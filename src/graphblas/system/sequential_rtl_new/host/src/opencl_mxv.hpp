// Copyright (C) 2013-2016 Altera Corporation, San Jose, California, USA. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 
// This agreement shall be governed in all respects by the laws of the State of California and
// by the laws of the United States of America.

#ifndef __OPENCL_MXM_HPP__
#define __OPENCL_MXM_HPP__
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <typeinfo>

// ACL specific includes
#include "CL/opencl.h"
#include "AOCLUtils/aocl_utils.h"

#define CHECK(X) assert(CL_SUCCESS == (X))
#define NUM_KERNELS 3
//#define NUM_KERNELS 2
#define NLOCALSIZE 16
//static const char *kernel_name[] = { "spmv_kernel"};
static const char *kernel_name[] = { "spmv_kernel", "compute_kernel", "merge_kernel" };

// ACL runtime configuration
static cl_platform_id   platform;
static cl_device_id     device;
static cl_context       context;
static cl_command_queue queue;
static cl_kernel        kernel[NUM_KERNELS];
static cl_program       program;
static cl_int           status;
static cl_event         event[NUM_KERNELS];
static int              platform_initialized=0;


// MAxVX=VY
static cl_mem bufferVY;
static cl_mem bufferIA;
static cl_mem bufferJA;
static cl_mem bufferMA;
static cl_mem bufferVX;

static unsigned sizeVY   ;
static unsigned sizeIA  ;
static unsigned sizeJA  ;
static unsigned sizeMA   ;
static unsigned sizeVX   ;

static unsigned flagBufferVY   = CL_MEM_READ_WRITE;
static unsigned flagBufferIA   = CL_MEM_READ_ONLY;
static unsigned flagBufferJA   = CL_MEM_READ_ONLY;
static unsigned flagBufferMA   = CL_MEM_READ_ONLY;
static unsigned flagBufferVX   = CL_MEM_READ_ONLY;

static void dump_error(const char *str, cl_int status) {
  printf("%s\n", str);
  printf("Error code: %d\n", status);
}

float ocl_get_exec_time_ns(cl_event evt)
{
  cl_ulong kernelEventQueued;
  cl_ulong kernelEventSubmit;
  cl_ulong kernelEventStart;
  cl_ulong kernelEventEnd;
  clGetEventProfilingInfo(evt, CL_PROFILING_COMMAND_QUEUED, sizeof(unsigned long long), &kernelEventQueued, NULL);
  clGetEventProfilingInfo(evt, CL_PROFILING_COMMAND_SUBMIT, sizeof(unsigned long long), &kernelEventSubmit, NULL);
  clGetEventProfilingInfo(evt, CL_PROFILING_COMMAND_START, sizeof(unsigned long long), &kernelEventStart, NULL);
  clGetEventProfilingInfo(evt, CL_PROFILING_COMMAND_END, sizeof(unsigned long long), &kernelEventEnd, NULL);
  cl_ulong exectime_ns = kernelEventEnd-kernelEventQueued;
  return (float)exectime_ns;
}

// Get execution time between Queueing of first and ending of last
float ocl_get_exec_time2_ns(cl_event evt_first, cl_event evt_last)
{
  cl_ulong firstQueued;
  cl_ulong lastEnd;
  clGetEventProfilingInfo(evt_first, CL_PROFILING_COMMAND_QUEUED, sizeof(unsigned long long), &firstQueued, NULL);
  clGetEventProfilingInfo(evt_last, CL_PROFILING_COMMAND_END, sizeof(unsigned long long), &lastEnd, NULL);
  cl_ulong exectime_ns = lastEnd-firstQueued;
  return (float)exectime_ns;
}



static unsigned char *load_file(const char* filename,size_t*size_ret) {
   FILE* fp;
   int len;
   const size_t CHUNK_SIZE = 1000000;
   unsigned char *result;
   size_t r = 0;
   size_t w = 0;
   fp = fopen(filename,"rb");
   if ( !fp ) return 0;
   // Obtain file size.
   fseek(fp, 0, SEEK_END);
   len = ftell(fp);
   // Go to the beginning.
   fseek(fp, 0, SEEK_SET);
   // Allocate memory for the file data.
   result = (unsigned char*)malloc(len+CHUNK_SIZE);
   if ( !result )
   {
     fclose(fp);
     return 0;
   }
   // Read file.
   while ( 0 < (r=fread(result+w,1,CHUNK_SIZE,fp) ) )
   {
     w+=r;
   }
   fclose(fp);
   *size_ret = w;
   return result;
}


// free the resources allocated during initialization
static void freeResources() {
  for ( int k = 0; k < NUM_KERNELS; k++) 
  { 
  if(kernel[k]) 
    clReleaseKernel(kernel[k]);  
     if(event[k])
    clReleaseEvent(event[k]);
  }
  //if(program) 
  //  clReleaseProgram(program);
  //if(queue) 
  //  clReleaseCommandQueue(queue);
  if(bufferVY)    clReleaseMemObject(bufferVY);
  if(bufferIA)    {clReleaseMemObject(bufferIA); printf("==================bufferIA Released\n");}
  if(bufferJA)    clReleaseMemObject(bufferJA);
  if(bufferVX)    clReleaseMemObject(bufferVX);
  if(bufferMA)    clReleaseMemObject(bufferMA);
  //if(context) 
  //  clReleaseContext(context);
}

// Parsing and print device info
template <class paramTYPE>
bool queryDeviceInfo(cl_device_info param_name,cl_device_id cur_device, paramTYPE *param_value){
  size_t param_value_size;
  size_t * param_value_size_ret = (size_t *)malloc(sizeof(size_t *));
  param_value_size = sizeof(paramTYPE);
  status = clGetDeviceInfo(cur_device, param_name, param_value_size, (void *)param_value, param_value_size_ret);
  if(status != CL_SUCCESS){
    dump_error("Failed clGetDeviceInfo.", status);
    freeResources();
    return 1;
  }
  return 0;
}

bool set_args_merge(){
  status = clSetKernelArg(kernel[2], 0, sizeof(cl_mem), (void*)&bufferVY);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 2.", status);
    return 1;
  }

  uint NV = sizeVY;
  status = clSetKernelArg(kernel[2], 1, sizeof(uint), (void*)&NV);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 2.", status);
    return 1;
  }
}

bool set_args_compute(unsigned int xsize, unsigned int ysize, unsigned int nvals) {
  unsigned int ii;
  status = clSetKernelArg(kernel[1], 0, sizeof(cl_mem), (void*)&bufferVY);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 0.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[1], 1, sizeof(cl_mem), (void*)&bufferIA);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 1.", status);
    return 1;
  }
  
  status = clSetKernelArg(kernel[1], 2, sizeof(cl_mem), (void*)&bufferJA);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 2.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[1], 3, sizeof(cl_mem), (void*)&bufferVX);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 3.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[1], 4, sizeof(cl_mem), (void*)&bufferMA);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 4.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[1], 5, sizeof(uint), &xsize);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 5.", status);
    return 1;
  }
  status = clSetKernelArg(kernel[1], 6, sizeof(uint), &ysize);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 6.", status);
    return 1;
  }
  status = clSetKernelArg(kernel[1], 7, sizeof(uint), &nvals);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 7.", status);
    return 1;
  }

  return 0;
}

bool set_args_spmv(unsigned int xsize, unsigned int ysize, unsigned int nvals) {
  unsigned int ii;
  status = clSetKernelArg(kernel[0], 0, sizeof(cl_mem), (void*)&bufferVY);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 0.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[0], 1, sizeof(cl_mem), (void*)&bufferIA);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 1.", status);
    return 1;
  }
  
  status = clSetKernelArg(kernel[0], 2, sizeof(cl_mem), (void*)&bufferJA);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 2.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[0], 3, sizeof(cl_mem), (void*)&bufferVX);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 3.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[0], 4, sizeof(cl_mem), (void*)&bufferMA);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 4.", status);
    return 1;
  }

  status = clSetKernelArg(kernel[0], 5, sizeof(uint), &xsize);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 5.", status);
    return 1;
  }
  status = clSetKernelArg(kernel[0], 6, sizeof(uint), &ysize);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 6.", status);
    return 1;
  }
  status = clSetKernelArg(kernel[0], 7, sizeof(uint), &nvals);
  if(status != CL_SUCCESS) {
    dump_error("Failed set arg 7.", status);
    return 1;
  }

  return 0;
}

template <class HOST_TYPE, class ScalarType>
bool init_platform(
             char * aocx_name
             ) {
  cl_uint num_platforms;
  cl_uint num_devices;
  // get the platform ID
  status = clGetPlatformIDs(1, &platform, &num_platforms);
  if(status != CL_SUCCESS) {
    dump_error("Failed clGetPlatformIDs.", status);
    freeResources();
    return 1;
  }

  if(num_platforms != 1) {
    printf("Found %d platforms!\n", num_platforms);
    freeResources();
    return 1;
  }

  // get the device ID
  status = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 1, &device, &num_devices);
  if(status != CL_SUCCESS) {
    dump_error("Failed clGetDeviceIDs.", status);
    freeResources();
    return 1;
  }
  if(num_devices != 1) {
    printf("Found %d devices!\n", num_devices);
  }

  // Parsing and print device info
  cl_device_info param_name;
  size_t param_value_size;
  cl_device_type  param_value;
  status = queryDeviceInfo<cl_device_type>(CL_DEVICE_TYPE, device, &param_value);
  if(status != CL_SUCCESS){
    dump_error("Failed clGetDeviceInfo.", status);
    freeResources();
    return 1;
  }
  else{
    switch(param_value) {
    case CL_DEVICE_TYPE_CPU :{
      printf("CL_DEVICE_TYPE is CL_DEVICE_TYPE_CPU\n"); break;
    }
    case CL_DEVICE_TYPE_ACCELERATOR :{
      printf("CL_DEVICE_TYPE is CL_DEVICE_TYPE_ACCELERATOR\n");break;
    }
    default:{
      printf("CL_DEVICE_TYPE is OTHERS\n");break;
    }
    }
  }
  // create a context
  context = clCreateContext(0, 1, &device, NULL, NULL, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateContext.", status);
    freeResources();
    return false;
  }
  // create a command queue
  queue = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateCommandQueue.", status);
    freeResources();
    return false;
  }
  const unsigned char* my_binary;
  size_t my_binary_len = 0;
  cl_int bin_status = 0;

//  char *aocx_name = "example2.aocx";
  printf ("Loading %s ...\n", aocx_name);
  my_binary = load_file (aocx_name, &my_binary_len); 

  if ((my_binary == 0) || (my_binary_len == 0)) { 
   printf("Error: unable to read %s into memory or the file was not found!\n", aocx_name);
   exit(-1);
  }

  program = clCreateProgramWithBinary (context, 1, &device, &my_binary_len, &my_binary, &bin_status, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateProgramWithBinary.", status);
    freeResources();
    return false;
  }  
  
  // build the program
  status = clBuildProgram(program, 0, NULL, "", NULL, NULL);
  if(status != CL_SUCCESS) {
    dump_error("Failed clBuildProgram.", status);
    freeResources();
    return false;
  }
  return true;
    
}

template <class HOST_TYPE, class ScalarType, class IndexType>
bool runtest(IndexType *pIA, IndexType *pJA, ScalarType *pMA, ScalarType * pVX, unsigned int sizex, unsigned int sizey,unsigned int nvals,ScalarType * pVY, char* aocx_name){

  if(platform_initialized == 0){
  //if(1){
    status = init_platform<HOST_TYPE, ScalarType>(aocx_name);
    if(status == false){
        dump_error("Failed to initialize platform.",status);
    }
    else{
    platform_initialized = 1;
    }
  }


  // create the input buffer
  bufferIA= clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * sizeIA, NULL, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateBufferIA.", status);
    freeResources();
    return false;
  }

  bufferVY= clCreateBuffer(context, flagBufferVY, sizeof(ScalarType) * sizeVY, NULL, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateBufferVY.", status);
    freeResources();
    return false;
  }
    

  bufferJA= clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * sizeJA, NULL, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateBufferJA.", status);
    freeResources();
    return false;
  }

  bufferMA= clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(ScalarType) * sizeMA, NULL, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateBufferMA.", status);
    freeResources();
    return false;
  }
    
  bufferVX= clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(ScalarType) * sizeVX, NULL, &status);
  if(status != CL_SUCCESS) {
    dump_error("Failed clCreateBufferVX.", status);
    freeResources();
    return false;
  }

  status = clEnqueueWriteBuffer(queue, bufferVY, CL_FALSE, 0, sizeof(ScalarType) * sizeVY, pVY, 0, NULL, NULL);
  if(status != CL_SUCCESS) {
    dump_error("Failed to enqueue write buffer bufferVY.", status);
    freeResources();
    return false;
  }
    
  status = clEnqueueWriteBuffer(queue, bufferIA, CL_FALSE, 0, sizeof(cl_uint) * sizeIA, pIA, 0, NULL, NULL);
  if(status != CL_SUCCESS) {
    dump_error("Failed to enqueue write buffer bufferIA.", status);
    freeResources();
    return false;
  }

  status = clEnqueueWriteBuffer(queue, bufferJA, CL_FALSE, 0, sizeof(cl_uint) * sizeJA, pJA, 0, NULL, NULL);
  if(status != CL_SUCCESS) {
    dump_error("Failed to enqueue write buffer bufferJA.", status);
    freeResources();
    return false;
  }

  status = clEnqueueWriteBuffer(queue, bufferMA, CL_FALSE, 0, sizeof(ScalarType) * sizeMA, pMA, 0, NULL, NULL);
  if(status != CL_SUCCESS) {
    dump_error("Failed to enqueue write buffer bufferMA.", status);
    freeResources();
    return false;
  }

  status = clEnqueueWriteBuffer(queue, bufferVX, CL_FALSE, 0, sizeof(ScalarType) * sizeVX, pVX, 0, NULL, NULL);
  if(status != CL_SUCCESS) {
    dump_error("Failed to enqueue write buffer bufferVX.", status);
    freeResources();
    return false;
  }

  // create the kernel
    const size_t local_size0[2]  = {1, 1};
    const size_t global_size0[2] = {1,1};
    const size_t local_size1[2]  = {1, 1};
    const size_t global_size1[2] = {1, 1};
 for ( int k = 0; k < NUM_KERNELS; k++)
  {

    kernel[k] = clCreateKernel(program, kernel_name[k], &status);
    if(status != CL_SUCCESS) {
      dump_error("Failed clCreateKernel.", status);
      freeResources();
      return 1;
    }
    else{
      printf("kernel[%d] is created.\n", k);
    }

    if (strcmp(kernel_name[k],"spmv_kernel") == 0)
    {
      set_args_spmv(sizeVX, sizeVY, sizeMA);
    }
    if (strcmp(kernel_name[k],"compute_kernel") == 0)
    {
      set_args_compute(sizeVX, sizeVY, sizeMA);
    }
    if (strcmp(kernel_name[k],"merge_kernel") == 0)
    {
      set_args_merge();
    }

    printf("i am here hehe\n");
    cl_uint work_dim;
//    if(k==0)status = clEnqueueTask(queue, kernel[0],  1, NULL, NULL);
    //if(k==0)status = clEnqueueTask(queue, kernel[0],  1, NULL, &event[k]);
    if(k==0)status = clEnqueueNDRangeKernel(queue, kernel[0], 2, NULL, (const size_t*)&global_size0, (const size_t*)&local_size0, 0, NULL, &event[k]);
    if(k==1)status = clEnqueueNDRangeKernel(queue, kernel[1], 2, NULL, (const size_t*)&global_size0, (const size_t*)&local_size0, 0, NULL, &event[k]);

    if(k==2)status = clEnqueueNDRangeKernel(queue, kernel[2], 2, NULL, (const size_t*)&global_size1, (const size_t*)&local_size1, 0, NULL, &event[k]);

    
    if (status != CL_SUCCESS) {
      dump_error("Failed to launch kernel.", status);
      freeResources();
      return 1;
    }
  }
   
  printf("  ... Waiting for spmv \n");
  clWaitForEvents( 1, &event[0] );
  printf("  Event done!\n");
 float time_ns = ocl_get_exec_time_ns(event[0]);
  

 printf("  Sender sent the token to receiver\n");
 printf("  ... Waiting for merge\n");
 clWaitForEvents( 1, &event[2] );

  clFinish(queue);
    
  printf("Kernel execution is complete. Execution time is %f ns\n", time_ns);

  status = clEnqueueReadBuffer(queue, bufferVY, CL_TRUE, 0, sizeof(ScalarType) * sizeVY, pVY, 0, NULL, NULL);
  printf("  Buffer read done!\n");
  if(status != CL_SUCCESS) {
    dump_error("Failed to enqueue read buffer bufferVY.", status);
    freeResources();
    return false;
  }

    
  // free the resources allocated
  freeResources();

  return true;
}


template <class IndexType, class ScalarType>
int opencl_mxv(IndexType *pIA, IndexType *pJA, ScalarType *pMA, ScalarType * pVX, unsigned int sizex, unsigned int sizey,unsigned int nvals,ScalarType * pVY, char * aocx_name){

  sizeVY   = sizey;
  printf("sizeVY is %d\n",sizeVY);
  sizeIA   = sizex+ 1;
  sizeJA   = nvals;
  sizeMA   = nvals;
  sizeVX   = sizex;
  
  bool success = false;
  success = runtest<cl_int, ScalarType, IndexType> (pIA, pJA, pMA, pVX, sizex, sizey,nvals,pVY, aocx_name);

  if(success == false) { 
      printf("FAILED\n");
      return -1;
  }

  printf("opencl_mxv done\n");
  
  return 0xdead;
}

// Needed to be defined by aocl_utils
void cleanup() { freeResources(); }
#endif
