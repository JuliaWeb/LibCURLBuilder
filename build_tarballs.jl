# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibCURL"
version = v"7.64.0"

# Collection of sources required to build LibCURL
sources = [
    "https://curl.haxx.se/download/curl-7.64.0.tar.gz" =>
    "cb90d2eb74d4e358c1ed1489f8e3af96b50ea4374ad71f143fa4595e998d81b5",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/curl-7.64.0

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
make -j${nproc} LDFLAGS="$LDFLAGS"
make install-exec
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libcurl", :libcurl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    string(
        "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/",
        "v0.17.0/build_MbedTLS.v2.16.0.jl",
    ),
    string(
        "https://github.com/bicycle1885/ZlibBuilder/releases/download/",
        "v1.0.3/build_Zlib.v1.2.11.jl",
    ),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
