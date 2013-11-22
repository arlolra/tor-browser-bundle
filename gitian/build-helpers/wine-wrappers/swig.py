#!/usr/bin/env python

# A wrapper for swig that converts Windows paths to Unix paths, so that swig can
# be called by Python distutils.

import os
import subprocess
import sys

import common

args = ["/usr/bin/swig"]
sys.argv.pop(0)
while sys.argv:
    a = sys.argv.pop(0)
    if not a.startswith("-"):
        args.append(common.winepath(a))
        continue
    if a in ("-I",):
        args.append(a)
        args.append(common.winepath(sys.argv.pop(0)))
        continue
    o = common.search_startswith(a, ("-I",))
    if o is not None:
        path = a[len(o):]
        args.append("%s%s" % (o, common.winepath(path)))
        continue
    args.append(a)
p = common.popen_faketime(args, stderr=subprocess.PIPE)
stderr = p.stderr.read()
sys.stderr.write(stderr)
if " Error: " in stderr:
    sys.exit(1)
