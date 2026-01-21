# Makefile for C-- Compiler
# EE046266: Compilation Methods - Winter 2025-2026

CXX = g++
CXXFLAGS = -std=c++11 -Wall
LEX = flex
YACC = bison

TARGET = rx-cc
SOURCES = rx-cc.cpp part3_helpers.cpp part3.tab.cpp lex.yy.c
OBJECTS = $(SOURCES:.cpp=.o)

all: $(TARGET)

$(TARGET): part3.tab.cpp lex.yy.c part3_helpers.cpp rx-cc.cpp
	$(CXX) $(CXXFLAGS) -o $(TARGET) rx-cc.cpp part3_helpers.cpp part3.tab.cpp lex.yy.c

part3.tab.cpp: part3.y
	$(YACC) -d -o part3.tab.cpp part3.y

lex.yy.c: part3.lex part3.tab.cpp
	$(LEX) part3.lex

clean:
	rm -f $(TARGET) *.o lex.yy.c part3.tab.cpp part3.tab.hpp
	rm -f examples/*.rsk examples/*.e

.PHONY: all clean
