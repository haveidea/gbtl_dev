/*
 * Copyright (c) 2017 Carnegie Mellon University.
 * All Rights Reserved.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS," WITH NO WARRANTIES WHATSOEVER. CARNEGIE
 * MELLON UNIVERSITY EXPRESSLY DISCLAIMS TO THE FULLEST EXTENT PERMITTED BY
 * LAW ALL EXPRESS, IMPLIED, AND STATUTORY WARRANTIES, INCLUDING, WITHOUT
 * LIMITATION, THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, AND NON-INFRINGEMENT OF PROPRIETARY RIGHTS.
 *
 * This Program is distributed under a BSD license.  Please see LICENSE file or
 * permission@sei.cmu.edu for more information.  DM-0002659
 */

/**
 * Implementation of all sparse mxv for the sequential (CPU) backend.
 */

#ifndef GB_SEQUENTIAL_SPARSE_MXV_HPP
#define GB_SEQUENTIAL_SPARSE_MXV_HPP

#pragma once

#include <functional>
#include <utility>
#include <vector>
#include <iterator>
#include <iostream>
#include <graphblas/algebra.hpp>

#include "sparse_helpers.hpp"
#include "host/src/opencl_mxv.hpp"



//****************************************************************************

namespace GraphBLAS
{
    namespace backend
    {
        //********************************************************************
        /// Implementation of 4.3.3 mxv: Matrix-Vector variant
        template<typename WVectorT,
            typename MaskT,
            typename AccumT,
            typename SemiringT,
            typename AMatrixT,
            typename UVectorT>
                inline void mxv(WVectorT        &w,
                        MaskT     const &mask,
                        AccumT           accum,
                        SemiringT        op,
                        AMatrixT  const &A,
                        UVectorT  const &u,
                        bool             replace_flag = false)
                {
                    static cl_int * IA;
                    static cl_int * JA;
                    static float * MA;
                    static float * VX;

                    // =================================================================
                    // Do the basic dot-product work with the semi-ring.
                    typedef typename SemiringT::result_type D3ScalarType;
                    typedef typename AMatrixT::ScalarType AScalarType;
                    typedef std::vector<std::tuple<IndexType,AScalarType> >  ARowType;

                    std::vector<std::tuple<IndexType, D3ScalarType> > t;
                    std::cout << A;

                    if ((A.nvals() > 0) && (u.nvals() > 0))
                    {
                        if((typeid(AScalarType)==typeid(float))){
                            auto u_contents(u.getContents());
                            printf("\n=================type match, using FPGA=================\n");
                            //float *MA=(float *)aocl_utils::alignedMalloc(A.nvals()*sizeof(float));;;
                            //unsigned int   *IA=(unsigned int *)aocl_utils::alignedMalloc((A.nrows()+1)*sizeof(unsigned int));;
                            //unsigned int   *JA=(unsigned int *)aocl_utils::alignedMalloc(A.nvals()*sizeof(unsigned int));;
                            MA=(float *)aocl_utils::alignedMalloc(A.nvals()*sizeof(float));;;
                            IA=(cl_int *)aocl_utils::alignedMalloc((A.nrows()+1)*sizeof(cl_int));;
                            JA=(cl_int *)aocl_utils::alignedMalloc(A.nvals()*sizeof(cl_int));;

                            unsigned int cur_ia = 0;
                            unsigned int cur_ja = 0;
                            IA[0] = 0;
                            for (IndexType row_idx = 0; row_idx < w.size(); ++row_idx)
                            {
                                ARowType const &A_row(A.getRow(row_idx));
                                if (!A_row.empty())
                                {
                                    for(IndexType ii = 0; ii <A_row.size(); ii++){
                                        MA[cur_ja]=std::get<1>(A_row[ii]);
                                        JA[cur_ja]=std::get<0>(A_row[ii]);
                                        cur_ja +=1;
                                    }
                                    cur_ia += A_row.size();
                                }
                                IA[row_idx+1] = cur_ia;
                            }
                            VX =(float        *)aocl_utils::alignedMalloc(u.size()*sizeof(float));
                            //float        *VX =(float        *)aocl_utils::alignedMalloc(u.size()*sizeof(float));
                            for(int i =0; i< u.size(); i++) {
                                VX[i] = 0;
                            }
                            for(int i =0; i< u_contents.size(); i++) {
                                VX[std::get<0>(u_contents[i])]= (float)std::get<1>(u_contents[i]);
                            }
                            float * result;
                            unsigned int w_size = (unsigned int)w.size();
                            unsigned int u_size = (unsigned int)u.size();
                            unsigned int A_nvals=A.nvals();
                            result = (float*)aocl_utils::alignedMalloc(w_size*sizeof(float));
                            opencl_mxv<cl_int, float>(IA, JA, MA, VX, w_size,u_size, A_nvals,result);
                            //opencl_mxv<unsigned int, float>(IA, JA, MA, VX, w_size,u_size, A_nvals,result);
                            for(int ii =0; ii < w.size(); ii++){
                                if(result[ii] !=0) {     
                                    std::cout<<ii;
                                    std::cout<<result[ii];
                                    t.push_back(std::make_tuple(ii,result[ii]));
                                }
                            }
                        }
                        else {
                            auto u_contents(u.getContents());
                            printf("\n=================type not match, using CPU =================\n");
                            for (IndexType row_idx = 0; row_idx < w.size(); ++row_idx)
                            {
                                ARowType const &A_row(A.getRow(row_idx));

                                if (!A_row.empty())
                                {
                                    D3ScalarType t_val;
                                    if (dot(t_val, A_row, u_contents, op))
                                    {
                                        t.push_back(std::make_tuple(row_idx, t_val));
                                    }
                                }
                            }

                        }
                    }
                    // =================================================================
                    // Accumulate into Z
                    /// @todo Do we need a type generator for z: D(w) if no accum,
                    /// or D3(accum). I think that output type should be equivalent, but
                    /// still need to work the proof.
                    typedef typename WVectorT::ScalarType WScalarType;
                    std::vector<std::tuple<IndexType, WScalarType> > z;
                    ewise_or_opt_accum_1D(z, w, t, accum);

                    // =================================================================
                    // Copy Z into the final output, w, considering mask and replace
                    write_with_opt_mask_1D(w, z, mask, replace_flag);
              
                    if(IA) aocl_utils::alignedFree(IA);
                    if(JA) aocl_utils::alignedFree(JA);
                    if(VX) aocl_utils::alignedFree(VX);
                    if(MA) aocl_utils::alignedFree(MA);

                }// void mxv 
    }//  backend
} // GraphBLAS

#endif
