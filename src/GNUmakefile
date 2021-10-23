# AS TESTING

#   ---     ---     ---     ---     ---

DIRS = $(shell find $(BASE_DIR) -type d)

CSRC = $(wildcard $(DIRS:%=%/*.c))
ASRC = $(wildcard $(DIRS:%=%/*.asm))

COBJ = $(patsubst %.c,%.o,$(ASRC))
AOBJ = $(patsubst %.asm,%.o,$(ASRC))

.PHONY: asm

as: $(AOBJ)
	@gcc $(AOBJ) -o a.exe

# intel sucks but I can't argue with cleaner asm syntax

$(AOBJ): $(ASRC)
	@as --64 -msyntax=intel -mnaked-reg $< -o $@

#   ---     ---     ---     ---     ---
