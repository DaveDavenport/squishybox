#!/bin/bash
valac test.vala MpdInteraction.vala --pkg=libmpdclient  --vapidir=./vapi/ --pkg=sdl --pkg=sdl-image --pkg=sdl-ttf --Xcc="-lSDL_ttf"    --Xcc="-lSDL_image"  --thread -C 
