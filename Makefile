QUIET=@
#@
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
SOURCES=\
	$(wildcard SRC/*.vala)\
	$(wildcard SRC/**/*.vala)

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
OUTPUT=$(BUILD_DIR)/$(PROGRAM)

LIBS+=-lSDL_ttf 

##################################################################################
##          Pre-processing above information                                    ##
##################################################################################

##
# Make right syntax for vala
##
VALA_PKG=$(foreach p,$(VALA_PACKAGES) $(PKGCONFIG_PACKAGES),--pkg=$p)
VAPI_DIRS=$(foreach p,$(VAPI_DIR), --vapidir=$p)

##
# Check if packages are available
##
PACKAGES_EXISTS=$(shell pkg-config --exists $(PKGCONFIG_PACKAGES); echo $$?)
ifeq ($(PACKAGES_EXISTS),0)
    $(info ** $(PKGCONFIG_PACKAGES) packages found)
else
    $(error One or more packages missing from: $(PKGCONFIG_PACKAGES))
endif

PKG_CFLAGS=$(shell pkg-config --cflags $(PKGCONFIG_PACKAGES) gobject-2.0 gthread-2.0 )
PKG_LIBS=$(shell pkg-config --libs $(PKGCONFIG_PACKAGES) gobject-2.0 gthread-2.0)


C_SOURCES=$(foreach p,$(SOURCES:.vala=.c),$(SOURCE_DIR)/$p)
FVAPI_SOURCES=$(foreach p,$(SOURCES:.vala=.vapi),$(SOURCE_DIR)/$p)
FVAPI_SOURCES_STAMP=$(foreach p,$(SOURCES:.vala=.vapi.stamp),$(SOURCE_DIR)/$p)
FVAPI_SOURCES_DEPS=$(foreach p,$(SOURCES:.vala=.dep),$(SOURCE_DIR)/$p)

DIR_SOURCES=$(foreach p,$(SOURCES), $(SOURCE_DIR)/$(dir $p))
BUILD_DIR_SOURCES=$(foreach p,$(SOURCES), $(BUILD_DIR)/$(dir $p))

all: $(OUTPUT) 

# tell it not to remove the stamp files, this way we can avoid even more re-builds
.SECONDARY: $(FVAPI_SOURCES_STAMP)

$(BUILD_DIR):
	$(info Create '$@' Directory)
	$(QUIET)mkdir -p '$@'
	$(QUIET) mkdir -p $(BUILD_DIR_SOURCES)

$(SOURCE_DIR):
	$(info Create '$@' Directory)
	$(QUIET)mkdir -p '$@'
	$(QUIET) mkdir -p $(DIR_SOURCES)


$(SOURCE_DIR)/%.vapi.stamp: %.vala | $(SOURCE_DIR)
	$(info Create fast vapi file: $@)
	$(QUIET) $(VALAC) --fast-vapi=$(@:.stamp=) $<  && touch $@


$(SOURCE_DIR)/%.dep: %.vala | $(FVAPI_SOURCES_STAMP)
	$(info Create dep and C file: $@)
	$(QUIET) $(VALAC) -C --deps=$@ $(addprefix --use-fast-vapi=,$(subst $(@:.dep=.vapi),,$(FVAPI_SOURCES))) $(VAPI_DIRS) $(VALA_PKG) $(VALA_FLAGS) -D PC -d $(SOURCE_DIR) $<

-include $(FVAPI_SOURCES_DEPS)

OBJECT_FILES=$(foreach p,$(SOURCES:.vala=.o),$(BUILD_DIR)/$p)


$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c | $(BUILD_DIR)
	$(info create object file $@)
	$(QUIET) $(CC) $(PKG_CFLAGS) $(CFLAGS)  -g -c  $< -o $@

$(OUTPUT): $(OBJECT_FILES) | $(BUILD_DIR)
	$(info Linking..... $@)
	$(QUIET) $(CC)  $^ $(LIBS) $(PKG_LIBS) $(CFLAGS) $(PKG_CFLAGS)-o $@


source:  $(SOURCES) $(SOURCE_DIR)
	$(info Creating source files: '$(SOURCES)')
	$(QUIET) $(VALAC) $(SOURCES)  $(VAPI_DIRS) $(VALA_PKG) $(VALA_FLAGS) -C -d $(SOURCE_DIR)
##
# Run it.
##
.PHONY: run
run: $(OUTPUT)
	$(OUTPUT)

##
# Clean up
##
clean:
	 $(info Removing $(BUILD_DIR) and $(SOURCE_DIR))
	$(QUIET) @rm -rf $(BUILD_DIR) $(SOURCE_DIR)


.PHONY: doc
doc:
	valadoc --package-name=SDLMpc  --force --no-protected --internal --private -b ./ --doclet=html -o doc/api-html *.vala $(VAPI_DIRS) $(VALA_PKG)
