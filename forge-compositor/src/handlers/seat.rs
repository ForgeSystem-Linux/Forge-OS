use smithay::delegate_seat;
use smithay::input::{Seat, SeatHandler, SeatState};
use smithay::reexports::wayland_server::protocol::wl_seat;
use smithay::reexports::wayland_server::{Client, Resource};

use crate::state::ForgeState;

impl SeatHandler for ForgeState {
    fn seat_state(&mut self) -> &mut SeatState<Self> {
        // We need to store seat state in our struct
        // For now, this is a placeholder
        unimplemented!()
    }

    fn focus_changed(
        &mut self,
        _seat: &Seat<Self>,
        _focused: Option<&smithay::input::Target<Self>>,
        _dh: &smithay::reexports::wayland_server::DisplayHandle,
        _qhandle: &smithay::reexports::wayland_server::QueueHandle<Self>,
    ) {
        // Focus change handling
    }

    fn cursor_image(
        &mut self,
        _seat: &Seat<Self>,
        _image: smithay::input::pointer::CursorImageStatus,
        _dh: &smithay::reexports::wayland_server::DisplayHandle,
        _qhandle: &smithay::reexports::wayland_server::QueueHandle<Self>,
    ) {
        // Cursor image handling
    }
}
