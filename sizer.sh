#!/bin/sh

# Framework options 

echo "$1\t\c" >> $3
echo "$2\t\c" >> $3

# Print total size
ls -la $1.framework/$1 | awk '{ printf("%s\t", $5) }' >> $3

# Print total size of dSYM
ls -la $1.framework.dSYM/Contents/Resources/DWARF/$1 | awk '{ printf("%s\t", $5) }' >> $3

# Pick arm64
lipo $1.framework/$1 -thin arm64 -output $1-arm64
ls -la $1-arm64 | awk '{ printf("%s\t", $5) }' >> $3

# Strip bitcode
xcrun bitcode_strip $1-arm64 -r -o $1-arm64-no-bitcode
ls -la $1-arm64-no-bitcode | awk '{ printf("%s\t", $5) }' >> $3

# Strip symbols
strip -Sx $1-arm64-no-bitcode -o $1-arm64-no-bitcode-stripped
ls -la $1-arm64-no-bitcode-stripped | awk '{ printf("%s\t", $5) }' >> $3

# Now size it
size $1-arm64-no-bitcode-stripped | tail -1 >> $3



