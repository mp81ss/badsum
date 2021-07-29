CC=gcc
CFLAGS=-Wall -Wextra -pedantic -march=x86-64 -O2
FASM_FLAGS=-d OS=LINUX

.PHONY: clean

badsum: badsum.c md5.o sha1.o
	$(CC) $(CFLAGS) -s -o $@ $^

%.o: %.asm x86_64.inc
	$(fasm)/fasm.x64 $(FASM_FLAGS) $< 

clean:
	$(RM) badsum badsum.o md5.o sha1.o
