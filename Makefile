CFLAGS=-O0
FILES=main.c grasm_interpreter.S

.PHONY: clean
all: debug

main: $(FILES)
	$(CC) $(CFLAGS) -o $@ $^

debug: $(FILES)
	$(CC) -O0 -g -o $@ $^
	 
clean:
	rm -rf main