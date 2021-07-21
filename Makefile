CC?=gcc
CFLAGS=-std=c99 -march=x86-64 -O2 -fpic
FASM_FLAGS=-d OS=LINUX

.PHONY: clean

badsum: md5.o sha1.o
	$(CC) $(CFLAGS) -c badsum.c
	$(CC) -fpie -o $@ badsum.o md5.o sha1.o

md5.o: md5.asm
	fasm $(FASM_FLAGS) $< 

sha1.o: sha1.asm
	fasm $(FASM_FLAGS) $< 

clean:
	$(RM) badsum badsum.o md5.o sha1.o
