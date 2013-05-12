build: prep
	./mkbundle-linux.sh
	./mkbundle-windows.sh

prep:
	./check-prerequisites.sh
	torsocks ./fetch-inputs.sh ../../gitian-builder/inputs/

clean:
	rm ../../gitian-builder/inputs/tor-win32-browser-gbuilt.zip
	rm ../../gitian-builder/inputs/tor-win32-gbuilt.zip
	rm ../../gitian-builder/inputs/tor-linux-browser-gbuilt.zip
	rm ../../gitian-builder/inputs/tor-linux-gbuilt.zip

distclean:
	rm ../../gitian-builder/inputs/*
