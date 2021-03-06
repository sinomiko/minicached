DEBUG ?= 1
CC = gcc
CCFLAGS = -g -O2 -std=gnu99 
CXX = g++
CXXFLAGS = -g -O2 -std=c++11
PACKAGE = minicached
PACKAGE_NAME = $(PACKAGE)
PACKAGE_STRING = $(PACKAGE_NAME)1.1
PACKAGE_VERSION = 1.1
SHELL = /bin/bash
VERSION = 1.1
SUBDIRS = source
EXTRAFLAGS = -g -I./include -lcrypto -lrt -ljson-c -lpthread -L./lib
OBJDIR = obj
LIBNAME = libminicached.a
LIBDIR = ./lib

vpath %.c $(SUBDIRS)

srcs = $(filter-out main.c, $(notdir $(wildcard $(SUBDIRS)/*.c)))
objs = $(srcs:%.c=$(OBJDIR)/%.o)

ifeq ($(DEBUG),1)
	TARGET_DIR=Debug
else
	TARGET_DIR=Release
endif

all : $(PACKAGE)
.PHONY : all

$(PACKAGE) : $(objs) 
	@mkdir -p $(TARGET_DIR) $(LIBDIR)
	$(AR) rcs $(LIBDIR)/$(LIBNAME) $^
	$(CC) -c $(CCFLAGS) $(EXTRAFLAGS) $(SUBDIRS)/main.c -o $(OBJDIR)/main.o
	$(CC) $(CCFLAGS) $(OBJDIR)/main.o $(EXTRAFLAGS) -lminicached -o $(TARGET_DIR)/$(PACKAGE)

$(objs) : $(OBJDIR)/%.o: %.c
	@mkdir -p $(OBJDIR)
	$(CC) -MMD -c $(CCFLAGS) $(EXTRAFLAGS) $< -o $@ 


#check header for obj reconstruction
-include $(OBJDIR)/*.d

.PHONY : clean 
clean :	
	-rm -fr $(OBJDIR)/* 
	-rm -fr $(TARGET_DIR)/*
	-rm -fr $(LIBDIR)/*
