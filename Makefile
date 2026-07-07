# Makefile for ucpp
#
# (c) Thomas Pornin 1999 - 2002
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 4. The name of the authors may not be used to endorse or promote
#    products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR 
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

.POSIX:

.PHONY: all clean install

# ----- user configurable part -----

# Edit the variables to suit your system.
#
#   use -DAUDIT to enable some internal sanity checks
#   use -DMEM_CHECK to check the return value of malloc()
#      (superseded by AUDIT)
#   use -DMEM_DEBUG to enable memory leak research (warning: this
#      slows down ucpp a bit, and greatly increases memory consumption)
#   use -DINLINE=foobar to enable use of the 'foobar'
#      non standard qualifier, as an equivalent to the C99 'inline'
#      qualifier. See tune.h for details.
#
# Two FLAGS lines are given for each system type; chose the first one for
# debug, the second one for a fast binary.

# for a generic compiler called cc
#CC = cc
#FLAGS = -DAUDIT
#FLAGS = -O -DMEM_CHECK

# for Minix-86
#CC = cc
#LDFLAGS = -i
#FLAGS = -m -DAUDIT
#FLAGS = -O -m -DMEM_CHECK

# for gcc
CC = gcc
FLAGS = -O3 -W -Wall -ansi
#FLAGS = -g -W -Wall -ansi -DAUDIT -DMEM_DEBUG
#FLAGS = -O3 -mcpu=pentiumpro -fomit-frame-pointer -W -Wall -ansi -DMEM_CHECK
#FLAGS = -O -pg -W -Wall -ansi -DMEM_CHECK
#LDFLAGS = -pg

# for the Compaq C compiler on Alpha/Linux
#CC = ccc
#FLAGS = -w0 -g -DAUDIT
#FLAGS = -w0 -fast -DMEM_CHECK

# for the Sun Workshop C Compiler
#CC = cc
#FLAGS = -g -Xa -DAUDIT
#FLAGS = -Xa -fast -DMEM_CHECK

# flags for the link step
LIBS =
#LIBS = libefence.a
#LIBS = -lgc_dbg

STAND_ALONE = -DSTAND_ALONE

ifdef STAND_ALONE
	CSRC = mem.c nhash.c cpp.c lexer.c assert.c macro.c eval.c
	FINAL_STEP = $(CC) $(LDFLAGS) -DUCPP_CONFIG $(STAND_ALONE) -o ucpp $(CSRC) $(LIBS)
endif

# ----- nothing should be changed below this line -----

LIBSRC = mem.c nhash.c cpp.c lexer.c assert.c macro.c eval.c
LIBOBJ = $(LIBSRC:.c=.o)
PICOBJ = $(LIBSRC:.c=.pic.o)
CFLAGS = $(FLAGS)
CPPFLAGS =
AR = ar
ARFLAGS = cq
RANLIB = ranlib
INSTALL = install
PREFIX = /usr/local
DESTDIR =
bindir = $(PREFIX)/bin
libdir = $(PREFIX)/lib
includedir = $(PREFIX)/include/ucpp
mandir = $(PREFIX)/share/man
LIB_STATIC = libucpp.a
LIB_SHARED = libucpp.so
PUBLIC_HEADERS = cpp.h mem.h nhash.h arith.h tune.h config.h
SWIG_INTERFACE = ucpp.i

all: ucpp $(LIB_STATIC) $(LIB_SHARED)

clean:
	@rm -rf *.o ucpp core *.a *.so pyucpp ucpp_wrap.*

install: all
	$(INSTALL) -d $(DESTDIR)$(bindir) $(DESTDIR)$(libdir) \
		$(DESTDIR)$(includedir) $(DESTDIR)$(mandir)/man1
	$(INSTALL) -m 755 ucpp $(DESTDIR)$(bindir)/ucpp
	$(INSTALL) -m 644 $(LIB_STATIC) $(DESTDIR)$(libdir)/$(LIB_STATIC)
	$(INSTALL) -m 755 $(LIB_SHARED) $(DESTDIR)$(libdir)/$(LIB_SHARED)
	$(INSTALL) -m 644 $(PUBLIC_HEADERS) $(SWIG_INTERFACE) $(DESTDIR)$(includedir)
	$(INSTALL) -m 644 ucpp.1 $(DESTDIR)$(mandir)/man1/ucpp.1

ucpp: $(LIBOBJ)
	@$(FINAL_STEP)

$(LIB_STATIC): $(PICOBJ)
	@$(AR) $(ARFLAGS) $@ $(PICOBJ)
	@$(RANLIB) $@

$(LIB_SHARED): $(PICOBJ)
	@$(CC) -shared $(PICOBJ) $(LDFLAGS) $(LIBS) -o $@

assert.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c assert.c
cpp.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c cpp.c
eval.o: tune.h ucppi.h cpp.h nhash.h mem.h arith.c arith.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c eval.c
lexer.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c lexer.c
macro.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c macro.c
mem.o: mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c mem.c
nhash.o: nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c nhash.c

assert.pic.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c assert.c -o $@
cpp.pic.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c cpp.c -o $@
eval.pic.o: tune.h ucppi.h cpp.h nhash.h mem.h arith.c arith.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c eval.c -o $@
lexer.pic.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c lexer.c -o $@
macro.pic.o: tune.h ucppi.h cpp.h nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c macro.c -o $@
mem.pic.o: mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c mem.c -o $@
nhash.pic.o: nhash.h mem.h
	@$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -DUCPP_NO_SHARED_LIB -c nhash.c -o $@
