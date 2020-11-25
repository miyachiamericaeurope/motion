################################################################################
# Makefile for Motion                                                          #
################################################################################
# Copyright 2000 by Jeroen Vreeken                                             #
#                                                                              #
# This program is published under the GNU public license version 2.0 or later. #
# Please read the file COPYING for more info.                                  #
################################################################################
# Please visit the Motion home page:                                           #
# https://motion-project.github.io/                                            #
################################################################################

CC      = gcc
INSTALL = install
INSTALL_DATA = ${INSTALL} -m 644

################################################################################
# Install locations, controlled by setting configure flags.                    #
################################################################################
prefix      = /usr/local
exec_prefix = ${prefix}
bindir      = ${exec_prefix}/bin
mandir      = ${datarootdir}/man
sysconfdir  = ${prefix}/etc
datadir     = ${datarootdir}
datarootdir = ${prefix}/share
docdir      = $(datadir)/doc/motion
examplesdir = $(datadir)/motion/examples
localedir   = ${datarootdir}/locale

################################################################################
# These variables contain compiler flags, object files to build and files to   #
# install.                                                                     #
################################################################################
CFLAGS       =  -g -O2 -D_THREAD_SAFE  -Wall \
	 -DVERSION=\"4.2.2\" \
	 -Dsysconfdir=\"$(sysconfdir)\"  \
	 -DLOCALEDIR=\"$(DESTDIR)$(localedir)\"    \
	 -DMOTIONDOCDIR=\"$(DESTDIR)$(docdir)\"    \
	 -I/usr/include/arm-linux-gnueabihf   -std=gnu99 -DHAVE_MMAL -Irasppicam -I/opt/vc/include
LDFLAGS      =  
LIBS         = -lm  -pthread -ljpeg -lmicrohttpd   -L/opt/vc/lib -lmmal_core -lmmal_util -Wl,--push-state,--no-as-needed -lmmal_vc_client -Wl,--pop-state -lvcos -lvchostif -lvchiq_arm -lavutil -lavformat -lavcodec -lswscale  -lavdevice  
OBJ          = motion.o logger.o conf.o draw.o jpegutils.o \
			   video_loopback.o video_v4l2.o video_common.o video_bktr.o \
			   netcam.o netcam_http.o netcam_ftp.o netcam_jpeg.o netcam_wget.o \
			   track.o alg.o event.o picture.o rotate.o translate.o \
			   webu.o webu_html.o webu_text.o webu_stream.o \
			   stream.o md5.o netcam_rtsp.o ffmpeg.o \
			   mmalcam.o raspicam/RaspiCamControl.o raspicam/RaspiCLI.o 
SRC          = $(foreach obj,$(OBJ:.o=.c),./$(obj))
DOC          = CHANGELOG COPYING CREDITS README.md  \
			   motion_guide.html motion_stylesheet.css \
			   motion_config.html motion_build.html \
			   mask1.png normal.jpg outputmotion1.jpg outputnormal1.jpg
DOC_FILES    = $(foreach doc,$(DOC),./$(doc))
EXAMPLES     = *.conf motion.service
EXAMPLES_BIN = motion.init-Debian motion.init-FreeBSD.sh
PROGS        = motion
DEPEND_FILE  = .depend
LANGCDS      =  da de es fi fr it ja ko li nl no pt sv zh

################################################################################
# ALL and PROGS build Motion and, possibly, Motion-control.                    #
################################################################################
all: progs
ifeq ("Linux","Linux")
	@echo "Build complete, run \"make install\" to install Motion!"
else
	@echo "Build complete, run \"gmake install\" to install Motion!"
endif
	@echo

progs: pre-build-info $(PROGS) convert-po

################################################################################
# Convert the po translation files into mo files                               #
################################################################################
convert-po:
ifeq ("yes","yes")
	@echo Performing the conversion of .po to .mo files
	@for lng in $(LANGCDS); \
	do \
	  msgfmt ./po/$$lng.po -o ./po/$$lng.mo  ;   \
	  if [ $$? -ne 0 ]; then exit 1; fi; \
	done
else
	@echo Skipping translations
endif
	@echo

################################################################################
# PRE-BUILD-INFO outputs some general info before the build process starts.    #
################################################################################
pre-build-info:
	@echo "Welcome to the setup procedure for Motion, the motion detection daemon! If you get"
	@echo "error messages during this procedure, please report them to the mailing list. The"
	@echo "Motion Guide contains all information you should need to get Motion up and running."
	@echo
	@echo "Version: 4.2.2"
ifeq ("Linux","Linux")
	@echo "Platform: Linux (if this is incorrect, please read README.FreeBSD)"
else
	@echo "Platform: *BSD/Darwin"
endif
	@echo

################################################################################
# MOTION builds motion. MOTION-OBJECTS and PRE-MOBJECT-INFO are helpers.       #
################################################################################
motion: motion-objects
	@echo "Linking Motion..."
	@echo "--------------------------------------------------------------------------------"
	$(CC) $(LDFLAGS) -o $@ $(OBJ) $(LIBS)
	@echo "--------------------------------------------------------------------------------"
	@echo "Motion has been linked."
	@echo

motion-objects: dep pre-mobject-info $(OBJ)
	@echo "--------------------------------------------------------------------------------"
	@echo "Motion object files compiled."
	@echo

pre-mobject-info:
	@echo "Compiling Motion object files..."
	@echo "--------------------------------------------------------------------------------"

################################################################################
# Define the compile command for C files.                                      #
################################################################################
%.o: ./%.c
	@echo -e "\tCompiling $< into $@..."
	@$(CC) -c $(CFLAGS) -I. $< -o $@

################################################################################
# Include the dependency file if it exists.                                    #
################################################################################
ifeq ($(DEPEND_FILE), $(wildcard $(DEPEND_FILE)))
ifeq (,$(findstring clean,$(MAKECMDGOALS)))
-include $(DEPEND_FILE)
endif
endif

################################################################################
# Make the dependency file depend on all header files and all relevant source  #
# files. This forces the file to be re-generated if the source/header files    #
# change. Note, however, that the existing version will be included before     #
# re-generation.                                                               #
################################################################################
$(DEPEND_FILE): *.h $(SRC)
	@echo "Generating dependencies, please wait..."
	@$(CC) $(CFLAGS) -I. -M $(SRC) > .tmp
	@mv -f .tmp $(DEPEND_FILE)
	@echo

################################################################################
# DEP, DEPEND and FASTDEP generate the dependency file.                        #
################################################################################
dep depend fastdep: $(DEPEND_FILE)

################################################################################
# DEV, BUILD with developer flags                                              #
################################################################################
dev: distclean autotools all

autotools:
	autoconf
	./configure --with-developer-flags

set-version:
	autoconf
	./configure --with-developer-flags

help:
	@echo "--------------------------------------------------------------------------------"
	@echo "make                   Build motion from local copy in your computer"
	@echo "make current           Build last version of motion from svn"
	@echo "make dev               Build motion with dev flags"
	@echo "make dev-git           Build motion with dev flags for git"
	@echo "make build-commit      Build last version of motion and prepare to commit to svn"
	@echo "make build-commit-git  Build last version of motion and prepare to commit to git"
	@echo "make clean             Clean objects"
	@echo "make distclean         Clean everything"
	@echo "make install           Install binary , examples , docs and config files"
	@echo "make uninstall         Uninstall all installed files"
	@echo "--------------------------------------------------------------------------------"
	@echo


################################################################################
# INSTALL installs all relevant files.                                         #
################################################################################
install:
	@echo "Installing files..."
	@echo "--------------------------------------------------------------------------------"
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(mandir)/man1
	mkdir -p $(DESTDIR)$(sysconfdir)/motion
	mkdir -p $(DESTDIR)$(docdir)
	mkdir -p $(DESTDIR)$(examplesdir)
	@sed -e 's|$${prefix}|$(prefix)|' motion-dist.conf > motion-dist.conf.tmp && mv -f motion-dist.conf.tmp motion-dist.conf
	@sed -e 's|$${prefix}|$(prefix)|' camera1-dist.conf > camera1-dist.conf.tmp && mv -f camera1-dist.conf.tmp camera1-dist.conf
	@sed -e 's|$${prefix}|$(prefix)|' camera2-dist.conf > camera2-dist.conf.tmp && mv -f camera2-dist.conf.tmp camera2-dist.conf
	@sed -e 's|$${prefix}|$(prefix)|' camera3-dist.conf > camera3-dist.conf.tmp && mv -f camera3-dist.conf.tmp camera3-dist.conf
	@sed -e 's|$${prefix}|$(prefix)|' camera4-dist.conf > camera4-dist.conf.tmp && mv -f camera4-dist.conf.tmp camera4-dist.conf
	$(INSTALL_DATA) ./motion.1 $(DESTDIR)$(mandir)/man1
	$(INSTALL_DATA) $(DOC_FILES) $(DESTDIR)$(docdir)
	$(INSTALL_DATA) $(EXAMPLES) $(DESTDIR)$(examplesdir)
	$(INSTALL) $(EXAMPLES_BIN) $(DESTDIR)$(examplesdir)
	$(INSTALL_DATA) motion-dist.conf $(DESTDIR)$(sysconfdir)/motion
	$(INSTALL_DATA) camera1-dist.conf $(DESTDIR)$(sysconfdir)/motion
	$(INSTALL_DATA) camera2-dist.conf $(DESTDIR)$(sysconfdir)/motion
	$(INSTALL_DATA) camera3-dist.conf $(DESTDIR)$(sysconfdir)/motion
	$(INSTALL_DATA) camera4-dist.conf $(DESTDIR)$(sysconfdir)/motion
	@for prog in $(PROGS); \
	do \
	($(INSTALL) $$prog $(DESTDIR)$(bindir) ); \
	done
ifeq ("yes","yes")
	@echo Installing translation files
	@for lng in $(LANGCDS); \
	do \
      mkdir -p $(DESTDIR)$(localedir)/$$lng"/LC_MESSAGES/";    \
	  $(INSTALL_DATA) ./po/$$lng.mo                \
	  $(DESTDIR)$(localedir)/$$lng"/LC_MESSAGES/motion.mo"  ;  \
	done
else
	@echo Skipping translations
endif
	@echo "--------------------------------------------------------------------------------"
	@echo "Install complete! The default configuration file, motion-dist.conf, has been"
	@echo "installed to $(sysconfdir)/motion. You need to rename/copy it to motion.conf"
	@echo "for Motion to find it. More configuration examples as well as init scripts"
	@echo "can be found in $(examplesdir)."
	@echo

################################################################################
# UNINSTALL and REMOVE uninstall already installed files.                      #
################################################################################
uninstall remove: pre-build-info
	@echo "Uninstalling files..."
	@echo "--------------------------------------------------------------------------------"
	for prog in $(PROGS); \
	do \
		($ rm -f $(bindir)/$$prog ); \
	done
	rm -f $(mandir)/man1/motion.1
	rm -f $(sysconfdir)/motion/motion-dist.conf
	rm -f $(sysconfdir)/motion/camera1-dist.conf
	rm -f $(sysconfdir)/motion/camera2-dist.conf
	rm -f $(sysconfdir)/motion/camera3-dist.conf
	rm -f $(sysconfdir)/motion/camera4-dist.conf
	rm -rf $(docdir)
	rm -rf $(examplesdir)
ifeq ("yes","yes")
	@echo Removing translation files files
	@for lng in $(LANGCDS); \
	do \
      rm -f $(DESTDIR)$(localedir)/$$lng"/LC_MESSAGES/motion.mo"  ;  \
	done
endif
	@echo "--------------------------------------------------------------------------------"
	@echo "Uninstall complete!"
	@echo

################################################################################
# CLEAN is basic cleaning; removes object files and executables, but does not  #
# remove files generated from the configure step.                              #
################################################################################
clean: pre-build-info
	@echo "Removing compiled files and binaries..."
	@rm -f *~ *.o $(PROGS) combine $(DEPEND_FILE)
	@rm -f ./po/*.mo

################################################################################
# DIST restores the directory to distribution state.                           #
################################################################################
dist: distclean
	@chmod -R 644 *
	@chmod 755 configure
	@chmod 755 version.sh

################################################################################
# DISTCLEAN removes all files generated during the configure step in addition  #
# to basic cleaning.                                                           #
################################################################################
distclean: clean
	@echo "Removing files generated by configure..."
	@rm -f config.status config.log config.cache Makefile motion.service motion.init-Debian motion.init-FreeBSD.sh
	@rm -f camera1-dist.conf camera2-dist.conf camera3-dist.conf camera4-dist.conf motion-dist.conf motion-help.conf motion.spec
	@rm -rf autom4te.cache config.h
	@echo "You will need to re-run configure if you want to build Motion."
	@echo

.PHONY: install