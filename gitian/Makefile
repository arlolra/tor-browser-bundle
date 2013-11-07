all: clean prep build

alpha: clean prep-alpha build-alpha

build:
	./mkbundle-linux.sh
	./mkbundle-windows.sh
	./mkbundle-mac.sh
	./hash-bundles.sh

build-alpha:
	./mkbundle-linux.sh versions.alpha
	./mkbundle-windows.sh versions.alpha
	./mkbundle-mac.sh versions.alpha
	./hash-bundles.sh

prep:
	./check-prerequisites.sh
	torsocks ./fetch-inputs.sh ../../gitian-builder/inputs/ versions

prep-alpha:
	./check-prerequisites.sh
	torsocks ./fetch-inputs.sh ../../gitian-builder/inputs/ versions.alpha

clean:
	rm -f ../../gitian-builder/inputs/*gbuilt*
	rm -f ../../gitian-builder/inputs/*.yml
	rm -f ../../gitian-builder/inputs/bundle.inputs
	rm -f ../../gitian-builder/inputs/versions*
	rm -f ../../gitian-builder/inputs/*debug.zip

vmclean:
	rm -rf ../../gitian-builder/*.qcow2
	rm -rf ../../gitian-builder/base-*
	rm -rf ../../gitian-builder/target-{lucid,precise}*

distclean: vmclean
	rm -rf ../../gitian-builder/inputs/*
