# badsum
A md5/sha1 hash calculator

### Building (for linux)
1. fasm must be present in path
2. Since fasm linux package does not include some required files, be sure to add the INCLUDE folder from windows package
3. Set fasm env var to the fasm folder
4. make

### Binaries
Windows package is available on the [release](https://github.com/mp81ss/badsum/releases) page

### Notes
Performances vary a lot across distro and file locations (Disk, filesystem, etc.)
Generally, badsum is faster than linux shipped md5sum/sha1sum
Read benchmark file for details
