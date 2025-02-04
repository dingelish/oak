/*
 * Copyright 2024 The Project Oak Authors
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

#include <string>

#include "absl/status/status_matchers.h"
#include "cc/oak_session/client_session.h"
#include "cc/oak_session/server_session.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "proto/session/session.pb.h"

namespace oak::session {
namespace {

using ::absl_testing::IsOk;
using ::oak::session::v1::SessionRequest;
using ::oak::session::v1::SessionResponse;
using ::testing::Eq;
using ::testing::Ne;

SessionConfig* TestConfig() {
  return SessionConfigBuilder(AttestationType::kUnattested,
                              HandshakeType::kNoiseNN)
      .Build();
}

void DoHandshake(ClientSession& client_session, ServerSession& server_session) {
  absl::StatusOr<std::optional<SessionRequest>> init =
      client_session.GetOutgoingMessage();
  ASSERT_THAT(init, IsOk());
  ASSERT_THAT(*init, Ne(std::nullopt));
  ASSERT_THAT(server_session.PutIncomingMessage(**init), IsOk());

  absl::StatusOr<std::optional<SessionResponse>> init_resp =
      server_session.GetOutgoingMessage();
  ASSERT_THAT(init_resp, IsOk());
  ASSERT_THAT(*init_resp, Ne(std::nullopt));
  ASSERT_THAT(client_session.PutIncomingMessage(**init_resp), IsOk());

  EXPECT_THAT(client_session.IsOpen(), Eq(true));
  EXPECT_THAT(server_session.IsOpen(), Eq(true));
}

TEST(ClientServerSessionTest, HandshakeSucceeds) {
  auto client_session = ClientSession::Create(TestConfig());
  auto server_session = ServerSession::Create(TestConfig());

  DoHandshake(**client_session, **server_session);
}

TEST(ClientServerSessionTest, AcceptEmptyOutgoingMessageResult) {
  auto client_session = ClientSession::Create(TestConfig());
  auto server_session = ServerSession::Create(TestConfig());

  DoHandshake(**client_session, **server_session);

  absl::StatusOr<std::optional<SessionRequest>> request =
      (*client_session)->GetOutgoingMessage();
  ASSERT_THAT(request, IsOk());
  ASSERT_THAT(*request, Eq(std::nullopt));

  absl::StatusOr<std::optional<SessionResponse>> response =
      (*server_session)->GetOutgoingMessage();
  ASSERT_THAT(response, IsOk());
  ASSERT_THAT(*response, Eq(std::nullopt));
}

TEST(ClientServerSessionTest, AcceptEmptyReadResult) {
  auto client_session = ClientSession::Create(TestConfig());
  auto server_session = ServerSession::Create(TestConfig());

  DoHandshake(**client_session, **server_session);

  absl::StatusOr<std::optional<v1::PlaintextMessage>> client_read =
      (*client_session)->Read();
  ASSERT_THAT(client_read, IsOk());
  ASSERT_THAT(*client_read, Eq(std::nullopt));

  absl::StatusOr<std::optional<v1::PlaintextMessage>> server_read =
      (*server_session)->Read();
  ASSERT_THAT(server_read, IsOk());
  ASSERT_THAT(*server_read, Eq(std::nullopt));
}

TEST(ClientServerSessionTest, ClientEncryptServerDecrypt) {
  auto client_session = ClientSession::Create(TestConfig());
  auto server_session = ServerSession::Create(TestConfig());

  DoHandshake(**client_session, **server_session);

  v1::PlaintextMessage plaintext_message_request;
  plaintext_message_request.set_plaintext("Hello Server");

  ASSERT_THAT((*client_session)->Write(plaintext_message_request), IsOk());
  absl::StatusOr<std::optional<SessionRequest>> request =
      (*client_session)->GetOutgoingMessage();
  ASSERT_THAT(request, IsOk());
  ASSERT_THAT(*request, Ne(std::nullopt));

  ASSERT_THAT((*server_session)->PutIncomingMessage(**request), IsOk());
  absl::StatusOr<std::optional<v1::PlaintextMessage>> received_request =
      (*server_session)->Read();
  ASSERT_THAT(received_request, IsOk());
  ASSERT_THAT(*received_request, Ne(std::nullopt));

  EXPECT_THAT((**received_request).plaintext(),
              Eq(plaintext_message_request.plaintext()));
}

TEST(ClientServerSessionTest, ServerEncryptClientDecrypt) {
  auto client_session = ClientSession::Create(TestConfig());
  auto server_session = ServerSession::Create(TestConfig());

  DoHandshake(**client_session, **server_session);

  v1::PlaintextMessage plaintext_message_response;
  plaintext_message_response.set_plaintext("Hello Client");

  ASSERT_THAT((*server_session)->Write(plaintext_message_response), IsOk());
  absl::StatusOr<std::optional<SessionResponse>> response =
      (*server_session)->GetOutgoingMessage();
  ASSERT_THAT(response, IsOk());
  ASSERT_THAT(*response, Ne(std::nullopt));

  ASSERT_THAT((*client_session)->PutIncomingMessage(**response), IsOk());
  absl::StatusOr<std::optional<v1::PlaintextMessage>> received_request =
      (*client_session)->Read();
  ASSERT_THAT(received_request, IsOk());
  ASSERT_THAT(*received_request, Ne(std::nullopt));

  EXPECT_THAT((**received_request).plaintext(),
              Eq(plaintext_message_response.plaintext()));
}

}  // namespace
}  // namespace oak::session
