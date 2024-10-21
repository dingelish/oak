#
# Copyright 2024 The Project Oak Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
"""Rust crates required by this workspace."""

load("@rules_rust//crate_universe:defs.bzl", "crate")

def _common_crates(std):
    """Crates present in all crate indexes."""
    return {
        "acpi": crate.spec(version = "5.0.0"),
        "aead": crate.spec(version = "0.5.2"),
        "aes-gcm": crate.spec(
            default_features = False,
            features = [
                "aes",
                "alloc",
            ],
            version = "0.10.3",
        ),
        "aml": crate.spec(version = "0.16.4"),
        "anyhow": crate.spec(
            default_features = False,
            version = "1.0.79",
        ),
        "arrayvec": crate.spec(
            default_features = False,
            version = "0.7.4",
        ),
        "atomic_refcell": crate.spec(version = "0.1.13"),
        "base64": crate.spec(
            version = "0.21.7",
            default_features = False,
            features = ["alloc"],
        ),
        "bitflags": crate.spec(version = "2.4.1"),
        "bitvec": crate.spec(
            default_features = False,
            version = "1.0.1",
        ),
        "bytes": crate.spec(
            default_features = std,
            version = "1.6.1",
        ),
        "ciborium": crate.spec(
            default_features = False,
            version = "0.2.1",
        ),
        "coset": crate.spec(
            default_features = False,
            version = "0.3.7",
        ),
        "curve25519-dalek": crate.spec(
            default_features = False,
            version = "*",
        ),
        "derive_builder": crate.spec(
            default_features = False,
            features = ["alloc"],
            version = "0.20.0",
        ),
        "ecdsa": crate.spec(
            default_features = False,
            features = [
                "der",
                "pem",
                "pkcs8",
                "signing",
            ],
            version = "0.16.9",
        ),
        "elf": crate.spec(
            default_features = False,
            version = "0.7.4",
        ),
        "getrandom": crate.spec(
            default_features = std,
            # rdrand is required to support x64_64-unknown-none.
            features = [] if std else ["rdrand"],
            version = "0.2.12",
        ),
        "goblin": crate.spec(
            default_features = False,
            features = [
                "elf32",
                "elf64",
                "endian_fd",
            ],
            version = "0.8.2",
        ),
        "hashbrown": crate.spec(
            default_features = False,
            version = "0.14.3",
            features = ["ahash"],
        ),
        "hex": crate.spec(
            default_features = False,
            features = ["alloc"],
            version = "0.4.3",
        ),
        "hkdf": crate.spec(
            default_features = False,
            version = "0.12.4",
        ),
        "hpke": crate.spec(
            default_features = False,
            features = [
                "alloc",
                "x25519",
            ],
            version = "0.11.0",
        ),
        "itertools": crate.spec(
            default_features = False,
            version = "0.13.0",
        ),
        "lazy_static": crate.spec(
            features = [] if std else ["spin_no_std"],
            version = "1.4.0",
        ),
        "libm": crate.spec(version = "0.2.8"),
        "linked_list_allocator": crate.spec(
            features = ["alloc_ref"],
            version = "0.10.5",
        ),
        "lock_api": crate.spec(
            default_features = std,
            features = ["arc_lock"] if std else [],
            version = "0.4.11",
        ),
        "log": crate.spec(
            version = "0.4.20",
        ),
        "maplit": crate.spec(
            version = "1.0.2",
        ),
        "mockall": crate.spec(
            version = "0.13.0",
        ),
        "p256": crate.spec(
            default_features = False,
            features = [
                "alloc",
                "ecdsa",
                "pem",
            ],
            version = "0.13.2",
        ),
        "p384": crate.spec(
            default_features = False,
            features = [
                "ecdsa",
                "pem",
            ],
            version = "0.13.0",
        ),
        "rsa": crate.spec(
            default_features = False,
            version = "0.9.6",
        ),
        "pkcs8": crate.spec(
            default_features = False,
            features = ["alloc"],
            version = "0.10.2",
        ),
        "primeorder": crate.spec(
            default_features = False,
            version = "0.13.6",
        ),
        "prost": crate.spec(
            default_features = False,
            # No derive feature - it requires std and will make other crates
            # in this index, like bytes, require std.
            features = ["prost-derive"] if std else [],
            version = "0.12.4",
        ),
        "rand_chacha": crate.spec(
            default_features = std,
            version = "0.3.1",
        ),
        "rand_core": crate.spec(
            default_features = False,
            features = ["getrandom"],
            version = "0.6.4",
        ),
        "regex-lite": crate.spec(
            default_features = False,
            features = [],
            version = "0.1.6",
        ),
        "rlsf": crate.spec(version = "0.2.1"),
        "self_cell": crate.spec(version = "1.0.4"),
        "serde": crate.spec(
            default_features = False,
            features = ["derive"],
            version = "1.0.195",
        ),
        "serde_json": crate.spec(
            default_features = False,
            features = ["alloc"],
            version = "1.0.111",
        ),
        "sha2": crate.spec(
            default_features = False,
            version = "0.10.8",
        ),
        "snafu": crate.spec(
            default_features = False,
            version = "0.8.0",
        ),
        "spinning_top": crate.spec(version = "0.3.0"),
        "static_assertions": crate.spec(version = "1.1.0"),
        "strum": crate.spec(
            default_features = False,
            features = ["derive"],
            version = "0.26.3",
        ),
        "time": crate.spec(
            default_features = False,
            features = [
                "serde",
                "parsing",
            ],
            version = "0.3.36",
        ),
        "uart_16550": crate.spec(version = "0.3.0"),
        "wasmi": crate.spec(
            default_features = std,
            # same version as cargo, newer versions had compatibility issues
            version = "0.31.2",
        ),
        "x509-cert": crate.spec(
            default_features = False,
            features = ["pem"],
            version = "0.2.5",
        ),
        "x86_64": crate.spec(version = "=0.14"),  #  0.15 does not support LowerHex formatting.
        "zerocopy": crate.spec(
            default_features = False,
            features = ["derive"],
            version = "0.7.32",
        ),
        "zeroize": crate.spec(
            features = ["derive"],
            version = "1.7.0",
        ),
    }

# Annotations for the no_std crates index.
OAK_NO_STD_ANNOTATIONS = {
    "linked_list_allocator": [crate.annotation(
        # overflow-checks are disabled for release builds, and for some reason Restricted Kernel
        # hits them in dev builds.  Let's disable them everywhere.
        rustc_flags = ["-C", "overflow-checks=false"],
    )],
}

# Crates for the no_std crates index. Crates that are used in all crate indexes
# should instead be added to _common_crates.
OAK_NO_STD_CRATES = _common_crates(std = False) | {
    "virtio-drivers": crate.spec(version = "0.7.3"),
}

# Annotations for the no_std no-AVX crates index.
OAK_NO_STD_NO_AVX_ANNOTATIONS = {
    "sha2": [crate.annotation(
        # Crate feature needed for SHA2 to build if AVX is not enabled.
        crate_features = ["force-soft"],
    )],
}

# Crates for the no_std no-AVX (no-alloc) crates index. Crates that are used in
# all crate indexes should instead be added to _common_crates.
OAK_NO_STD_NO_AVX_CRATES = _common_crates(std = False)

# Annotations for the std crates index.
OAK_STD_ANNOTATIONS = {
    # Provide the jemalloc library built by the library included above.
    # The tikv-jemalloc-sys crate using by tikv-jemallocator uses a build script to run
    # configure/make for libjemalloc. This doesn't work out of the box. The suggestion is to
    # instead build libjemalloc with bazel, and then provide the generated lbirary to the
    # build script.
    #
    # See: https://github.com/bazelbuild/rules_rust/issues/1670
    # The example there didn't work exactly as written in this context, but I was able
    # to modify it to get it working.
    "tikv-jemalloc-sys": [crate.annotation(
        build_script_data = [
            "@jemalloc//:gen_dir",
        ],
        build_script_env = {
            "JEMALLOC_OVERRIDE": "$(execpath @jemalloc//:gen_dir)/lib/libjemalloc.a",
        },
        data = ["@jemalloc//:gen_dir"],
        version = "0.5.4",
        deps = ["@jemalloc"],
    )],
    # Enable `tokio_unstable` so that we can access the Tokio runtime metrics.
    "tokio": [crate.annotation(
        rustc_flags = ["--cfg=tokio_unstable"],
    )],
}

# Crates for the std crates index. Crates that are used in all
# crate indexes should instead be added to _common_crates.
OAK_STD_CRATES = _common_crates(std = True) | {
    "async-recursion": crate.spec(version = "1.1.1"),
    "async-stream": crate.spec(version = "0.3.5"),
    "assertables": crate.spec(version = "7.0.1"),
    "assert-json-diff": crate.spec(version = "2.0.2"),
    "async-trait": crate.spec(
        default_features = False,
        version = "0.1.77",
    ),
    "bmrng": crate.spec(version = "0.5.2"),
    "chrono": crate.spec(
        default_features = False,
        features = [
            "std",
            "clock",
        ],
        version = "0.4.31",
    ),
    "clap": crate.spec(
        features = [
            "derive",
            "env",
        ],
        version = "4.4.17",
    ),
    "colored": crate.spec(version = "2.1.0"),
    "command-fds": crate.spec(
        features = ["tokio"],
        version = "0.3.0",
    ),
    "command-group": crate.spec(version = "5.0.1"),
    "criterion": crate.spec(version = "0.5.1"),
    "criterion-macro": crate.spec(version = "0.4.0"),
    "env_logger": crate.spec(version = "0.11.2"),
    "futures": crate.spec(version = "0.3.31"),
    "futures-util": crate.spec(version = "0.3.31"),
    # Use same version as cargo, newer versions has compatibility issues.
    "http": crate.spec(version = "0.2.11"),
    "http-body-util": crate.spec(version = "0.1.2"),
    "hyper": crate.spec(
        features = [
            "full",
        ],
        version = "1.4.1",
    ),
    "hyper-util": crate.spec(version = "0.1.7", features = ["full"]),
    "ignore": crate.spec(version = "0.4.22"),
    "libloading": crate.spec(version = "0.8.5"),
    "nix": crate.spec(
        features = [
            "fs",
            "mman",
            "mount",
            "process",
            "signal",
            "term",
            "ucontext",
            "user",
        ],
        version = "0.27.1",
    ),
    "oci-spec": crate.spec(version = "0.6.7"),
    "once_cell": crate.spec(version = "1.19.0"),
    # TODO b/350061567 - Remove opentelemetry version pins
    "opentelemetry": crate.spec(
        features = [
            "trace",
        ],
        version = "0.22.0",
    ),
    "opentelemetry-proto": crate.spec(
        features = [
            "gen-tonic",
            "logs",
            "metrics",
        ],
        version = "0.5.0",
    ),
    "opentelemetry-otlp": crate.spec(
        features = [
            "grpc-tonic",
            "logs",
            "metrics",
            "trace",
        ],
        version = "0.15.0",
    ),
    "opentelemetry_sdk": crate.spec(
        features = [
            "logs",
            "metrics",
            "rt-tokio",
            "trace",
        ],
        version = "0.22.1",
    ),
    "os_pipe": crate.spec(version = "1.1.5"),
    "ouroboros": crate.spec(version = "0.18.4"),
    "parking_lot": crate.spec(version = "0.12.1"),
    "port_check": crate.spec(version = "0.1.5"),
    "portpicker": crate.spec(version = "0.1.1"),
    "pprof": crate.spec(
        features = [
            "frame-pointer",
            "prost-codec",
        ],
        version = "0.13.0",
    ),
    "pretty_assertions": crate.spec(version = "1.4.0"),
    "procfs": crate.spec(version = "0.16.0"),
    "prost-build": crate.spec(version = "0.12.3"),
    "prost-derive": crate.spec(version = "0.12.4"),
    "prost-types": crate.spec(version = "0.12.3"),
    "quote": crate.spec(version = "1.0.35"),
    "rand": crate.spec(version = "0.8.5"),
    "regex": crate.spec(
        default_features = False,
        version = "1.10.2",
    ),
    "regex-lite": crate.spec(
        default_features = False,
        features = [
            "std",
            "string",
        ],
        version = "0.1.6",
    ),
    "rtnetlink": crate.spec(version = "0.14.1"),
    "serde_yaml": crate.spec(version = "0.9.30"),
    "signal-hook": crate.spec(version = "0.3.17"),
    "signal-hook-tokio": crate.spec(
        features = ["futures-v0_3"],
        version = "0.3.1",
    ),
    "simple_logger": crate.spec(version = "4.3.3"),
    "stderrlog": crate.spec(version = "0.6.0"),
    "strum_macros": crate.spec(version = "0.25"),
    "syn": crate.spec(
        features = ["full"],
        version = "2.0.48",
    ),
    "syslog": crate.spec(version = "6.1.0"),
    "tar": crate.spec(version = "0.4.40"),
    "temp-env": crate.spec(version = "0.3.6"),
    "tempfile": crate.spec(version = "3.10.1"),
    "tikv-jemallocator": crate.spec(version = "0.5.4"),
    "tokio": crate.spec(
        features = [
            "fs",
            "io-util",
            "macros",
            "net",
            "parking_lot",
            "process",
            "rt",
            "rt-multi-thread",
            "signal",
            "sync",
            "time",
        ],
        version = "1.36.0",
    ),
    "tokio-stream": crate.spec(
        features = ["net"],
        version = "0.1.14",
    ),
    "tokio-util": crate.spec(version = "0.7.10"),
    "tokio-vsock": crate.spec(
        # Pull the crate from github as the latest version
        # in the repository depends on tonic 10.0.2 that causes
        # compilation errors as the compiler thinks that `Connected`
        # is not implemented for `VsockStream`.
        # Other options is to patch the generated bazel file in the
        # create annotation or to write bazel for the local repository
        # in the third-party folder. Writing patches is fragile as
        # the generated build file might differ for repositories that
        # depends on Oak. In fact, the patched version in the
        # third-party folder changes the version of tonic to 11.0.0 in
        # the dependencies.
        git = "https://github.com/rust-vsock/tokio-vsock",
        rev = "2a52faeb4ede7d9712adbc096e547ab7ea766f4b",
        features = ["tonic-conn"],
    ),
    "toml": crate.spec(version = "0.5.11"),
    "tonic": crate.spec(
        features = ["gzip"],
        version = "0.11.0",
    ),
    "tonic-build": crate.spec(version = "0.11.0"),
    "tonic-web": crate.spec(version = "0.11.0"),
    "tower": crate.spec(
        features = ["load-shed"],
        version = "0.4.13",
    ),
    "tower-http": crate.spec(
        features = ["trace"],
        version = "0.4.4",
    ),
    "tracing": crate.spec(version = "0.1.40"),
    "ubyte": crate.spec(version = "0.10.4"),
    "walkdir": crate.spec(version = "2.5.0"),
    "wasmtime": crate.spec(
        default_features = False,
        # Try to figure out a minimal set of features we need (e.g. disable wasm profiling)
        features = [
            "async",
            "cranelift",
            "cache",
            "parallel-compilation",
            "pooling-allocator",
            "runtime",
        ],
        # same version as cargo
        version = "18.0.4",
    ),
    "which": crate.spec(version = "5.0.0"),
    "xz2": crate.spec(version = "0.1.7"),
}
