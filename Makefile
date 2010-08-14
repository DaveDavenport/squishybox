VALAC=valac
PROGRAMS=sdlmpc

sdlmpc_SOURCES=\
	$(wildcard *.vala)

sdlmpc: $(sdlmpc_SOURCES)
	$(VALAC) -o $@ $^ --pkg=libmpdclient --pkg=linux --pkg=posix --vapidir=./vapi/ --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread -D PC 

source:  $(sdlmpc_SOURCES)
	$(VALAC) $^ --pkg=libmpdclient --pkg=linux --pkg=posix --vapidir=./vapi/ --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread -C 

clean:
	@rm $(PROGRAMS)
	@rm $(sdlmpc_SOURCES:.vala=.c)
