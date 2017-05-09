# Makefile for DiskSim edit by NMSU Data Storage Lab

# default parameters
DEFAULT_DIXTRAC         = yes
DEFAULT_SSD             = yes
DEFAULT_ARCH64          = yes
DEFAULT_STD             = gnu90
DEFAULT_OPTIMIZE        = 2
DEFAULT_TOLERANT        = yes
DEFAULT_INSTALLDIR      = bin
DEFAULT_PATCHSYTHDEVS   = yes
DEFAULT_PRINTMAPREQUEST = yes

# URLs with source, extension and patches
URL_DISKSIM_BASE    = http://www.pdl.cmu.edu/PDL-FTP/DriveChar/disksim-4.0.tar.gz
URL_DISKSIM_DIXTRAC = http://www.pdl.cmu.edu/PDL-FTP/DriveChar/disksim-4.0-with-dixtrac.tar.gz
URL_SSD             = https://download.microsoft.com/download/9/7/A/97A84DF6-E0F6-4F52-AEAB-C5AE453CE61D/ssd-add-on.zip
URL_ARCH64          = https://github.com/myidpt/PFSsim/archive/master.zip

# local directories
DIR_PATCH           = patches
DIR_SRC             = src
DIR_BUILD           = build
INSTALLDIR          = $(DEFAULT_INSTALLDIR)
DIR_DISKSIM         = $(DIR_BUILD)/disksim-4.0
DIR_SSD             = $(DIR_DISKSIM)/ssdmodel
DIR_ARCH64          = $(DIR_BUILD)/PFSsim-master

# downloaded files
FILE_DISKSIM        = $(DIR_SRC)/$(notdir $(URL_DISKSIM))
FILE_SSD            = $(DIR_SRC)/$(notdir $(URL_SSD))
FILE_ARCH64         = $(DIR_SRC)/$(notdir $(URL_ARCH64))

# other files
EXEC                = $(DIR_DISKSIM)/src/disksim
PATCHED             = $(DIR_BUILD)/.patched

# commands
MAKE                = make
CHMOD               = chmod
CURL                = curl -skLO
UNTAR               = tar xzf
RMDIR               = rm -rf
MKDIR               = mkdir -p
UNZIP               = unzip -o -q
PATCH               = patch -p1
SED                 = sed
FIND                = find
OD                  = od -c
GREP                = grep
SPLITDIFF           = splitdiff -ad
RMFILE              = rm -f
CP                  = cp -a
LS                  = ls -l
STRIP               = strip
TOUCH               = touch
FILE_CMD            = file -ib
ECHO                = @/bin/echo -e
TITLE               = @/bin/echo -en "\n$(COLOR_TITLE)"; /bin/echo -n
SUCCESS             = @/bin/echo -en "\n$(COLOR_OK)"; /bin/echo -n
END                 = ; /bin/echo -e "$(COLOR_NONE)"

# colors
COLOR_NONE          = \x1b[0m
COLOR_TITLE         = \x1b[33;01m
COLOR_SUMMARY       = \x1b[35;01m
COLOR_OK            = \x1b[32;01m

# dynamic target lists
SOURCES             = summary $(DIR_DISKSIM)
VALIDATION_TESTS    = $(DIR_DISKSIM)/valid/runvalid $(DIR_DISKSIM)/valid/memsvalid

# set options to defaults
DIXTRAC             = $(DEFAULT_DIXTRAC)
SSD                 = $(DEFAULT_SSD)
ARCH64              = $(DEFAULT_ARCH64)
STD                 = $(DEFAULT_STD)
OPTIMIZE            = $(DEFAULT_OPTIMIZE)
TOLERANT            = $(DEFAULT_TOLERANT)
PATCHSYTHDEVS       = $(DEFAULT_PATCHSYTHDEVS)
PRINTMAPREQUEST     = $(DEFAULT_PRINTMAPREQUEST)

# ignore patch failures?
ifeq ($(TOLERANT), yes)
  IGNORE_PATCH_FAILURE = || true
else ifeq ($(TOLERANT), no)
  IGNORE_PATCH_FAILURE =
else
  $(error Invalid TOLERANT=$(TOLERANT). Use TOLERANT=yes or TOLERANT=no)
endif

# use DIXtrac sources?
ifeq ($(DIXTRAC), yes)
  URL_DISKSIM = $(URL_DISKSIM_DIXTRAC)
else ifeq ($(DIXTRAC), no)
  URL_DISKSIM = $(URL_DISKSIM_BASE)
else
  $(error Invalid DIXTRAC=$(DIXTRAC). Use DIXTRAC=yes or DIXTRAC=no)
endif

# use SSD patch?
ifeq ($(SSD), yes)
  SOURCES := $(SOURCES) $(DIR_SSD)
  ifeq ($(DIXTRAC), yes)
    SOURCES := $(SOURCES) patch_ssd_dixtrac
  endif
  VALIDATION_TESTS := $(VALIDATION_TESTS) $(DIR_SSD)/valid/runvalid
else ifeq ($(SSD), no)
else
  $(error Invalid SSD=$(SSD). Use SSD=yes or SSD=no)
endif

# use 64b patch?
ifeq ($(ARCH64), yes)
  SOURCES := $(SOURCES) patch_arch64
  ifeq ($(SSD), yes)
    SOURCES := $(SOURCES) patch_arch64_ssd
  endif
  SOURCES := $(SOURCES) patch_arch64_after
  ifeq ($(DIXTRAC), yes)
    SOURCES := $(SOURCES) patch_arch64_after_dixtrac
  endif
else ifeq ($(ARCH64), no)
else
  $(error Invalid ARCH64=$(ARCH64). Use ARCH64=yes or ARCH64=no)
endif

# patch loadsythdevs?
ifeq ($(PATCHSYTHDEVS), yes)
  SOURCES := $(SOURCES) patch_loadsynthdevs
else ifeq ($(PATCHSYTHDEVS), no)
else
  $(error Invalid PATCHSYTHDEVS=$(PATCHSYTHDEVS). Use PATCHSYTHDEVS=yes or PATCHSYTHDEVS=no)
endif

# print maprequests?
ifeq ($(PRINTMAPREQUEST), yes)
  SOURCES := $(SOURCES) patch_printmaprequests
else ifeq ($(PRINTMAPREQUEST), no)
else
  $(error Invalid PRINTMAPREQUEST=$(PRINTMAPREQUEST). Use PRINTMAPREQUEST=yes or PRINTMAPREQUEST=no)
endif

# enforce C standard?
ifneq ($(strip $(STD)),)
  SOURCES := $(SOURCES) enforce_c_standard
endif

# enforce C optimization?
ifneq ($(strip $(OPTIMIZE)),)
  SOURCES := $(SOURCES) enforce_c_optimize
endif

# main
.DEFAULT: all
.PHONY: all
all: sources compile install

# create folders
$(DIR_SRC) $(DIR_BUILD) $(INSTALLDIR):
	$(MKDIR) '$@'

# prepare sources
.PHONY: sources
sources: avoid_double_patching $(SOURCES)
	@$(TOUCH) '$(PATCHED)'
	$(SUCCESS) 'OK, patched: $(DIR_DISKSIM)' $(END)

.PHONY: avoid_double_patching
avoid_double_patching:
	@test \! -f '$(PATCHED)'

# print summary build configuration
.PHONY: summary
summary:
	$(ECHO)
	$(ECHO) "$(COLOR_SUMMARY)Build configuration:$(COLOR_NONE)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Use DiskSim with DIXtrac:    $(DIXTRAC)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Use Microsoft SSD extension: $(SSD)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Use Oliver Liu 64bit patch:  $(ARCH64)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Patch loadsynthdevs():       $(PATCHSYTHDEVS)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Print map requests:          $(PRINTMAPREQUEST)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Enforce C standard:          $(STD)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Enforce C optimization:      $(OPTIMIZE)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Ignore patch failures:       $(TOLERANT)"
	$(ECHO) "  $(COLOR_SUMMARY)*$(COLOR_NONE) Install dir for binaries:    $(INSTALLDIR)"
	$(ECHO)


# DiskSim
$(FILE_DISKSIM): | $(DIR_SRC)
	$(TITLE) '[DISKSIM] Download $(notdir $@) ...' $(END)
	cd '$|' && $(CURL) '$(URL_DISKSIM)'

$(DIR_DISKSIM): $(FILE_DISKSIM) | $(DIR_BUILD)
	$(TITLE) '[DISKSIM] Unpack $(notdir $<) ...' $(END)
	cd '$|' && $(UNTAR) '../$<'


# SSD extension
$(FILE_SSD): | $(DIR_SRC)
	$(TITLE) '[SSD] Download $(notdir $@) ...' $(END)
	cd '$|' && $(CURL) '$(URL_SSD)'

$(DIR_SSD): $(FILE_SSD) | $(DIR_BUILD)
	$(TITLE) '[SSD] Unpack $(notdir $<) ...' $(END)
	cd '$(DIR_DISKSIM)' && $(UNZIP) '../../$<'
	$(RMFILE) '$(DIR_DISKSIM)/SSD Extension '*.txt
	$(TITLE) '[SSD] Remove DOS newlines ...' $(END)
	@for f in `$(FIND) '$(DIR_SSD)' -type f \( -name '*.[hcd]' -o -name ssd-patch \)| sort`; do \
	  { $(OD) "$$f" | $(GREP) -q '\\r'; } || continue; \
	  echo "$(SED) -i 's/\\\\r$$//' $$f"; \
    $(SED) -i 's/\r$$//' "$$f"; \
	done
	$(TITLE) '[SSD] Patch with $(notdir $(DIR_SSD))/ssd-patch ...' $(END)
	cd '$(DIR_DISKSIM)' && $(PATCH) <'$(notdir $(DIR_SSD))/ssd-patch' $(IGNORE_PATCH_FAILURE)

.PHONY: patch_ssd_dixtrac
patch_ssd_dixtrac: $(DIR_PATCH)/ssd-dixtrac.patch
	$(TITLE) '[SSD,DIXTRAC] Patch with $< ...' $(END)
	cd '$(DIR_DISKSIM)' && $(PATCH) <'../../$<' $(IGNORE_PATCH_FAILURE)


# Arch64 patch
$(FILE_ARCH64): | $(DIR_SRC)
	$(TITLE) '[ARCH64] Download $(notdir $@) ...' $(END)
	cd '$|' && $(CURL) '$(URL_ARCH64)'

$(DIR_ARCH64): $(FILE_ARCH64)
	$(TITLE) '[ARCH64] Unpack $(notdir $<) ...' $(END)
	cd '$(DIR_BUILD)' && $(UNZIP) '../$<'
	$(TITLE) '[ARCH64] Split patch 64bit-with-dixtrac-ssd-patch ...' $(END)
	cd '$(DIR_ARCH64)' && $(SPLITDIFF) disksim/64bit-ssd-patch-files/patch-files/64bit-with-dixtrac-ssd-patch
	$(RMFILE) '$(DIR_ARCH64)'/disksim-4.0_dixtrac_*

.PHONY: patch_arch64
patch_arch64: | $(DIR_ARCH64)
	$(TITLE) '[ARCH64] Patch for 64bit ...' $(END)
	cd '$(DIR_DISKSIM)' && cat $$($(FIND) '../../$|' -name 'disksim-4.0_*' -a \! -name 'disksim-4.0_ssdmodel_*' | sort) | $(PATCH) $(IGNORE_PATCH_FAILURE)
	$(TITLE) '[ARCH64] Copy physim_driver ...' $(END)
	$(CP) '$|'/disksim/64bit-ssd-patch-files/modified-source-files/src/physim_driver.? '$(DIR_DISKSIM)'/src/

.PHONY: patch_arch64_ssd
patch_arch64_ssd: | $(DIR_ARCH64)
	$(TITLE) '[ARCH64,SSD] Patch for 64bit ssd ...' $(END)
	cd '$(DIR_DISKSIM)' && cat '../../$|'/disksim-4.0_ssdmodel_* | $(PATCH) $(IGNORE_PATCH_FAILURE)

.PHONY: patch_arch64_after
patch_arch64_after: $(DIR_PATCH)/64bit.patch
	$(TITLE) '[ARCH64] Patch with $< ...' $(END)
	cd '$(DIR_DISKSIM)' && $(PATCH) <'../../$<' $(IGNORE_PATCH_FAILURE)

.PHONY: patch_arch64_after_dixtrac
patch_arch64_after_dixtrac: $(DIR_PATCH)/64bit-dixtrac.patch
	$(TITLE) '[ARCH64,DIXTRAC] Patch with $< ...' $(END)
	cd '$(DIR_DISKSIM)' && $(PATCH) <'../../$<' $(IGNORE_PATCH_FAILURE)

.PHONY: enforce_c_standard
enforce_c_standard:
	$(TITLE) '[DISKSIM] Enforce C standard $(STD) ...' $(END)
	@for f in $$($(GREP) -rl '^CFLAGS *=' $$($(FIND) '$(DIR_DISKSIM)' -type f -name Makefile)); do \
		echo "$(SED) -i 's/^\\(CFLAGS[^=]*=\\)/\\\1-std=$(STD) /' $$f"; \
		$(SED) -i 's/^\(CFLAGS[^=]*=\)/\1-std=$(STD) /' "$$f"; \
	done

.PHONY: enforce_c_optimize
enforce_c_optimize:
	$(TITLE) '[DISKSIM] Enforce C optimization $(OPTIMIZE) ...' $(END)
	@for f in $$($(GREP) -rl '^CFLAGS *=' $$($(FIND) '$(DIR_DISKSIM)' -type f -name Makefile)); do \
		echo "$(SED) -i 's/^\\(CFLAGS[^=]*=\\)/\\\1-O$(OPTIMIZE) /' $$f"; \
		$(SED) -i 's/^\(CFLAGS[^=]*=\)/\1-O$(OPTIMIZE) /' "$$f"; \
	done

.PHONY: patch_loadsynthdevs
patch_loadsynthdevs: $(DIR_PATCH)/loadsynthdevs.patch
	$(TITLE) '[DISKSIM] Patch with $< ...' $(END)
	cd '$(DIR_DISKSIM)' && $(PATCH) <'../../$<' $(IGNORE_PATCH_FAILURE)

.PHONY: patch_printmaprequests
patch_printmaprequests: $(DIR_PATCH)/printmaprequests.patch
	$(TITLE) '[DISKSIM] Patch with $< ...' $(END)
	cd '$(DIR_DISKSIM)' && $(PATCH) <'../../$<' $(IGNORE_PATCH_FAILURE)

# compile disksim
.PHONY: compile
compile $(EXEC): $(PATCHED) | $(DIR_DISKSIM)
	$(TITLE) '[DISKSIM] Compile ...' $(END)
	$(CHMOD) +x '$|/libparam/'*.pl
	$(MAKE) -C '$|'
	test -x '$(EXEC)'
	$(SUCCESS) 'OK, compiled $(EXEC)' $(END)


# install
.PHONY: install
install: $(EXEC) | $(INSTALLDIR)
	$(TITLE) '[DISKSIM] Install binaries ...' $(END)
	@for f in $$($(FIND) $(DIR_DISKSIM)/src $(DIR_DISKSIM)/dixtrac $(DIR_DISKSIM)/memsmodel -maxdepth 1 -type f -executable); do \
	  case "$$($(FILE_CMD) "$$f")" in \
  	  'application/x-executable'*) \
         echo "$(CP) $$f $|/"; \
         $(CP) "$$f" '$|'/;; \
    esac; \
	done;
	cd '$|' && $(STRIP) *
	$(SUCCESS) 'OK, installed binaries:' $(END)
	@$(LS) '$(INSTALLDIR)/'* | $(GREP) -v '^total'
	$(ECHO)


# tests
.PHONY: test
test: | $(VALIDATION_TESTS)

.PHONY: $(VALIDATION_TESTS)
$(VALIDATION_TESTS): $(EXEC)
	$(TITLE) '[DISKSIM] Run validation test $@ ...' $(END)
	cd '$(dir $@)' && sh '$(notdir $@)'


# clean
.PHONY: clean
clean:
	$(RMDIR) '$(DIR_BUILD)' '$(PATCHED)'

.PHONY: distclean
distclean: | clean
	$(RMDIR) '$(DIR_SRC)'


# help
.PHONY: help
help:
	$(ECHO) '$(COLOR_OK)Make patched DiskSim$(COLOR_NONE)'
	$(ECHO)
	$(ECHO) '$(COLOR_TITLE)Usage:$(COLOR_NONE)'
	$(ECHO) '  make [options] [target ...]'
	$(ECHO)
	$(ECHO) '$(COLOR_TITLE)Options:$(COLOR_NONE)'
	$(ECHO) '          DIXTRAC=yes|no ... use DiskSim with DIXtrac        (by default: $(DEFAULT_DIXTRAC))'
	$(ECHO) '              SSD=yes|no ... use Microsoft SSD extension     (by default: $(DEFAULT_SSD))'
	$(ECHO) '           ARCH64=yes|no ... use Oliver Liu 64bit patch      (by default: $(DEFAULT_ARCH64))'
	$(ECHO) '    PATCHSYTHDEVS=yes|no ... patch loadsynthdevs()           (by default: $(DEFAULT_PATCHSYTHDEVS))'
	$(ECHO) '  PRINTMAPREQUEST=yes|no ... print map requests              (by default: $(DEFAULT_PRINTMAPREQUEST))'
	$(ECHO) '            STD=<string> ... enforce C standard thru -std=   (by default: $(DEFAULT_STD))'
	$(ECHO) '       OPTIMIZE=<string> ... enforce C optimization thru -O  (by default: $(DEFAULT_OPTIMIZE))'
	$(ECHO) '         TOLERANT=yes|no ... ignore patch failures           (by default: $(DEFAULT_TOLERANT))'
	$(ECHO) '        INSTALLDIR=<dir> ... dir to install binaries         (by default: $(DEFAULT_INSTALLDIR))'
	$(ECHO)
	$(ECHO) '$(COLOR_TITLE)Targets:$(COLOR_NONE)'
	$(ECHO) '          all ......... make sources, compile and install'
	$(ECHO) '          sources ..... download sources to $(COLOR_SUMMARY)$(DIR_SRC)/$(COLOR_NONE)'
	$(ECHO) '          compile ..... compile disksim in $(COLOR_SUMMARY)$(DIR_DISKSIM)/$(COLOR_NONE)'
	$(ECHO) '          install ..... install binaries to $(COLOR_SUMMARY)$(INSTALLDIR)/$(COLOR_NONE)'
	$(ECHO) '          test ........ run valadation tests'
	$(ECHO) '          clean ....... delete $(COLOR_SUMMARY)$(DIR_BUILD)/$(COLOR_NONE)'
	$(ECHO) '          distclean ... delete also $(COLOR_SUMMARY)$(DIR_SRC)/$(COLOR_NONE)'
	$(ECHO) '          help ........ print this help screen'
	$(ECHO)
