CC = gcc
CFLAGS = -Wall -g
LEX = flex

part1: part1.lex
	$(LEX) -o lex.yy.c part1.lex
	$(CC) $(CFLAGS) -o part1 lex.yy.c -lfl

clean:
	rm -f part1 lex.yy.c

.PHONY: clean