TORSOCKS = torsocks

all: clean resume

nightly: clean resume-nightly

alpha: clean resume-alpha

resume: prep build incrementals hash

resume-nightly: prep-nightly build-nightly

resume-alpha: prep-alpha build-alpha incrementals-alpha hash-alpha

build:
	./mkbundle-linux.sh
	./mkbundle-windows.sh
	./mkbundle-mac.sh

build-nightly:
	./mkbundle-linux.sh versions.nightly
	./mkbundle-windows.sh versions.nightly
	./mkbundle-mac.sh versions.nightly
	./hash-bundles.sh versions.nightly

build-alpha:
	./mkbundle-linux.sh versions.alpha
	./mkbundle-windows.sh versions.alpha
	./mkbundle-mac.sh versions.alpha

incrementals:
	$(TORSOCKS) ../tools/update-responses/download_missing_versions release
	../tools/update-responses/gen_incrementals release

incrementals-alpha:
	$(TORSOCKS) ../tools/update-responses/download_missing_versions alpha
	../tools/update-responses/gen_incrementals alpha

signmars:
	./signmars.sh versions

signmars-alpha:
	./signmars.sh versions.alpha

signmars-nightly:
	./signmars.sh versions.nightly

dmg2mars:
	cd $(shell ../tools/update-responses/get_channel_version release) && ../../tools/dmg2mar
	$(TORSOCKS) ../tools/update-responses/download_missing_versions release
	CHECK_CODESIGNATURE_EXISTS=1 MAR_SKIP_EXISTING=1 ../tools/update-responses/gen_incrementals release

dmg2mars-alpha:
	cd $(shell ../tools/update-responses/get_channel_version alpha) && ../../tools/dmg2mar
	$(TORSOCKS) ../tools/update-responses/download_missing_versions alpha
	CHECK_CODESIGNATURE_EXISTS=1 MAR_SKIP_EXISTING=1 ../tools/update-responses/gen_incrementals alpha

update_responses:
	../tools/update-responses/update_responses release

update_responses-alpha:
	../tools/update-responses/update_responses alpha


hash:
	./hash-bundles.sh versions

hash-alpha:
	./hash-bundles.sh versions.alpha

hash-nightly:
	./hash-bundles.sh versions.nightly

sign:
	$(TORSOCKS) ./upload-signature.sh versions

sign-alpha:
	$(TORSOCKS) ./upload-signature.sh versions.alpha

sign-nightly:
	./upload-signature.sh versions.nightly

match:
	$(TORSOCKS) ./check-match.sh versions

match-nightly:
	./check-match.sh versions.nightly

match-alpha:
	$(TORSOCKS) ./check-match.sh versions.alpha

prep:
	./check-prerequisites.sh
	$(TORSOCKS) ./fetch-inputs.sh ../../gitian-builder/inputs/ versions

prep-nightly:
	./check-prerequisites.sh
	./fetch-inputs.sh ../../gitian-builder/inputs/ versions.nightly

prep-alpha:
	./check-prerequisites.sh
	$(TORSOCKS) ./fetch-inputs.sh ../../gitian-builder/inputs/ versions.alpha

clean: clean-utils clean-tor clean-browser clean-pt clean-sandbox clean-bundle
	rm -f ../../gitian-builder/inputs/*.yml
	rm -f ../../gitian-builder/inputs/bundle.inputs
	rm -f ../../gitian-builder/inputs/versions*

clean-utils: clean-bundle
	rm -f ../../gitian-builder/inputs/*utils.zip

clean-tor: clean-bundle
	rm -f ../../gitian-builder/inputs/tor-linux*
	rm -f ../../gitian-builder/inputs/tor-mac*
	rm -f ../../gitian-builder/inputs/tor-win*

clean-browser: clean-bundle
	rm -f ../../gitian-builder/inputs/tor-browser-linux*
	rm -f ../../gitian-builder/inputs/tor-browser-mac*
	rm -f ../../gitian-builder/inputs/tor-browser-win*
	rm -f ../../gitian-builder/inputs/mar-tools-*

clean-pt: clean-bundle
	rm -f ../../gitian-builder/inputs/pluggable-transports*

clean-sandbox: clean-bundle
	rm -f ../../gitian-builder/inputs/sandbox-linux*

clean-bundle:
	rm -f ../../gitian-builder/inputs/bundle-*

vmclean:
	rm -rf ../../gitian-builder/*.qcow2
	rm -rf ../../gitian-builder/base-*
	rm -rf ../../gitian-builder/target-{lucid,wheezy,precise}*

distclean: vmclean
	rm -rf ../../gitian-builder/inputs/*
