# Makefile for C-- Parser (Tracing Version)
# This version generates detailed trace output

CC = gcc
CFLAGS = -Wall -g
FLEX = flex
BISON = bison

TARGET = part2_trace

LEX_SRC = part2_trace.lex
YACC_SRC = part2_trace.y
HELPER_SRC = ../part2_helpers.c
HELPER_HDR = ../part2_helpers.h

LEX_C = lex.yy.c
YACC_C = part2_trace.tab.c
YACC_H = part2_trace.tab.h

OBJS = $(YACC_C:.c=.o) $(LEX_C:.c=.o) $(HELPER_SRC:.c=.o)

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -d $(YACC_SRC)

$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) $(LEX_SRC)

part2_trace.tab.o: $(YACC_C) $(HELPER_HDR)
	$(CC) $(CFLAGS) -c $(YACC_C)

lex.yy.o: $(LEX_C) $(HELPER_HDR)
	$(CC) $(CFLAGS) -c $(LEX_C)

part2_helpers.o: $(HELPER_SRC) $(HELPER_HDR)
	$(CC) $(CFLAGS) -c $(HELPER_SRC)

# Test with simple example
test: $(TARGET)
	@echo "Running trace parser on test_simple_demo.cmm..."
	./$(TARGET) < ../test_simple_demo.cmm > output.tree
	@echo ""
	@echo "=== OUTPUT TREE ==="
	@cat output.tree
	@echo ""
	@echo "=== TRACE FILE ==="
	@cat trace_output.txt

clean:
	rm -f $(TARGET) $(OBJS) $(LEX_C) $(YACC_C) $(YACC_H) trace_output.txt output.tree
