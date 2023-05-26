SRCS= unix-x.tex unix-x.sty unix-x.ist

unix-x.dvi: $(SRCS)
	latex unix-x
	makeindex -s unix-x.ist unix-x.idx
	latex unix-x

unix-x.ps: unix-x.dvi
	dvips -K -D 600 -o unix-x.ps unix-x.dvi

unix-x.pdf: unix-x.ps
	ps2pdf unix-x.ps unix-x.pdf

pdf: unix-x.ps
	ps2pdf unix-x.ps unix-x.pdf

print: unix-x.pdf

xdvi:
	xdvi unix-x.dvi&

tar:
	tar cvflz unix-x.tar.gz  $(SRCS) Makefile

clean:
	rm -f *~ *.dvi *.ps *.pdf *.tar.gz *.lo? *.i[dln]* *.aux *.out *.toc *.ans
