use anyhow::{Context, Result};
use std::os::unix::io::OwnedFd;

use crate::state::ForgeState;

/// DRM backend using libliftoff and libdisplay-info
pub struct DrmBackend {
    fd: OwnedFd,
    device: *mut forge_drm_sys::lo_device,
    outputs: Vec<DrmOutput>,
    drm_fd: i32,
}

struct DrmOutput {
    output: *mut forge_drm_sys::lo_output,
    crtc_id: u32,
    connector_id: u32,
    width: u32,
    height: u32,
    name: String,
}

impl DrmBackend {
    pub fn new() -> Result<Self> {
        tracing::info!("Initializing DRM backend with libliftoff");

        // Open DRM device
        let drm_path = find_drm_device()?;
        let fd = std::fs::OpenOptions::new()
            .read(true)
            .write(true)
            .open(&drm_path)
            .context(format!("Failed to open DRM device: {}", drm_path))?;

        let drm_fd = std::os::unix::io::AsRawFd::as_raw_fd(&fd);

        // Create libliftoff device
        let device = unsafe { forge_drm_sys::lo_device_create_drm(drm_fd) };
        if device.is_null() {
            anyhow::bail!("Failed to create libliftoff device");
        }

        tracing::info!("DRM device opened: {}", drm_path);

        // Take DRM master
        let ret = unsafe { forge_drm_sys::drmSetMaster(drm_fd) };
        if ret != 0 {
            tracing::warn!("Failed to take DRM master (may already have it)");
        }

        // Enumerate outputs
        let outputs = enumerate_outputs(device, drm_fd)?;

        tracing::info!("Found {} outputs", outputs.len());
        for output in &outputs {
            tracing::info!("  {}x{} {}", output.width, output.height, output.name);
        }

        Ok(Self {
            fd,
            device,
            outputs,
            drm_fd,
        })
    }

    pub fn output_count(&self) -> usize {
        self.outputs.len()
    }

    pub fn primary_output(&self) -> Option<&DrmOutput> {
        self.outputs.first()
    }

    pub fn modes(&self, output_idx: usize) -> Vec<(u32, u32, u32)> {
        if output_idx >= self.outputs.len() {
            return vec![];
        }

        let output = &self.outputs[output_idx];
        // Query modes from display-info
        // For now return the current mode
        vec![(output.width, output.height, 60)]
    }
}

impl Drop for DrmBackend {
    fn drop(&mut self) {
        unsafe {
            // Drop DRM master
            forge_drm_sys::drmDropMaster(self.drm_fd);

            // Cleanup libliftoff
            for output in &self.outputs {
                forge_drm_sys::lo_output_destroy(output.output);
            }
            forge_drm_sys::lo_device_destroy(self.device);
        }
    }
}

fn find_drm_device() -> Result<String> {
    // Try to find a DRM device from /dev/dri/
    let dri_path = "/dev/dri";
    let entries = std::fs::read_dir(dri_path).context("Failed to read /dev/dri")?;

    for entry in entries {
        let entry = entry?;
        let name = entry.file_name().to_string_lossy().to_string();

        if name.starts_with("card") {
            return Ok(entry.path().to_string_lossy().to_string());
        }
    }

    anyhow::bail!("No DRM device found in /dev/dri")
}

fn enumerate_outputs(
    device: *mut forge_drm_sys::lo_device,
    drm_fd: i32,
) -> Result<Vec<DrmOutput>> {
    let mut outputs = Vec::new();

    // Get DRM resources
    let resources = unsafe { forge_drm_sys::drmModeGetResources(drm_fd) };
    if resources.is_null() {
        anyhow::bail!("Failed to get DRM resources");
    }

    // For now, create a single output
    // In production, this would enumerate connectors from DRM resources
    // and create libliftoff outputs for each

    // Cleanup
    unsafe { forge_drm_sys::drmModeFreeResources(resources) };

    Ok(outputs)
}

/// Initialize DRM session via libseat
pub fn init_seat_session() -> Result<()> {
    tracing::info!("DRM backend ready");
    tracing::info!("In production, this would:");
    tracing::info!("  1. Open DRM device via libseat");
    tracing::info!("  2. Enumerate CRTCs and connectors");
    tracing::info!("  3. Create libliftoff outputs");
    tracing::info!("  4. Allocate GBM buffers");
    tracing::info!("  5. Create EGL surfaces");
    tracing::info!("  6. Render frames via OpenGL");
    tracing::info!("  7. Present via DRM page flip");

    Ok(())
}
