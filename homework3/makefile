# Makefile for C-- Compiler (Part 3)
# EE046266 Winter 2025-2026

CXX = g++
CXXFLAGS = -std=c++11 -Wall -Wno-write-strings -Wno-deprecated-register
LEX = flex
YACC = bison

# Target executable
TARGET = rx-cc

# Source files
LEX_SRC = part3.lex
YACC_SRC = part3.y
HELPERS_SRC = part3_helpers.cpp
MAIN_SRC = rx-cc.cpp

# Generated files
LEX_OUT = lex.yy.c
YACC_OUT = part3.tab.cpp
YACC_HDR = part3.tab.hpp

# Object files
OBJS = $(YACC_OUT:.cpp=.o) $(LEX_OUT:.c=.o) $(HELPERS_SRC:.cpp=.o) $(MAIN_SRC:.cpp=.o)

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

# Generate parser
$(YACC_OUT) $(YACC_HDR): $(YACC_SRC)
	$(YACC) -d -o $(YACC_OUT) $<

# Generate lexer
$(LEX_OUT): $(LEX_SRC) $(YACC_HDR)
	$(LEX) -o $@ $<

# Compile C++ files
%.o: %.cpp $(YACC_HDR)
	$(CXX) $(CXXFLAGS) -c $<

# Compile C files (lexer output)
%.o: %.c $(YACC_HDR)
	$(CXX) $(CXXFLAGS) -c $<

clean:
	rm -f $(TARGET) $(OBJS) $(LEX_OUT) $(YACC_OUT) $(YACC_HDR) part3.tab.cpp part3.tab.hpp
	rm -f *.rsk *.e
	rm -f lex.yy.o part3.tab.o

test: $(TARGET)
	@echo "Running test on example1.cmm..."
	./$(TARGET) examples/example1.cmm
	@echo ""
	@echo "Generated code:"
	@cat examples/example1.rsk

# Help target
help:
	@echo "Available targets:"
	@echo "  all (default) - Build the compiler"
	@echo "  clean         - Remove generated files"
	@echo "  test          - Run a simple test"
	@echo "  help          - Show this help message"
