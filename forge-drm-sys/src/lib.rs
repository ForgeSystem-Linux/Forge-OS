//! FFI bindings for libliftoff, libdisplay-info, and related DRM libraries

#![allow(non_camel_case_types)]
#![allow(non_upper_case_globals)]

use libc::{c_int, c_uint, c_void};

// Opaque types
pub enum lo_device {}
pub enum lo_output {}
pub enum lo_layer {}
pub enum di_info {}
pub enum di_mode {}

// libliftoff device
extern "C" {
    pub fn lo_device_create_drm(fd: c_int) -> *mut lo_device;
    pub fn lo_device_destroy(device: *mut lo_device);
    pub fn lo_device_get_drm_fd(device: *mut lo_device) -> c_int;

    // libliftoff output
    pub fn lo_output_create(
        device: *mut lo_device,
        crtc_id: u32,
        connector_id: u32,
    ) -> *mut lo_output;
    pub fn lo_output_destroy(output: *mut lo_output);
    pub fn lo_output_get_crtc_id(output: *mut lo_output) -> u32;
    pub fn lo_output_get_connector_id(output: *mut lo_output) -> u32;
    pub fn lo_output_set_name(output: *mut lo_output, name: *const libc::c_char);

    // libliftoff layer
    pub fn lo_layer_create(output: *mut lo_output) -> *mut lo_layer;
    pub fn lo_layer_destroy(layer: *mut lo_layer);
    pub fn lo_layer_set_surface(layer: *mut lo_layer, width: u32, height: u32);
    pub fn lo_layer_set_source_crop(
        layer: *mut lo_layer,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
    );
    pub fn lo_layer_set_dest_crop(
        layer: *mut lo_layer,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
    );
    pub fn lo_layer_set_zpos(layer: *mut lo_layer, zpos: u32);
    pub fn lo_layer_set_alpha(layer: *mut lo_layer, alpha: f32);
    pub fn lo_layer_set_enabled(layer: *mut lo_layer, enabled: bool);
    pub fn lo_layer_commit(layer: *mut lo_layer) -> c_int;

    // libliftoff plane assignment
    pub fn lo_layer_get_plane_id(layer: *mut lo_layer) -> u32;
}

// libdisplay-info
extern "C" {
    pub fn di_info_create_from_fd(fd: c_int, drm_id: u32) -> *mut di_info;
    pub fn di_info_destroy(info: *mut di_info);
    pub fn di_info_get_connector_type(info: *mut di_info) -> u32;
    pub fn di_info_get_connector_type_id(info: *mut di_info) -> u32;
    pub fn di_info_get_width_mm(info: *mut di_info) -> u32;
    pub fn di_info_get_height_mm(info: *mut di_info) -> u32;
    pub fn di_info_get_modes(info: *mut di_info, count: *mut u32) -> *const *const di_mode;
    pub fn di_mode_get_width(mode: *const di_mode) -> u32;
    pub fn di_mode_get_height(mode: *const di_mode) -> u32;
    pub fn di_mode_get_vrefresh(mode: *const di_mode) -> u32;
}

// DRM helpers
extern "C" {
    pub fn drmModeGetResources(fd: c_int) -> *mut c_void;
    pub fn drmModeGetCrtc(fd: c_int, crtc_id: u32) -> *mut c_void;
    pub fn drmModeGetConnector(fd: c_int, connector_id: u32) -> *mut c_void;
    pub fn drmModeGetEncoder(fd: c_int, encoder_id: u32) -> *mut c_void;
    pub fn drmModeSetCrtc(
        fd: c_int,
        crtc_id: u32,
        buffer_id: u32,
        x: u32,
        y: u32,
        connectors: *mut u32,
        count_connectors: c_int,
        mode_info: *const drmModeModeInfo,
    ) -> c_int;
    pub fn drmModePageFlip(
        fd: c_int,
        crtc_id: u32,
        buffer_id: u32,
        flags: u32,
        user_data: *mut c_void,
    ) -> c_int;
    pub fn drmHandleEvent(fd: c_int, evctx: *mut drmEventContext) -> c_int;
    pub fn drmModeFreeResources(resources: *mut c_void);
    pub fn drmModeFreeCrtc(crtc: *mut c_void);
    pub fn drmModeFreeConnector(connector: *mut c_void);
    pub fn drmModeFreeEncoder(encoder: *mut c_void);

    pub fn drmSetMaster(fd: c_int) -> c_int;
    pub fn drmDropMaster(fd: c_int) -> c_int;
    pub fn drmModeGetPlaneResources(fd: c_int) -> *mut c_void;
    pub fn drmModeGetPlane(fd: c_int, plane_id: u32) -> *mut c_void;
    pub fn drmModeFreePlaneResources(resources: *mut c_void);
    pub fn drmModeFreePlane(plane: *mut c_void);
}

#[repr(C)]
pub struct drmModeModeInfo {
    pub clock: u32,
    pub hdisplay: u16,
    pub hsync_start: u16,
    pub hsync_end: u16,
    pub htotal: u16,
    pub hskew: u16,
    pub vdisplay: u16,
    pub vsync_start: u16,
    pub vsync_end: u16,
    pub vtotal: u16,
    pub vscan: u16,
    pub vrefresh: u32,
    pub flags: u32,
    pub type_: u32,
    pub name: [i8; 32],
}

#[repr(C)]
pub struct drmEventContext {
    pub version: c_int,
    pub vblank_handler: Option<unsafe extern "C" fn(c_int, u32, u32, u32, *mut c_void)>,
    pub page_flip_handler: Option<unsafe extern "C" fn(c_int, u32, u32, u32, *mut c_void)>,
}

pub const DRM_MODE_PAGE_FLIP: u32 = 0x0200;
pub const DRM_MODE_PAGE_FLIP_EVENT: u32 = 0x0200;
pub const DRM_PAGE_FLIP_EVENT: u32 = 0x1;
