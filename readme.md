# badsum
A md5/sha1 hash calculator

### Building (for linux)
1. fasm must be present in path
2. Since fasm linux package does not include some required files, be sure to add the INCLUDE folder from windows package
3. Set fasm env var to the fasm folder
4. make

### Binaries
Windows package is available on the [release](https://github.com/mp81ss/yacut/releases) page

### Notes
md5 is 3x faster then linux shipped md5sum, while sha1 is 2.7x faster then sha1sum
