# Makefile for C-- Parser (Project Part 2)
# Student IDs: 322449539, 323885350

CC = gcc
CFLAGS = -Wall -g
FLEX = flex
BISON = bison

# Output executable name
TARGET = part2

# Source files
LEX_SRC = part2.lex
YACC_SRC = part2.y
HELPER_SRC = part2_helpers.c
HELPER_HDR = part2_helpers.h

# Generated files
LEX_C = lex.yy.c
YACC_C = part2.tab.c
YACC_H = part2.tab.h

# Object files
OBJS = $(YACC_C:.c=.o) $(LEX_C:.c=.o) $(HELPER_SRC:.c=.o)

.PHONY: all clean

all: $(TARGET)

# Build the parser executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

# Generate parser C code from Bison grammar
$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -d $(YACC_SRC)

# Generate lexer C code from Flex specification
$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) $(LEX_SRC)

# Compile parser object
part2.tab.o: $(YACC_C) $(HELPER_HDR)
	$(CC) $(CFLAGS) -c $(YACC_C)

# Compile lexer object
lex.yy.o: $(LEX_C) $(HELPER_HDR)
	$(CC) $(CFLAGS) -c $(LEX_C)

# Compile helper functions
part2_helpers.o: $(HELPER_SRC) $(HELPER_HDR)
	$(CC) $(CFLAGS) -c $(HELPER_SRC)

# Clean generated and compiled files
clean:
	rm -f $(TARGET) $(OBJS) $(LEX_C) $(YACC_C) $(YACC_H)
