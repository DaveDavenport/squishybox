#!/bin/bash
valac test.vala MpdInteraction.vala IREvent.vala --pkg=libmpdclient --pkg=linux --pkg=posix --vapidir=./vapi/ --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread 
