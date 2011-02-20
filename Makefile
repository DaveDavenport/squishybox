QUIET=@
#
# Vala compiler binary
#
VALAC=valac

#
# Program name
#
PROGRAM=sdlmpc

#
# Source files
#
sdlmpc_SOURCES=\
	$(wildcard *.vala)

#
# Directory where source files should be dumped
#
SOURCE_DIR=build/sources

#
# Directory where binary is placed
#
BUILD_DIR=build/binary

#
# PKG_CONFIG packages that should be used
#
PKGCONFIG_PACKAGES=\
    glib-2.0\
    sdl\
    SDL_image\
    libmpdclient\

#
# Other vala binding that should be used
#
VALA_PACKAGES=\
    linux\
    sdl-ttf\
    posix

#
# Where extra vapi files are located
#
VAPI_DIR=\
	vapi

##
# Vala Flags
# Manually add -lSDL_ttf, because that seems to be missing.
##
VALA_FLAGS=--thread --Xcc="-lSDL_ttf"

##################################################################################
##          Pre-processing above information                                    ##
##################################################################################

##
# Make right syntax for vala
##
VALA_PKG=$(foreach p,$(VALA_PACKAGES) $(PKGCONFIG_PACKAGES),--pkg=$p)

##
# Check if packages are available
##
PACKAGES_EXISTS=$(shell pkg-config --exists $(PKGCONFIG_PACKAGES); echo $$?)
ifeq ($(PACKAGES_EXISTS),0)
    $(info All $(PKGCONFIG_PACKAGES) packages found)
else
    $(error One or more packages missing from: $(PKGCONFIG_PACKAGES))
endif




all: $(PROGRAM) 


$(BUILD_DIR):
	$(info Create '$@' Directory)
	$(QUIET)mkdir -p '$@'

$(PROGRAM): $(sdlmpc_SOURCES) $(BUILD_DIR)
	$(info Building source files: '$(sdlmpc_SOURCES)')
	$(QUIET) $(VALAC) -o $@ $(sdlmpc_SOURCES)  --vapidir=$(VAPI_DIR)  $(VALA_PKG) $(VALA_FLAGS) -D PC -d $(BUILD_DIR)

$(SOURCE_DIR):
	$(info Create '$@' Directory)
	$(QUIET)mkdir -p '$@'

source:  $(sdlmpc_SOURCES) $(SOURCE_DIR)
	$(info Creating source files: '$(sdlmpc_SOURCES)')
	$(QUIET) $(VALAC) $(sdlmpc_SOURCES)  --vapidir=$(VAPI_DIR) $(VALA_PKG) $(VALA_FLAGS) -C -d $(SOURCE_DIR)

clean:
	 $(info Removing $(BUILD_DIR) and $(SOURCE_DIR))
	$(QUIET) @rm -r $(BUILD_DIR) $(SOURCE_DIR)


.PHONY: doc
doc:
	valadoc --package-name=SDLMpc  --force --no-protected --internal --private -b ./ --doclet=html -o doc/api-html *.vala --vapidir=$(VAPI_DIR) $(VALA_PKG)
