# ARCHIVED - Moved to gitlab


# badsum
A md5/sha1 hash calculator

### Building (for linux)
1. Extract fasm linux package (if not present)
1. Since fasm linux package does not include some required files, add the INCLUDE folder from windows package
2. Set fasm env var to the fasm folder
3. make

### Binaries
Windows package is available on the [release](https://github.com/mp81ss/badsum/releases) page

### Notes
Performances vary a lot across distro and file locations (Disk, filesystem, etc.)\
Generally, badsum is faster than linux shipped md5sum/sha1sum\
Read benchmark file for details
