all:
	tar xzf ${CLOUD_HYPERVISOR_SRC_TAR}
	cargo build --features="tdx" --manifest-path cloud-hypervisor-38.0/Cargo.toml
	mkdir -p target
	cp ./cloud-hypervisor-38.0/target/x86_64-unknown-linux-gnu/debug/cloud-hypervisor target/
