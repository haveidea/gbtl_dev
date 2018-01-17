AM_CXXFLAG=-lboost_unit_test_framework

if ENABLE_CUDA

else

AM_CPPFLAGS = -I$(abs_top_srcdir) $(BACKEND_CPPFLAGS)

SUBDIRS = sequential

noinst_PROGRAMS = \
test_sequential_sparse_mxv 

test_sequential_sparse_mxv_SOURCES = test_sparse_mxv.cpp

endif
