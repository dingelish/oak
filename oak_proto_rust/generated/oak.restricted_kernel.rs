/// The initial payload provided to a restricted kernel instance on startup. This
/// can contain the binary, as well as any other initialization information that
/// might be needed (like endorsements).
#[allow(clippy::derive_partial_eq_without_eq)]
#[derive(Clone, PartialEq, ::prost_derive::Message)]
pub struct InitialData {
    /// The restricted kernel ELF application binary bytes.
    #[prost(bytes = "vec", tag = "1")]
    pub application_bytes: ::prost::alloc::vec::Vec<u8>,
    /// The serialized endorsement bytes.
    #[prost(bytes = "vec", tag = "2")]
    pub endorsement_bytes: ::prost::alloc::vec::Vec<u8>,
}
