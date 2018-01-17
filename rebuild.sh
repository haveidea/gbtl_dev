#! /usr/bin/env bash

rm -rf build
mkdir build
cd build
cmake ../src -DOC_EMU=OFF
make -i -j 8

