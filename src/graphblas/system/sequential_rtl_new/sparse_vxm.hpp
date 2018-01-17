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
 * Implementations of sparse vxm for the sequential (CPU) backend.
 */

#ifndef GB_SEQUENTIAL_SPARSE_VXM_HPP
#define GB_SEQUENTIAL_SPARSE_VXM_HPP

#pragma once

#include <functional>
#include <utility>
#include <vector>
#include <iterator>
#include <iostream>
#include <graphblas/algebra.hpp>

#include "sparse_helpers.hpp"


//****************************************************************************

namespace GraphBLAS
{
    namespace backend
    {
        //********************************************************************
        /// Implementation of 4.3.2 vxm: Vector-Matrix multiply
        template<typename WVectorT,
                 typename MaskT,
                 typename AccumT,
                 typename SemiringT,
                 typename AMatrixT,
                 typename UVectorT>
        inline void vxm(WVectorT        &w,
                        MaskT     const &mask,
                        AccumT           accum,
                        SemiringT        op,
                        UVectorT  const &u,
                        AMatrixT  const &A,
                        bool             replace_flag = false)
        {
            // =================================================================
            // Do the basic dot-product work with the semi-ring.
            typedef typename SemiringT::result_type D3ScalarType;
            typedef typename AMatrixT::ScalarType AScalarType;
            typedef std::vector<std::tuple<IndexType,AScalarType> > AColType;
            typedef std::vector<std::tuple<IndexType,AScalarType> >  ARowType;

            std::vector<std::tuple<IndexType, D3ScalarType> > t;

            if ((A.nvals() > 0) && (u.nvals() > 0))
            {
              if((typeid(AScalarType)==typeid(float))){
                 auto u_contents(u.getContents());
                 printf("\n=================type match, using FPGA=================\n");
                 float *MA=(float *)std::malloc(A.nvals()*sizeof(float));;;
                 unsigned int   *IA=(unsigned int *)std::malloc((A.nrows()+1)*sizeof(unsigned int));;
                 unsigned int   *JA=(unsigned int *)std::malloc(A.nvals()*sizeof(unsigned int));;
                 unsigned int cur_ia = 0;
                 unsigned int cur_ja = 0;
                 IA[0] = 0;
                 for (IndexType col_idx = 0; col_idx < w.size(); ++col_idx)
                 {
                     AColType const &A_col(A.getCol(col_idx));
                     if (!A_col.empty())
                     {
                         for(IndexType ii = 0; ii <A_col.size(); ii++){
                             MA[cur_ja]=std::get<1>(A_col[ii]);
                             JA[cur_ja]=std::get<0>(A_col[ii]);
                             cur_ja +=1;
                         }
                         cur_ia += A_col.size();
                     }
                     IA[col_idx+1] = cur_ia;
                 }
                 float        *pVX =(float        *)std::malloc(u.size()*sizeof(float));
                 for(int i =0; i< u.size(); i++) {
                     pVX[i] = 0;
                 }
                 for(int i =0; i< u_contents.size(); i++) {
                     pVX[std::get<0>(u_contents[i])]= (float)std::get<1>(u_contents[i]);
                 }
                 float * result;
                 unsigned int w_size = (unsigned int)w.size();
                 unsigned int u_size = (unsigned int)u.size();
                 unsigned int A_nvals=A.nvals();
                 result = (float*)std::malloc(w_size*sizeof(float));
                 opencl_mxv<unsigned int, float>(IA, JA, MA, pVX, w_size,u_size, A_nvals,result);
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
                for (IndexType col_idx = 0; col_idx < w.size(); ++col_idx)
                {
                    AColType const &A_col(A.getCol(col_idx));

                    if (!A_col.empty())
                    {
                        D3ScalarType t_val;
                        if (dot(t_val, u_contents, A_col, op))
                        {
                            t.push_back(std::make_tuple(col_idx, t_val));
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
        }

    } // backend
} // GraphBLAS

#endif
