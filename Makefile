VALAC=valac
PROGRAMS=sdlmpc

sdlmpc_SOURCES=\
	$(wildcard *.vala)

all: sdlmpc
.PHONY: debug

debug: $(sdlmpc_SOURCES)
	$(VALAC) -o $@ $^ --pkg=libmpdclient --pkg=linux --pkg=posix --vapidir=./vapi/ --pkg=glib-2.0 --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread -D PC -D SHOW_REDRAW 

sdlmpc: $(sdlmpc_SOURCES)
	$(VALAC) -o $@ $^ --pkg=libmpdclient --pkg=linux --pkg=posix --vapidir=./vapi/ --pkg=glib-2.0 --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread -D PC 

source:  $(sdlmpc_SOURCES)
	$(VALAC) $^ --pkg=libmpdclient --pkg=linux --pkg=posix --vapidir=./vapi/ --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread -C 

clean:
	@rm $(PROGRAMS)
	@rm $(sdlmpc_SOURCES:.vala=.c)


.PHONY: doc
doc:
	valadoc --package-name=SDLMpc  --force --no-protected --internal --private -b ./ --doclet=html -o doc/api-html *.vala --vapidir=./vapi/ --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --pkg=linux --pkg=posix --pkg=libmpdclient
