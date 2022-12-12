//
// Copyright 2022 The Project Oak Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#![no_std]
#![no_main]
#![feature(cstr_from_bytes_until_nul)]

use core::{alloc::Layout, arch::asm, ffi::c_void, mem::MaybeUninit, panic::PanicInfo};
use goblin::elf::header;
use oak_sev_guest::io::PortFactoryWrapper;
use static_alloc::bump::Bump;
use x86_64::{
    instructions::{hlt, interrupts::int3, segmentation::Segment, tlb},
    registers::{
        control::{Cr3, Cr3Flags},
        segmentation::*,
    },
    structures::{
        gdt::{Descriptor, GlobalDescriptorTable, SegmentSelector},
        idt::InterruptDescriptorTable,
        paging::{
            page_table::{PageTable, PageTableFlags},
            PageSize, PhysFrame, Size2MiB,
        },
    },
    PhysAddr, VirtAddr,
};

mod acpi;
mod asm;
mod cmos;
mod fw_cfg;
mod logging;
mod sev;
mod zero_page;

#[link_section = ".boot"]
static mut BOOT_ALLOC: MaybeUninit<Bump<[u8; 128 * 1024]>> = MaybeUninit::uninit();

#[link_section = ".boot.secrets"]
static SEV_SECRETS: MaybeUninit<oak_sev_guest::secrets::SecretsPage> = MaybeUninit::uninit();
#[link_section = ".boot.cpuid"]
static SEV_CPUID: MaybeUninit<oak_sev_guest::cpuid::CpuidPage> = MaybeUninit::uninit();

extern "C" {
    #[link_name = "pd_addr"]
    static BIOS_PD: c_void;

    #[link_name = "pt_addr"]
    static BIOS_PT: c_void;

    #[link_name = "boot_stack_pointer"]
    static BOOT_STACK_POINTER: c_void;
}

/// Creates page tables that identity-map the first 1GiB of memory using 2MiB hugepages.
pub fn create_page_tables(
    pml4: &mut PageTable,
    pdpt: &mut PageTable,
    pd: &mut PageTable,
    encrypted: u64,
) {
    pml4.zero();
    pml4[0].set_addr(
        PhysAddr::new(pdpt as *const _ as u64 | encrypted),
        PageTableFlags::PRESENT | PageTableFlags::WRITABLE,
    );

    pdpt.zero();
    pdpt[0].set_addr(
        PhysAddr::new(pd as *const _ as u64 | encrypted),
        PageTableFlags::PRESENT | PageTableFlags::WRITABLE,
    );

    pd.iter_mut().enumerate().for_each(|(i, entry)| {
        entry.set_addr(
            PhysAddr::new(((i as u64) * Size2MiB::SIZE) | encrypted),
            PageTableFlags::PRESENT | PageTableFlags::WRITABLE | PageTableFlags::HUGE_PAGE,
        );
    });
}

pub fn create_gdt(gdt: &mut GlobalDescriptorTable) -> (SegmentSelector, SegmentSelector) {
    let cs = gdt.add_entry(Descriptor::kernel_code_segment());
    let ds = gdt.add_entry(Descriptor::kernel_data_segment());
    (cs, ds)
}

pub fn create_idt(_idt: &mut InterruptDescriptorTable) {}

/// Passes control to the operating system kernel. No more code from the BIOS will run.
///
/// # Safety
///
/// This assumes that the kernel entry point is valid.
pub unsafe fn jump_to_kernel(entry_point: VirtAddr, zero_page: usize) -> ! {
    asm!(
        // Boot stack pointer
        "mov {1}, %rsp",
        // Zero page address
        "mov {2}, %rsi",
        // ...and away we go!
        "jmp *{0}",
        in(reg) entry_point.as_u64(),
        in(reg) &BOOT_STACK_POINTER as *const _ as u64,
        in(reg) zero_page as u64,
        options(noreturn, att_syntax)
    );
}

/// Entry point for the Rust code in the stage0 BIOS.
///
/// # Arguments
///
/// * `encrypted` - If not zero, the `encrypted`-th bit will be set in the page tables.
#[no_mangle]
pub extern "C" fn rust64_start(encrypted: u64) -> ! {
    let (es, snp) = if encrypted > 0 {
        // We're under some form of memory encryption, thus it's safe to access the SEV_STATUS MSR.
        let status =
            oak_sev_guest::msr::get_sev_status().unwrap_or(oak_sev_guest::msr::SevStatus::empty());
        (
            status.contains(oak_sev_guest::msr::SevStatus::SEV_ES_ENABLED),
            status.contains(oak_sev_guest::msr::SevStatus::SNP_ACTIVE),
        )
    } else {
        (false, false)
    };

    // We assume 0-th bit is never the encrypted bit.
    let encrypted = if encrypted > 0 { 1 << encrypted } else { 0 };

    // If we're under SEV-ES or SNP, we need a GHCB block for communication.
    let ghcb_protocol = if es {
        Some(sev::init_ghcb(snp, encrypted))
    } else {
        None
    };

    logging::init_logging(match ghcb_protocol {
        Some(protocol) => PortFactoryWrapper::new_ghcb(protocol),
        None => PortFactoryWrapper::new_raw(),
    });
    log::info!("starting...");

    // Safety: we assume there won't be any other hardware devices using the fw_cfg IO ports.
    let mut fwcfg = unsafe {
        fw_cfg::FwCfg::new(match ghcb_protocol {
            Some(protocol) => PortFactoryWrapper::new_ghcb(protocol),
            None => PortFactoryWrapper::new_raw(),
        })
    }
    .expect("fw_cfg device not found!");

    let zero_page = zero_page::init_zero_page(
        &mut fwcfg,
        match ghcb_protocol {
            Some(protocol) => PortFactoryWrapper::new_ghcb(protocol),
            None => PortFactoryWrapper::new_raw(),
        },
    );

    if snp {
        sev::validate_memory(zero_page, encrypted);
    }

    // Initialize the bump allocator.
    // Safety: we're the only thread, and we need to explicitly zero out the internal state if we're
    // running under memory encryption.
    let alloc = unsafe { BOOT_ALLOC.write(Bump::uninit()) };

    /* Set up the machine according to the 64-bit Linux boot protocol.
     * See https://www.kernel.org/doc/html/latest/x86/boot.html#id1 for the particular requirements.
     */

    let gdt = alloc
        .leak(GlobalDescriptorTable::new())
        .expect("Failed to allocate memory for GDT");

    let (cs, ds) = create_gdt(gdt);
    gdt.load();
    // Safety: we've set up the valid data structures in create_gdt, above.
    unsafe {
        CS::set_reg(cs);
        DS::set_reg(ds);
        ES::set_reg(ds);
        FS::set_reg(ds);
        GS::set_reg(ds);
        SS::set_reg(ds);
    }

    let idt = alloc
        .leak(InterruptDescriptorTable::new())
        .expect("Failed to allocate memory for IDT");

    create_idt(idt);
    idt.load();

    let pml4 = alloc
        .leak(PageTable::new())
        .expect("Failed to allocate memory for PML4");
    let pdpt = alloc
        .leak(PageTable::new())
        .expect("Failed to allocate memory for PDPT");
    let pd = alloc
        .leak(PageTable::new())
        .expect("Failed to allocate memory for PD");
    create_page_tables(pml4, pdpt, pd, encrypted);
    /* We need to do some trickery here. All of the stage0 code is somewhere within [4G-2M; 4G).
     * Thus, let's keep our own last PD, so that we can continue executing after reloading the
     * page tables.
     * Same for the first 2M of memory; we're using 4K pages there, so keep that around.
     */
    // Safety: dereferencing the raw pointer is safe as that's the currently in-use page directory.
    pd[0].set_addr(
        PhysAddr::new(unsafe { &BIOS_PT } as *const _ as u64 | encrypted),
        PageTableFlags::PRESENT | PageTableFlags::WRITABLE,
    );
    pdpt[3].set_addr(
        PhysAddr::new(unsafe { &BIOS_PD } as *const _ as u64 | encrypted),
        PageTableFlags::PRESENT | PageTableFlags::WRITABLE,
    );
    // Safety: changing the page tables here is safe because (a) we've populated the new page tables
    // at the well-known address of BOOT_PML4_ADDR and (b) we've ensured we keep the mapping for our
    // own code.
    unsafe {
        Cr3::write(
            PhysFrame::from_start_address(PhysAddr::new(pml4 as *const _ as u64)).unwrap(),
            Cr3Flags::empty(),
        );
    }

    if snp {
        let cc_blob = alloc
            .leak(oak_linux_boot_params::CCBlobSevInfo::new(
                SEV_SECRETS.as_ptr(),
                SEV_CPUID.as_ptr(),
            ))
            .expect("Failed to allocate memory for CCBlobSevInfo");
        let setup_data = alloc
            .leak(oak_linux_boot_params::CCSetupData::new(cc_blob))
            .expect("Failed to allocate memory for CCSetupData");

        // Put our header as the first element in the linked list.
        setup_data.header.next = zero_page.hdr.setup_data;
        zero_page.hdr.setup_data = &setup_data.header as *const oak_linux_boot_params::SetupData;
    }

    if let Ok(cmdline_size) = fwcfg.read_cmdline_size() {
        if cmdline_size > 0 {
            let mut buf = alloc
                .alloc(
                    Layout::from_size_align(cmdline_size as usize, 1)
                        .expect("failed to create layout for kernel command line"),
                )
                .expect("failed to allocate memory for kernel command line");
            // Safety: we've now allocated (at least) `cmdline_size` worth of bytes, so turning the
            // memory into a slice is safe.
            let buf =
                unsafe { core::slice::from_raw_parts_mut(buf.as_mut(), cmdline_size as usize) };
            fwcfg
                .read_cmdline(buf)
                .expect("failed to read kernel command line from fw_cfg");
            zero_page.hdr.cmdline_size = cmdline_size;
            zero_page.hdr.cmd_line_ptr = buf.as_ptr() as u32;
        }
    }

    // Attempt to parse 64 bytes at 0x200000 (2MiB) as an ELF header. If it works, extract the entry
    // point address from there; if there is no valid ELF header at that address, assume it's code,
    // and jump there directly.
    // Safety: this assumes the kernel is loaded at the given address.
    let mut entry = VirtAddr::new(0x200000);
    let header = header::header64::Header::from_bytes(unsafe {
        &*(entry.as_u64() as *const [u8; header::header64::SIZEOF_EHDR])
    });
    if header.e_ident[0] == header::ELFMAG[0]
        && header.e_ident[1] == header::ELFMAG[1]
        && header.e_ident[2] == header::ELFMAG[2]
        && header.e_ident[3] == header::ELFMAG[3]
        && header.e_ident[4] == header::ELFCLASS64
        && header.e_ident[5] == header::ELFDATA2LSB
        && header.e_ident[6] == header::EV_CURRENT
        && header.e_ident[7] == header::ELFOSABI_SYSV
    {
        // Looks like we have a valid ELF header at 0x200000. Trust its entry point.
        entry = VirtAddr::new(header.e_entry);
    }

    zero_page.acpi_rsdp_addr = acpi::build_acpi_tables(&mut fwcfg).unwrap();

    log::info!("jumping to kernel at {:#018x}", entry.as_u64());

    // Clean-ups we need to do just before we jump to the kernel proper: clean up the early GHCB we
    // used and switch back to a hugepage for the first 2M of memory.
    if ghcb_protocol.is_some() {
        sev::deinit_ghcb(snp, encrypted);
    }

    // Allow identity-op to keep the fact that the address we're talking about here is 0x00.
    #[allow(clippy::identity_op)]
    pd[0].set_addr(
        PhysAddr::new(0x00 | encrypted),
        PageTableFlags::PRESENT | PageTableFlags::WRITABLE | PageTableFlags::HUGE_PAGE,
    );
    tlb::flush_all();

    unsafe {
        jump_to_kernel(entry, zero_page as *const _ as usize);
    }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    log::error!("{}", info);

    // Trigger a breakpoint exception. As we don't have a #BP handler, this will triple fault and
    // terminate the program.
    int3();

    loop {
        hlt();
    }
}
