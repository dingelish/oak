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

load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("//bazel:defs.bzl", "oci_runtime_bundle")

package(licenses = ["notice"])

cc_library(
    name = "app_service",
    srcs = ["app_service.cc"],
    hdrs = ["app_service.h"],
    deps = [
        ":orchestrator_client",
        "//cc/crypto:common",
        "//cc/crypto:server_encryptor",
        "//oak_containers_hello_world_trusted_app/proto:interface_cc_grpc",
        "//oak_containers_hello_world_trusted_app/proto:interface_cc_proto",
        "//oak_crypto/proto/v1:crypto_cc_proto",
        "@com_github_grpc_grpc//:grpc++",
        "@com_google_absl//absl/strings",
    ],
)

cc_library(
    name = "orchestrator_client",
    srcs = ["orchestrator_client.cc"],
    hdrs = ["orchestrator_client.h"],
    deps = [
        "//cc/crypto:encryption_key",
        "//cc/crypto/hpke:recipient_context",
        "//oak_containers/proto:interfaces_cc_grpc",
        "//oak_containers/proto:interfaces_cc_proto",
        "//oak_crypto/proto/v1:crypto_cc_proto",
        "//proto/containers:orchestrator_crypto_cc_grpc",
        "//proto/containers:orchestrator_crypto_cc_proto",
        "@com_github_grpc_grpc//:grpc++",
        "@com_google_absl//absl/status",
        "@com_google_absl//absl/status:statusor",
        "@com_google_absl//absl/strings",
        "@com_google_protobuf//:protobuf",
    ],
)

cc_binary(
    name = "main",
    srcs = ["main.cc"],
    deps = [
        ":app_service",
        ":orchestrator_client",
        "@com_github_grpc_grpc//:grpc++",
        "@com_google_absl//absl/log:check",
        "@com_google_absl//absl/log:initialize",
        "@com_google_absl//absl/status",
        "@com_google_absl//absl/status:statusor",
    ],
)

pkg_tar(
    name = "tar",
    srcs = [":main"],
    package_dir = "/usr/local/bin",
)

oci_image(
    name = "image",
    base = "@distroless_cc_debian12",
    entrypoint = ["/usr/local/bin/main"],
    tars = [":tar"],
)

oci_runtime_bundle(
    name = "bundle",
    image = ":image",
)