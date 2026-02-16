AS=nasm
ASFLAGS=-felf64 -g -F dwarf
LD=ld
LDFLAGS=

BINARY_NAME=server

SHARED_FILES=functions.asm print.asm
SHARED_OBJS=$(SHARED_FILES:.asm=.o)

PROJECT_FILES=server.asm socket.asm handle_client.asm http.asm
PROJECT_OBJS=$(PROJECT_FILES:.asm=.o)

all: $(PROJECT_OBJS) $(SHARED_OBJS)
	$(LD) $(LDFLAGS) -o $(BINARY_NAME) $^

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

libs: functions.asm print.asm
	$(AS) $(ASFLAGS) functions.asm
	$(AS) $(ASFLAGS) print.asm

clean:
	rm -f *.o
	rm $(BINARY_NAME)
