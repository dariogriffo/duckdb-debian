duckdb_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$duckdb_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <duckdb_version> <build_version> [architecture]"
    echo "Example: $0 1.5.4 1 arm64"
    echo "Example: $0 1.5.4 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Function to map Debian architecture to duckdb CLI release asset name.
# The glibc builds are used (not musl) so runtime extension installs
# (INSTALL httpfs; etc.) match the official linux_amd64/linux_arm64
# extension repository platforms.
get_duckdb_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "duckdb_cli-linux-amd64"
            ;;
        "arm64")
            echo "duckdb_cli-linux-arm64"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local duckdb_release

    duckdb_release=$(get_duckdb_release "$build_arch")
    if [ -z "$duckdb_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    echo "Building for architecture: $build_arch using $duckdb_release"

    # Clean up any previous builds for this architecture
    rm -f "$duckdb_release" "${duckdb_release}.gz" || true

    # Download and decompress the duckdb CLI binary for this architecture
    if ! wget -q "https://github.com/duckdb/duckdb/releases/download/v${duckdb_VERSION}/${duckdb_release}.gz"; then
        echo "❌ Failed to download duckdb CLI for $build_arch"
        return 1
    fi

    if ! gunzip "${duckdb_release}.gz"; then
        echo "❌ Failed to decompress duckdb CLI for $build_arch"
        return 1
    fi

    # Build packages for all Ubuntu distributions
    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$duckdb_VERSION-${BUILD_VERSION}~${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "duckdb-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg duckdb_VERSION="$duckdb_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg DUCKDB_RELEASE="$duckdb_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "duckdb-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/duckdb_$FULL_VERSION.deb" - > "./duckdb_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./duckdb_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted binary
    rm -f "$duckdb_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building duckdb $duckdb_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la duckdb_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
