all: clean prep build

build:
	./mkbundle-linux.sh
	./mkbundle-windows.sh
	./mkbundle-mac.sh

prep:
	./check-prerequisites.sh
	torsocks ./fetch-inputs.sh ../../gitian-builder/inputs/

clean:
	rm -f ../../gitian-builder/inputs/*gbuilt*.zip
	rm -f ../../gitian-builder/inputs/*.yml
	rm -f ../../gitian-builder/inputs/bundle.inputs
	rm -f ../../gitian-builder/inputs/versions

distclean:
	rm -rf ../../gitian-builder/inputs/*
