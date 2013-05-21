all: clean prep build

build:
	./mkbundle-linux.sh
	./mkbundle-windows.sh
	#./mkbundle-mac.sh

prep:
	./check-prerequisites.sh
	torsocks ./fetch-inputs.sh ../../gitian-builder/inputs/

clean:
	rm ../../gitian-builder/inputs/*gbuilt*.zip

distclean:
	rm ../../gitian-builder/inputs/*
