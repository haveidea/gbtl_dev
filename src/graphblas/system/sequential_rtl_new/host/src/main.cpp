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


#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
#include <unistd.h>
#include <string.h>
#include <vector>


// ACL specific includes
#include "CL/opencl.h"
#include "AOCLUtils/aocl_utils.h"
#include "opencl_mxv.hpp"

#define CHECK(X) assert(CL_SUCCESS == (X))
typedef struct {
   unsigned int col_index;
   float        value;
} row_item;

int main(int argc, char* argv[]){
    unsigned int  sizex = 16  ; //
    unsigned int  sizey = 16  ; //
    float         rate  = 0.5 ; // zero rate

    int c;
    opterr = 0;
    char * filename =(char *)malloc(sizeof(char)*256);
    strcpy(filename,"example2.aocx");

    while((c = getopt(argc, argv, "x:y:r:f:h"))!=-1){
        switch(c){
            case 'x': sizex    = atoi(optarg); break;
            case 'y': sizey    = atoi(optarg); break;
            case 'r': rate     = atof(optarg); if(rate >= 1) {printf("Error: Zero rate should be less than 1.\n");exit(0);} break;
            case 'f': filename = strcpy(filename, optarg); break;
            case 'h': printf("argv[0] -x SIZEX -y SIZEY -r ZERO_PERCENT -f FILE.aocx\n");exit(0);break;
        }
    }

    printf("argument is %d %d %f %s\n", sizex, sizey, rate, filename);

    std::vector <row_item> * matrix;
    bool           is_none_zero;

    matrix = (std::vector <row_item> *)malloc(sizey * sizeof(std::vector <row_item> ));

    row_item * cur_item;
    for (int ii = 0; ii <sizex; ii++){
      for (int jj = 0; jj < sizey; jj++){
          if((1.0* rand()/RAND_MAX )< rate) {
              is_none_zero = true;
              cur_item = (row_item *) malloc(sizeof(row_item));
              cur_item->col_index = ii;
              cur_item->value = 1.0 * rand()/RAND_MAX; 
              matrix[jj].push_back(*cur_item);
          } 
      }
    }
    unsigned int sizema = 0;
    for (int jj = 0; jj < sizey; jj++){
      sizema += matrix[jj].size();
    }
    unsigned int   * IA    = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*(sizey+1));
    unsigned int   * JA    = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*sizema);
    float * MA    = (float*)aocl_utils::alignedMalloc(sizeof(float)*sizema);
    float * VX    = (float*)aocl_utils::alignedMalloc(sizeof(float)*sizex);
    float * VY    = (float*)aocl_utils::alignedMalloc(sizeof(float)*sizey);


    IA[0] = 0;
    int index = 0;
    for(int jj = 0; jj < sizey; jj++){
      for (int ii = 0; ii < matrix[jj].size(); ii++){
          JA[index] = matrix[jj][ii].col_index;
          MA[index] = matrix[jj][ii].value;
          index ++;
      }
      IA[jj+1] = index;
    }

    for (int jj = 0; jj <sizex; jj++){
        VX[jj] = 1.0;
    }

//    float * VY  = (float*)aocl_utils::alignedMalloc(sizeof(float)*sizevy);
//
//    unsigned int * VYOFF = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*(nblky+1));
//    unsigned int * VY_end    = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*nblky);
//
//    unsigned int * IAOFF = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*(sizeiaoff+1));
//    unsigned int * JAOFF = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*(sizejaoff+1));
//    unsigned int * MAOFF = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*(sizemaoff+1));
//    unsigned int * VXOFF = (unsigned int*)aocl_utils::alignedMalloc(sizeof(unsigned int)*(sizevxoff+1));
//
//    for (unsigned int ii = 0; ii <= nblky; ii++){
//        VYOFF [ii]   = ii * sizen;
//    }
//
//    for (int ii = 0; ii< sizevx; ii++){
//        VX[ii] =1.0 ;
//    }
//
//    for (int ii = 0; ii< sizema; ii++){
//        MA[ii]=1.0;
//    }
//
//    unsigned int ja_index = 0;
//    unsigned int ia_index = 0;
//    for (int jj = 0; jj< nblky; jj++){
//        for (int ii = 0; ii< nblkx; ii++){
//            if(1){
//                for(int kk = 0; kk<sizen; kk++){
//                    JA[ja_index] = kk;
//                    ja_index ++;
//                }
//                for(int kk = 0; kk <sizen+1; kk++){
//                    IA[ia_index] = kk;
//                    ia_index++;
//                }
//            }
//            else {
//                for(int kk = 0; kk <sizen+1; kk++){
//                    IA[ia_index] = 0;
//                    ia_index++;
//                }
//            }
//        }
//    }
//
//    unsigned int IAOFF_index = 0;
//    unsigned int JAOFF_index = 0;
//    unsigned int MAOFF_index = 0;
//    unsigned int VXOFF_index = 0;
//    for (int ii = 0; ii<= nblkx; ii++){
//        VXOFF[ii]   = ii * sizen;
//    }
//
//    for (int ii = 0; ii< nblky; ii++){
//        for (int jj = 0; jj< nblkx; jj++){
//            MAOFF[ii*nblkx+jj] = MAOFF_index;
//            if(1){
//                MAOFF_index += sizen;
//            }
//            printf("ii is %d, jj is %d, nblkx is %d, sizen is %d, index is : %d, MAOFF is %d\n",ii, jj, nblkx, sizen, jj * nblkx+ii, MAOFF[jj*nblkx+ii] );
//        }
//    }
//    MAOFF[nblkx * nblky ] = MAOFF_index;
//
//    printf("main : sizen is %d\n",sizen);
//    printf("main : MAOFF[0] is %d\n",MAOFF[0]);
//    printf("main : MAOFF[1] is %d\n",MAOFF[1]);
//    printf("main : MAOFF[2] is %d\n",MAOFF[2]);
//    printf("main : MAOFF[3] is %d\n",MAOFF[3]);
//    printf("main : MAOFF[4] is %d\n",MAOFF[4]);
//
//    for (int jj = 0; jj< nblky; jj++){
//        for (int ii = 0; ii< nblkx; ii++){
//            JAOFF[jj*nblkx+ii] = JAOFF_index;
//            if(1){
//                JAOFF_index += sizen;
//            }
//        }
//    }
//    JAOFF[nblkx*nblky] = JAOFF_index;
//    for (int jj = 0; jj< nblky; jj++){
//        for (int ii = 0; ii< nblkx; ii++){
//            IAOFF[jj*nblkx+ii] = IAOFF_index;
//            IAOFF_index += sizen+1;
//        }
//    }
//    IAOFF[nblkx*nblky] = IAOFF_index;
//
  
   int  return_val=opencl_mxv<unsigned int, float> (IA, JA, MA, VX, sizex, sizey, sizema, VY, filename);
//
//    for (int ii = 0; ii < m; ii++){
//        printf("VY[%d]: %f\n", ii,VY[ii]);
//    }
//
//    aocl_utils::alignedFree(    MA    );
//    aocl_utils::alignedFree(    VX    );
//    aocl_utils::alignedFree(    VY    );
//    aocl_utils::alignedFree(    IA    );
//    aocl_utils::alignedFree(    JA    );
//    aocl_utils::alignedFree(    IAOFF );
//    aocl_utils::alignedFree(    JAOFF );
//    aocl_utils::alignedFree(    MAOFF );
//    aocl_utils::alignedFree(    VXOFF );
//    printf("Exit normally\n");

}
