# AS TESTING

#   ---     ---     ---     ---     ---

DIRS = $(shell find $(BASE_DIR) -type d)

CSRC = $(wildcard $(DIRS:%=%/*.c))
ASRC = $(wildcard $(DIRS:%=%/*.asm))

COBJ = $(patsubst %.c,%.o,$(ASRC))
AOBJ = $(patsubst %.asm,%.o,$(ASRC))

.PHONY: asm

as: $(AOBJ)
#	@ld $(AOBJ) -o hello.exe

# well, might have to sieve between coff & pe later on!
# for now lets just make them all executables and no linking
$(AOBJ): $(ASRC)
	@fasm $<
#$@

#   ---     ---     ---     ---     ---
