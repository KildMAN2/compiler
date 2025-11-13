CC = gcc
CFLAGS = -Wall -g
LEX = flex

part1: homework0.lex
	$(LEX) -o lex.yy.c homework0.lex
	$(CC) $(CFLAGS) -o homework0 lex.yy.c -lfl

clean:
	rm -f homework0 lex.yy.c

.PHONY: clean