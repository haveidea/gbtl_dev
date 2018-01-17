/*
 * Copyright (c) 2015 Carnegie Mellon University and The Trustees of Indiana
 * University.
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

#include <iostream>

#include <graphblas/graphblas.hpp>
#include <algorithms/page_rank.hpp>

//****************************************************************************
int main()
{
    // FA Tech Note graph
    //
    //    {-, -, -, 1, -, -, -, -, -},
    //    {-, -, -, 1, -, -, 1, -, -},
    //    {-, -, -, -, 1, 1, 1, -, 1},
    //    {1, 1, -, -, 1, -, 1, -, -},
    //    {-, -, 1, 1, -, -, -, -, 1},
    //    {-, -, 1, -, -, -, -, -, -},
    //    {-, 1, 1, 1, -, -, -, -, -},
    //    {-, -, -, -, -, -, -, -, -},
    //    {-, -, 1, -, 1, -, -, -, -};

    /// @todo change scalar type to unsigned int or GraphBLAS::IndexType
    using T = GraphBLAS::IndexType;
    typedef GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag> GBMatrix;
    //T const INF(std::numeric_limits<T>::max());

    GraphBLAS::IndexType const NUM_NODES = 9;
    GraphBLAS::IndexArrayType i = {0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3,
                                   4, 4, 4, 5, 6, 6, 6, 8, 8};
    GraphBLAS::IndexArrayType j = {3, 3, 6, 4, 5, 6, 8, 0, 1, 4, 6,
                                   2, 3, 8, 2, 1, 2, 3, 2, 4};
    std::vector<float> v(i.size(), 1);

    GBMatrix G_tn(NUM_NODES, NUM_NODES);
    G_tn.build(i.begin(), j.begin(), v.begin(), i.size());
    GraphBLAS::print_matrix(std::cout, G_tn, "Graph adjacency matrix:");

    // Perform a single BFS
    GraphBLAS::Vector<float> parent_list(NUM_NODES);
    algorithms::page_rank<GraphBLAS::Matrix<float, GraphBLAS::DirectedMatrixTag>,float>(G_tn,  parent_list, 0.85, 0.001, 1);
    GraphBLAS::print_vector(std::cout, parent_list,
                            "Parent list for root at vertex 3");


    return 0;
}
