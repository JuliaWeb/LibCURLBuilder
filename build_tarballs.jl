# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibCURL"
version = v"7.64.1"

# Collection of sources required to build LibCURL
sources = [
    "https://curl.haxx.se/download/curl-7.64.1.tar.gz" =>
    "432d3f466644b9416bc5b649d344116a753aeaa520c8beaf024a90cba9d3d35d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/curl-7.64.1

# Configure and build
./configure \
    --prefix=$prefix \
    --host=$target \
    --with-mbedtls \
    --without-ssl \
    --disable-manual

if [[ $target == *-w64-mingw32 ]]; then
    LDFLAGS="$LDFLAGS -L$prefix/bin"
elif [[ $target == x86_64-apple-darwin14 ]]; then
    LDFLAGS="$LDFLAGS -L$prefix/lib -Wl,-rpath,$prefix/lib"
else
    LDFLAGS="$LDFLAGS -L$prefix/lib -Wl,-rpath-link,$prefix/lib"
fi
make -j${nproc} LDFLAGS="$LDFLAGS" CPPFLAGS="$CPPFLAGS -I$prefix/include"
make install-exec
"""

# Build for ALL THE PLATFORMS!
platforms = supported_platforms()

# The products that we will ensure are always built
# Note: Avoid including the `curl` executable as it is unneeded and requires additional
# configuration to work.
products(prefix) = [
    LibraryProduct(prefix, "libcurl", :libcurl),
    # ExecutableProduct(prefix, "curl", :curl)
]

# Dependencies that must be installed before this package can be built
gh = "https://github.com"
dependencies = [
    "$gh/JuliaWeb/MbedTLSBuilder/releases/download/v0.20.0/build_MbedTLS.v2.6.1.jl",
    "$gh/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
