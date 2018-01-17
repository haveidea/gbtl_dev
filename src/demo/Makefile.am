# TODO Best way to add the library sources?

AM_CPPFLAGS = -I$(abs_top_srcdir) $(BACKEND_CPPFLAGS)

if ENABLE_CUDA

AM_CPPFLAGS += -I$(abs_top_srcdir)/cusplibrary

include $(top_srcdir)/mk/cuda.mk

noinst_PROGRAMS = page_rank_demo

else

noinst_PROGRAMS = page_rank_demo


page_rank_demo_SOURCES = page_rank_demo.cpp graphblas.cpp

AM_CPPFLAGS+=-I$(abs_top_srcdir)
endif
