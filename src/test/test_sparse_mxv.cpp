/*
 * Copyright (c) 2017 Carnegie Mellon University and The Trustees of
 * Indiana University.
 * All Rights Reserved.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS," WITH NO WARRANTIES WHATSOEVER. CARNEGIE
 * MELLON UNIVERSITY AND THE TRUSTEES OF INDIANA UNIVERSITY EXPRESSLY DISCLAIM
 * TO THE FULLEST EXTENT PERMITTED BY LAW ALL EXPRESS, IMPLIED, AND STATUTORY
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF PROPRIETARY RIGHTS.
 *
 * This Program is distributed under a BSD license.  Please see LICENSE file or
 * permission@sei.cmu.edu for more information.  DM-0002659
 */

#include <graphblas/graphblas.hpp>

#define BOOST_TEST_MAIN
#define BOOST_TEST_MODULE sparse_mxv_suite

#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(sparse_mxv_suite)

//****************************************************************************

namespace
{
    std::vector<std::vector<float> > m3x3_dense = {{12, 1, 3},
                                                    {0,  0, 6},
                                                    {7,  0, 9}};

    std::vector<std::vector<float> > m3x4_dense = {{5, 0, 1, 2},
                                                    {6, 7, 0, 0},
                                                    {4, 5, 0, 1}};

    std::vector<float> u3_dense = {1, 1, 0};
    std::vector<float> u4_dense = {0, 0, 1, 1};

    std::vector<float> ans3_dense = {13, 0, 7};
    std::vector<float> ans4_dense = { 3, 0, 1};

    static std::vector<float> v4_ones = {1, 1, 1, 1};
    static std::vector<float> v3_ones = {1, 1, 1};
}

//****************************************************************************
// Tests without mask
//****************************************************************************

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_bad_dimensions)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mB(m3x4_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> w4(4);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> w3(3);

    // incompatible input dimensions
    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(w3,
                        GraphBLAS::NoMask(),
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(), mB, u3)),
        GraphBLAS::DimensionException);

    // incompatible output matrix dimensions
    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(w4,
                        GraphBLAS::NoMask(),
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(), mA, u3)),
        GraphBLAS::DimensionException);
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_reg)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mB(m3x4_dense, 0.);
    GraphBLAS::Vector<float> u3(u3_dense, 0.);
    GraphBLAS::Vector<float> u4(u4_dense, 0.);
    GraphBLAS::Vector<float> result(3);
    GraphBLAS::Vector<float> ansA(ans3_dense, 0.);
    GraphBLAS::Vector<float> ansB(ans4_dense, 0.);

    GraphBLAS::mxv(result,
                   GraphBLAS::NoMask(),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), mA, u3);
    BOOST_CHECK_EQUAL(result, ansA);

    GraphBLAS::mxv(result,
                   GraphBLAS::NoMask(),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), mB, u4);
    BOOST_CHECK_EQUAL(result, ansB);
}

////****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_stored_zero_result)
{
    // Build some matrices.
    std::vector<std::vector<float> > A = {{1, 1, 0, 0},
                                        {1, 2, 2, 0},
                                        {0, 2, 3, 3},
                                        {0, 0, 3, 4}};
    std::vector<float> u4_dense =  { 1,-1, 0, 0};
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(A, 0);
    GraphBLAS::Vector<float> u(u4_dense, 0);
    GraphBLAS::Vector<float> result(4);

    //??? use a different sentinel value so that stored zeros are preserved.
    int const NIL(666);
    std::vector<float> ans = {  0,  -1, -2, NIL};
    GraphBLAS::Vector<float> answer(ans, NIL);

    GraphBLAS::mxv(result,
                   GraphBLAS::NoMask(),
                   GraphBLAS::NoAccumulate(), // Second<int>(),
                   GraphBLAS::ArithmeticSemiring<float>(), mA, u);
    BOOST_CHECK_EQUAL(result, answer);
    BOOST_CHECK_EQUAL(result.nvals(), 3);
}

////****************************************************************************
BOOST_AUTO_TEST_CASE(test_a_transpose)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mB(m3x4_dense, 0.);
    GraphBLAS::Vector<float> u3(u3_dense, 0.);
    GraphBLAS::Vector<float> u4(u4_dense, 0.);
    GraphBLAS::Vector<float> result3(3);
    GraphBLAS::Vector<float> result4(4);

    std::vector<float> ansAT_dense = {12, 1, 9};
    std::vector<float> ansBT_dense = {11, 7, 1, 2};

    GraphBLAS::Vector<float> ansA(ansAT_dense, 0.);
    GraphBLAS::Vector<float> ansB(ansBT_dense, 0.);

    GraphBLAS::mxv(result3,
                   GraphBLAS::NoMask(),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(),
                   transpose(mA), u3);
    BOOST_CHECK_EQUAL(result3, ansA);

    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(result4,
                        GraphBLAS::NoMask(),
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(),
                        transpose(mB), u4)),
        GraphBLAS::DimensionException);

    GraphBLAS::mxv(result4,
                   GraphBLAS::NoMask(),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(),
                   transpose(mB), u3);
    BOOST_CHECK_EQUAL(result4, ansB);
}

//****************************************************************************
// Tests using a mask with REPLACE
//****************************************************************************

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_replace_bad_dimensions)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m4(u4_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> w3(3);

    // incompatible mask matrix dimensions
    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(w3,
                        m4,
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(), mA, u3,
                        true)),
        GraphBLAS::DimensionException);
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_replace_reg)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense, 0.);
    BOOST_CHECK_EQUAL(m3.nvals(), 2);

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 1, 0};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       m3,
                       GraphBLAS::Second<float>(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3,
                       true);

        BOOST_CHECK_EQUAL(result.nvals(), 2);
        BOOST_CHECK_EQUAL(result, answer);
    }

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 0, 0};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       m3,
                       GraphBLAS::NoAccumulate(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3,
                       true);

        BOOST_CHECK_EQUAL(result.nvals(), 1);
        BOOST_CHECK_EQUAL(result, answer);
    }
}

////****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_replace_reg_stored_zero)
{
    // tests a computed and stored zero
    // tests a stored zero in the mask

    // Build some matrices.
    std::vector<std::vector<float> > A_dense = {{1, 1, 0, 0},
                                              {1, 2, 2, 0},
                                              {0, 2, 3, 3},
                                              {0, 0, 3, 4}};
    std::vector<float> u4_dense =  { 1,-1, 1, 0};
    std::vector<float> mask_dense =  { 1, 1, 1, 0};
    std::vector<float> ones_dense =  { 1, 1, 1, 1};
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> A(A_dense, 0);
    GraphBLAS::Vector<float> u(u4_dense, 0);
    GraphBLAS::Vector<float> mask(mask_dense, 0);
    GraphBLAS::Vector<float> result(ones_dense, 0);

    BOOST_CHECK_EQUAL(mask.nvals(), 3);  // [ 1 1 1 - ]
    mask.setElement(3, 0);
    BOOST_CHECK_EQUAL(mask.nvals(), 4);  // [ 1 1 1 0 ]

    float const NIL(666);
    std::vector<float> ans = { NIL, 1, 1,  NIL};
    GraphBLAS::Vector<float> answer(ans, NIL);

    GraphBLAS::mxv(result,
                   mask,
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), A, u,
                   true);
    BOOST_CHECK_EQUAL(result.nvals(), 2);
    BOOST_CHECK_EQUAL(result, answer);
}

////****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_replace_a_transpose)
{
    // Build some matrices.
    std::vector<std::vector<int> > A_dense = {{1, 1, 0, 0, 1},
                                              {1, 2, 2, 0, 1},
                                              {0, 2, 3, 3, 1},
                                              {0, 0, 3, 4, 1}};
    std::vector<int> u4_dense =  { 1,-1, 1, 0};
    std::vector<int> mask_dense =  { 1, 0, 1, 0, 1};
    std::vector<int> ones_dense =  { 1, 1, 1, 1, 1};
    GraphBLAS::Matrix<int, GraphBLAS::DirectedMatrixTag> A(A_dense, 0);
    GraphBLAS::Vector<int> u(u4_dense, 0);
    GraphBLAS::Vector<int> mask(mask_dense, 0);
    GraphBLAS::Vector<int> result(ones_dense, 0);

    int const NIL(666);
    std::vector<int> ans = { 0, NIL, 1,  NIL, 1};
    GraphBLAS::Vector<int> answer(ans, NIL);

    GraphBLAS::mxv(result,
                   mask,
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), transpose(A), u,
                   true);

    BOOST_CHECK_EQUAL(result, answer);
}

//****************************************************************************
// Tests using a mask with MERGE semantics
//****************************************************************************

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_bad_dimensions)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m4(u4_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> w3(v3_ones, 0.);

    // incompatible mask matrix dimensions
    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(w3,
                        m4,
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(), mA, u3)),
        GraphBLAS::DimensionException);
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_reg)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense, 0.); // [1 1 -]
    BOOST_CHECK_EQUAL(m3.nvals(), 2);

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 1, 1};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       m3,
                       GraphBLAS::Second<float>(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3);

        BOOST_CHECK_EQUAL(result.nvals(), 3);
        BOOST_CHECK_EQUAL(result, answer);
    }

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 0, 1};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       m3,
                       GraphBLAS::NoAccumulate(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3);

        BOOST_CHECK_EQUAL(result.nvals(), 2);
        BOOST_CHECK_EQUAL(result, answer);
    }
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_reg_stored_zero)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense); // [1 1 0]
    BOOST_CHECK_EQUAL(m3.nvals(), 3);

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 1, 1};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       m3,
                       GraphBLAS::Second<float>(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3);

        BOOST_CHECK_EQUAL(result.nvals(), 3);
        BOOST_CHECK_EQUAL(result, answer);
    }

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 0, 1};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       m3,
                       GraphBLAS::NoAccumulate(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3);

        BOOST_CHECK_EQUAL(result.nvals(), 2);
        BOOST_CHECK_EQUAL(result, answer);
    }
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_masked_a_transpose)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.); // [1 1 -]
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense, 0.); // [1 1 -]
    GraphBLAS::Vector<float> result(v3_ones, 0.);

    BOOST_CHECK_EQUAL(m3.nvals(), 2);

    std::vector<float> ans = {12, 1, 1};
    GraphBLAS::Vector<float> answer(ans, 0.);

    GraphBLAS::mxv(result,
                   m3,
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), transpose(mA), u3);

    BOOST_CHECK_EQUAL(result.nvals(), 3);
    BOOST_CHECK_EQUAL(result, answer);
}

//****************************************************************************
// Tests using a complemented mask with REPLACE semantics
//****************************************************************************

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_replace_bad_dimensions)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m4(u4_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> w3(3);

    // incompatible mask matrix dimensions
    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(w3,
                        GraphBLAS::complement(m4),
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(), mA, u3,
                        true)),
        GraphBLAS::DimensionException);
}
//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_replace_reg)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);

    std::vector<float> scmp_mask_dense = {0., 0., 1.};
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(scmp_mask_dense, 0.);
    BOOST_CHECK_EQUAL(m3.nvals(), 1);

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 1, 0};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       GraphBLAS::complement(m3),
                       GraphBLAS::Second<float>(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3,
                       true);

        BOOST_CHECK_EQUAL(result.nvals(), 2);
        BOOST_CHECK_EQUAL(result, answer);
    }

    {
        GraphBLAS::Vector<float> result(v3_ones, 0.);

        std::vector<float> ans = {13, 0, 0};
        GraphBLAS::Vector<float> answer(ans, 0.);

        GraphBLAS::mxv(result,
                       GraphBLAS::complement(m3),
                       GraphBLAS::NoAccumulate(),
                       GraphBLAS::ArithmeticSemiring<float>(), mA, u3,
                       true);

        BOOST_CHECK_EQUAL(result.nvals(), 1);
        BOOST_CHECK_EQUAL(result, answer);
    }
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_replace_reg_stored_zero)
{
    // tests a computed and stored zero
    // tests a stored zero in the mask
    // Build some matrices.
    std::vector<std::vector<int> > A_dense = {{1, 1, 0, 0},
                                              {1, 2, 2, 0},
                                              {0, 2, 3, 3},
                                              {0, 0, 3, 4}};
    std::vector<int> u4_dense =  { 1,-1, 1, 0};
    std::vector<int> scmp_mask_dense =  { 0, 0, 0, 1 };
    std::vector<int> ones_dense =  { 1, 1, 1, 1};
    GraphBLAS::Matrix<int, GraphBLAS::DirectedMatrixTag> A(A_dense, 0);
    GraphBLAS::Vector<int> u(u4_dense, 0);
    GraphBLAS::Vector<int> mask(scmp_mask_dense); //, 0);
    GraphBLAS::Vector<int> result(ones_dense, 0);

    BOOST_CHECK_EQUAL(mask.nvals(), 4);  // [ 0 0 0 1 ]

    int const NIL(666);
    std::vector<int> ans = { 0, 1, 1,  NIL};
    GraphBLAS::Vector<int> answer(ans, NIL);

    GraphBLAS::mxv(result,
                   GraphBLAS::complement(mask),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), A, u,
                   true);
    BOOST_CHECK_EQUAL(result.nvals(), 3);
    BOOST_CHECK_EQUAL(result, answer);
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_replace_a_transpose)
{
    // Build some matrices.
    std::vector<std::vector<int> > A_dense = {{1, 1, 0, 0, 1},
                                              {1, 2, 2, 0, 1},
                                              {0, 2, 3, 3, 1},
                                              {0, 0, 3, 4, 1}};
    std::vector<int> u4_dense =  { 1,-1, 1, 0};
    std::vector<int> mask_dense =  { 0, 1, 0, 1, 0};
    std::vector<int> ones_dense =  { 1, 1, 1, 1, 1};
    GraphBLAS::Matrix<int, GraphBLAS::DirectedMatrixTag> A(A_dense, 0);
    GraphBLAS::Vector<int> u(u4_dense, 0);
    GraphBLAS::Vector<int> mask(mask_dense, 0);
    GraphBLAS::Vector<int> result(ones_dense, 0);

    int const NIL(666);
    std::vector<int> ans = { 0, NIL, 1,  NIL, 1};
    GraphBLAS::Vector<int> answer(ans, NIL);

    GraphBLAS::mxv(result,
                   GraphBLAS::complement(mask),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), transpose(A), u,
                   true);

    BOOST_CHECK_EQUAL(result, answer);
}

//****************************************************************************
// Tests using a complemented mask (with merge semantics)
//****************************************************************************

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_bad_dimensions)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m4(u4_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> w3(v3_ones, 0.);

    // incompatible mask matrix dimensions
    BOOST_CHECK_THROW(
        (GraphBLAS::mxv(w3,
                        GraphBLAS::complement(m4),
                        GraphBLAS::NoAccumulate(),
                        GraphBLAS::ArithmeticSemiring<float>(), mA, u3)),
        GraphBLAS::DimensionException);
}
//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_reg)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense, 0.); // [1 1 -]
    GraphBLAS::Vector<float> result(v3_ones, 0.);

    BOOST_CHECK_EQUAL(m3.nvals(), 2);

    std::vector<float> ans = {1, 1, 7}; // if accum is NULL then {1, 0, 7};
    GraphBLAS::Vector<float> answer(ans, 0.);

    GraphBLAS::mxv(result,
                   GraphBLAS::complement(m3),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), mA, u3);

    BOOST_CHECK_EQUAL(result.nvals(), 3); //2);
    BOOST_CHECK_EQUAL(result, answer);
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_reg_stored_zero)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.);
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense); // [1 1 0]
    GraphBLAS::Vector<float> result(v3_ones, 0.);

    BOOST_CHECK_EQUAL(m3.nvals(), 3);

    std::vector<float> ans = {1, 1, 7}; // if accum is NULL then {1, 0, 7};
    GraphBLAS::Vector<float> answer(ans, 0.);

    GraphBLAS::mxv(result,
                   GraphBLAS::complement(m3),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), mA, u3);

    BOOST_CHECK_EQUAL(result.nvals(), 3); //2);
    BOOST_CHECK_EQUAL(result, answer);
}

//****************************************************************************
BOOST_AUTO_TEST_CASE(test_mxv_scmp_masked_a_transpose)
{
    GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> mA(m3x3_dense, 0.);

    GraphBLAS::Vector<float, GraphBLAS::SparseTag> u3(u3_dense, 0.); // [1 1 -]
    GraphBLAS::Vector<float, GraphBLAS::SparseTag> m3(u3_dense, 0.); // [1 1 -]
    GraphBLAS::Vector<float> result(v3_ones, 0.);

    BOOST_CHECK_EQUAL(m3.nvals(), 2);

    std::vector<float> ans = {1, 1, 9};
    GraphBLAS::Vector<float> answer(ans, 0.);

    GraphBLAS::mxv(result,
                   GraphBLAS::complement(m3),
                   GraphBLAS::NoAccumulate(),
                   GraphBLAS::ArithmeticSemiring<float>(), transpose(mA), u3);

    BOOST_CHECK_EQUAL(result.nvals(), 3);
    BOOST_CHECK_EQUAL(result, answer);
}


BOOST_AUTO_TEST_SUITE_END()
