CC := gcc

CFLAGS := $(shell pkg-config sdl2 --cflags)

SRCDIR := src/
OBJDIR := build/obj/

NAME := gpugol

SFILES := c
OFILES := o

LIBS := -lSDL2 -lOpenCL -lm

SOURCES := $(shell find $(SRCDIR) -name "*.$(SFILES)")
OBJECTS := $(patsubst $(SRCDIR)%.$(SFILES), $(OBJDIR)%.$(OFILES), $(SOURCES))

all: directories $(NAME)

directories:
	mkdir -p $(OBJDIR)
	mv $(NAME)_backup $(NAME)_backup1
	mv $(NAME) $(NAME)_backup

$(NAME): $(OBJECTS)
	$(CC) $^ $(LIBS) -o $@
$(OBJDIR)%$(OFILES): $(SRCDIR)%$(SFILES)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	mv $(NAME)_backup $(NAME)_backup1
	mv $(NAME) $(NAME)_backup
	rm -rf $(OBJDIR)		