use smithay::input::Seat;
use smithay::wayland::selection::data_device::{
    ClientDndGrabHandler, DataDeviceHandler, DataDeviceState, ServerDndGrabHandler,
};

use crate::state::ForgeState;

impl ClientDndGrabHandler for ForgeState {}
impl ServerDndGrabHandler for ForgeState {
    fn send(&mut self, _mime_type: String, _fd: std::os::unix::io::OwnedFd, _seat: Seat<Self>) {}
}

impl DataDeviceHandler for ForgeState {
    fn data_device_state(&self) -> &DataDeviceState {
        &self.data_device_state
    }
}
