SHELL=		/bin/sh

LIBS=           ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4}
FC=		ifort
LDFLAGS=        
FFLAGS=	        -FR -cpp 
SRCS=		merge2n4.f 
OBJS=		merge2n4.o 
CMD=		pcprtma_merge2n4

all:		$(CMD)

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) $(ESSL) -o $(@) $(OBJS) $(LIBS)
clean:
	rm -rf $(OBJS) $(CMD)
mvexec:
	-mv $(CMD) ../../exec/.

