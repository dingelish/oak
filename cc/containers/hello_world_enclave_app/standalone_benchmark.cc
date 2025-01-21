/*
 * Copyright 2025 The Project Oak Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <cstdint>

#include "absl/log/check.h"
#include "absl/log/log.h"
#include "absl/status/status_matchers.h"
#include "benchmark/benchmark.h"
#include "cc/attestation/verification/insecure_attestation_verifier.h"
#include "cc/client/client.h"
#include "cc/client/session_client.h"
#include "cc/containers/hello_world_enclave_app/app_service.h"
#include "cc/containers/sdk/standalone/oak_standalone.h"
#include "cc/oak_session/channel/oak_session_channel.h"
#include "cc/oak_session/client_session.h"
#include "cc/transport/grpc_streaming_transport.h"
#include "cc/transport/grpc_sync_session_client_transport.h"
#include "grpcpp/server.h"
#include "grpcpp/server_builder.h"
#include "oak_containers/examples/hello_world/proto/hello_world.grpc.pb.h"

using ::oak::attestation::v1::AttestationResults;
using ::oak::attestation::verification::InsecureAttestationVerifier;
using ::oak::client::OakClient;
using ::oak::containers::example::EnclaveApplication;
using ::oak::containers::hello_world_enclave_app::EnclaveApplicationImpl;
using ::oak::crypto::EncryptionKeyProvider;
using ::oak::crypto::KeyPair;
using ::oak::session::v1::EndorsedEvidence;
using ::oak::session::v1::PlaintextMessage;
using ::oak::session::v1::SessionResponse;
using ::oak::transport::GrpcStreamingTransport;

namespace oak::containers::sdk::standalone {

namespace {

std::string TestMessage(int size) {
  std::string message;
  message.reserve(size);
  for (int i = 0; i < size; i++) {
    message += i % 255;
  }
  return message;
}

constexpr absl::string_view kApplicationConfig = "{}";

class HelloWorldStandaloneBench : public benchmark::Fixture {
 public:
  void SetUp(benchmark::State& state) override {
    // Set up our new Keypair and get an EndorsedEvidence from Rust.
    absl::StatusOr<KeyPair> key_pair = KeyPair::Generate();
    QCHECK_OK(key_pair);
    absl::StatusOr<EndorsedEvidence> endorsed_evidence =
        GetEndorsedEvidence(*key_pair);
    QCHECK_OK(endorsed_evidence);

    // Verify that the endorsed evidence is valid.
    InsecureAttestationVerifier verifier;
    absl::StatusOr<AttestationResults> attestation_results = verifier.Verify(
        std::chrono::system_clock::now(), endorsed_evidence->evidence(),
        endorsed_evidence->endorsements());
    QCHECK_OK(attestation_results);

    service_ = std::make_unique<EnclaveApplicationImpl>(
        OakSessionContext(std::move(*endorsed_evidence),
                          std::make_unique<EncryptionKeyProvider>(*key_pair)),
        kApplicationConfig);

    grpc::ServerBuilder builder;
    builder.AddListeningPort("[::]:8080", grpc::InsecureServerCredentials());
    builder.RegisterService(service_.get());
    server_ = builder.BuildAndStart();

    auto channel = grpc::CreateChannel("localhost:8080",
                                       grpc::InsecureChannelCredentials());
    stub_ = EnclaveApplication::NewStub(channel);
  }

 protected:
  std::unique_ptr<EnclaveApplicationImpl> service_;
  std::unique_ptr<grpc::Server> server_;
  std::unique_ptr<EnclaveApplication::Stub> stub_;
};

BENCHMARK_DEFINE_F(HelloWorldStandaloneBench, HPKEInvocation)
(benchmark::State& state) {
  std::string test_message = TestMessage(state.range(0));
  grpc::ClientContext context;
  auto transport =
      std::make_unique<GrpcStreamingTransport>(stub_->LegacySession(&context));
  InsecureAttestationVerifier verifier;
  auto client = OakClient::Create(std::move(transport), verifier);
  QCHECK_OK(client);

  for (auto iter : state) {
    auto result = (*client)->Invoke(test_message);
    QCHECK_OK(result);
    QCHECK(*result ==
           absl::Substitute("Hello from the enclave, $1! Btw, the app has a "
                            "config with a length of $0 bytes.",
                            kApplicationConfig.size(), test_message));
  }
  state.SetBytesProcessed(int64_t(state.iterations()) *
                          int64_t(state.range(0)));
}

BENCHMARK_DEFINE_F(HelloWorldStandaloneBench, NoiseInvocation)
(benchmark::State& state) {
  std::string test_message = TestMessage(state.range(0));
  client::OakSessionClient session_client;
  grpc::ClientContext context;
  auto channel = session_client.NewChannel(
      std::make_unique<transport::GrpcSyncSessionClientTransport>(
          stub_->OakSession(&context)));
  QCHECK_OK(channel);

  for (auto i : state) {
    auto result = (*channel)->Send(test_message);
    QCHECK_OK(result);
    auto response = (*channel)->Receive();
    QCHECK_OK(response);
    QCHECK(*response ==
           absl::Substitute("Hello from the enclave, $1! Btw, the app has a "
                            "config with a length of $0 bytes.",
                            kApplicationConfig.size(), test_message));
  }
  state.SetBytesProcessed(int64_t(state.iterations()) *
                          int64_t(state.range(0)));
}

BENCHMARK_DEFINE_F(HelloWorldStandaloneBench, PlaintextInvocation)
(benchmark::State& state) {
  std::string test_message = TestMessage(state.range(0));
  grpc::ClientContext context;
  auto reader_writer = stub_->PlaintextSession(&context);

  for (auto _ : state) {
    PlaintextMessage request;
    request.set_plaintext(test_message);
    bool result = reader_writer->Write(request);
    QCHECK(result);
    PlaintextMessage response;
    bool response_result = reader_writer->Read(&response);
    QCHECK(response_result);
    QCHECK(response.plaintext() ==
           absl::Substitute("Hello from the enclave, $1! Btw, the app has a "
                            "config with a length of $0 bytes.",
                            kApplicationConfig.size(), test_message));
  }
  state.SetBytesProcessed(int64_t(state.iterations()) *
                          int64_t(state.range(0)));
}

BENCHMARK_REGISTER_F(HelloWorldStandaloneBench, HPKEInvocation)
    ->Range(2, 1 << 21);
BENCHMARK_REGISTER_F(HelloWorldStandaloneBench, NoiseInvocation)
    ->Range(2, 1 << 21);
BENCHMARK_REGISTER_F(HelloWorldStandaloneBench, PlaintextInvocation)
    ->Range(2, 1 << 21);

}  // namespace

}  // namespace oak::containers::sdk::standalone

// Run the benchmark
BENCHMARK_MAIN();
