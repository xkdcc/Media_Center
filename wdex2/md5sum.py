#!/usr/bin/python

import os,sys
import hashlib


def main(argv):
    if (len(sys.argv) != 3 ):
        print 'md5sum.py <md5|sha1> <inputfile>'
        sys.exit()
    algorithm = sys.argv[1]
    if (algorithm != "md5" and algorithm != "sha1"):
        print 'md5sum.py <md5|sha1> <inputfile>'
        sys.exit()

    inputfile = sys.argv[2]
    if (os.path.exists(inputfile) == False):
        print "[ERR] " + inputfile + " not exist."
        sys.exit()

    BLOCKSIZE = 65536
    if (algorithm == "md5"):
        hasher = hashlib.md5()
    elif (algorithm == "sha1"):
        hasher = hashlib.sha1()
    
    with open(inputfile, 'rb') as afile:
        buf = afile.read(BLOCKSIZE)
        while len(buf) > 0:
            hasher.update(buf)
            buf = afile.read(BLOCKSIZE)

    if (algorithm == "md5"):
        print("MD5: " + hasher.hexdigest())
    elif (algorithm == "sha1"):
        print("SHA1: " + hasher.hexdigest())

if __name__ == "__main__":
       main(sys.argv)
