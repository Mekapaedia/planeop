CC=gcc
STD=-std=c99
LIBS=-lm $(ADDLIBS)
SRC=fuseop.c
OBJ=$(SRC:.c=.o)
EXE=fuseop

all: $(SRC) $(EXE)

$(EXE): $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) -o $@ $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

clean: 
	rm -rf $(SRC:.c=.gcno) $(SRC:.c=.gcda) $(SRC:.c=.gcov) $(OBJ)
	rm -rf gmon.out $(EXE)
