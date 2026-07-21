use std::time::Instant;

use smithay::delegate_compositor;
use smithay::delegate_data_device;
use smithay::delegate_seat;
use smithay::delegate_shm;
use smithay::delegate_xdg_shell;
use smithay::input::{Seat, SeatHandler, SeatState};
use smithay::reexports::wayland_server::backend::{ClientData, ClientId, DisconnectReason};
use smithay::reexports::wayland_server::DisplayHandle;
use smithay::wayland::buffer::BufferHandler;
use smithay::wayland::compositor::{CompositorClientState, CompositorState};
use smithay::wayland::selection::data_device::DataDeviceState;
use smithay::wayland::selection::SelectionHandler;
use smithay::wayland::shell::xdg::{ToplevelSurface, XdgShellState};
use smithay::wayland::shm::{ShmHandler, ShmState};

pub struct ForgeState {
    pub start_time: Instant,
    pub dh: DisplayHandle,

    pub compositor_state: CompositorState,
    pub xdg_shell_state: XdgShellState,
    pub shm_state: ShmState,
    pub seat_state: SeatState<Self>,
    pub data_device_state: DataDeviceState,

    pub seat: Seat<Self>,

    pub keyboard_focus: Option<smithay::reexports::wayland_server::protocol::wl_surface::WlSurface>,

    // Window tracking
    pub windows: Vec<WindowInfo>,
    pub active_window: Option<usize>,

    // Workspace support
    pub workspaces: Vec<Workspace>,
    pub active_workspace: usize,
}

#[derive(Debug, Clone)]
pub struct WindowInfo {
    pub surface: ToplevelSurface,
    pub title: String,
    pub app_id: String,
    pub geometry: smithay::utils::Rectangle<i32, smithay::utils::Logical>,
    pub position: smithay::utils::Point<i32, smithay::utils::Logical>,
    pub is_maximized: bool,
    pub is_minimized: bool,
    pub is_focused: bool,
    pub workspace: usize,
    // Server-side decoration state
    pub decorations: DecorationsState,
}

#[derive(Debug, Clone)]
pub struct DecorationsState {
    pub mode: DecorationMode,
    pub titlebar_height: i32,
}

#[derive(Debug, Clone, PartialEq)]
pub enum DecorationMode {
    ServerSide,
    ClientSide,
    None,
}

impl Default for DecorationsState {
    fn default() -> Self {
        Self {
            mode: DecorationMode::ServerSide,
            titlebar_height: 32,
        }
    }
}

impl WindowInfo {
    pub fn new(surface: ToplevelSurface, workspace: usize) -> Self {
        Self {
            surface,
            title: String::new(),
            app_id: String::new(),
            geometry: smithay::utils::Rectangle::from_size((800, 600).into()),
            position: (0, 0).into(),
            is_maximized: false,
            is_minimized: false,
            is_focused: false,
            workspace,
            decorations: DecorationsState::default(),
        }
    }

    /// Get the total geometry including titlebar
    pub fn total_geometry(&self) -> smithay::utils::Rectangle<i32, smithay::utils::Logical> {
        let mut geo = self.geometry;
        if self.decorations.mode == DecorationMode::ServerSide {
            geo.size.h += self.decorations.titlebar_height;
        }
        geo
    }
}

#[derive(Debug, Clone)]
pub struct Workspace {
    pub name: String,
    pub windows: Vec<usize>,
}

impl Workspace {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            windows: Vec::new(),
        }
    }
}

#[derive(Default)]
pub struct ClientState {
    pub compositor_state: CompositorClientState,
}

impl ClientData for ClientState {
    fn initialized(&self, _client_id: ClientId) {}
    fn disconnected(&self, _client_id: ClientId, _reason: DisconnectReason) {}
}

delegate_compositor!(ForgeState);
delegate_xdg_shell!(ForgeState);
delegate_shm!(ForgeState);
delegate_seat!(ForgeState);
delegate_data_device!(ForgeState);

impl BufferHandler for ForgeState {
    fn buffer_destroyed(
        &mut self,
        _buffer: &smithay::reexports::wayland_server::protocol::wl_buffer::WlBuffer,
    ) {
    }
}

impl SelectionHandler for ForgeState {
    type SelectionUserData = ();
}

impl ForgeState {
    pub fn new(dh: DisplayHandle) -> Self {
        let compositor_state = CompositorState::new::<Self>(&dh);
        let xdg_shell_state = XdgShellState::new::<Self>(&dh);
        let shm_state = ShmState::new::<Self>(&dh, vec![]);
        let mut seat_state = SeatState::new();
        let seat = seat_state.new_wl_seat(&dh, "forge-seat");
        let data_device_state = DataDeviceState::new::<Self>(&dh);

        // Create initial workspaces
        let workspaces = vec![
            Workspace::new("1"),
            Workspace::new("2"),
            Workspace::new("3"),
            Workspace::new("4"),
        ];

        Self {
            start_time: Instant::now(),
            dh,
            compositor_state,
            xdg_shell_state,
            shm_state,
            seat_state,
            data_device_state,
            seat,
            keyboard_focus: None,
            windows: Vec::new(),
            active_window: None,
            workspaces,
            active_workspace: 0,
        }
    }

    pub fn add_window(&mut self, surface: ToplevelSurface) {
        let workspace = self.active_workspace;
        let mut info = WindowInfo::new(surface, workspace);

        // Position window in current workspace
        let offset = self.workspaces[workspace].windows.len() * 50;
        info.position = (100 + offset as i32, 100 + offset as i32).into();

        let idx = self.windows.len();
        self.windows.push(info);
        self.workspaces[workspace].windows.push(idx);
        tracing::info!(
            "Window added to workspace '{}' (total: {})",
            self.workspaces[workspace].name,
            self.windows.len()
        );
    }

    pub fn remove_window(
        &mut self,
        surface: &smithay::reexports::wayland_server::protocol::wl_surface::WlSurface,
    ) {
        let idx = self.windows.iter().position(|w| w.surface.wl_surface() == surface);
        if let Some(idx) = idx {
            let workspace = self.windows[idx].workspace;
            self.workspaces[workspace].windows.retain(|&i| i != idx);
            self.windows.remove(idx);
            // Reindex remaining windows in workspace
            for ws in &mut self.workspaces {
                for i in &mut ws.windows {
                    if *i > idx {
                        *i -= 1;
                    }
                }
            }
            tracing::info!("Window removed, total: {}", self.windows.len());
        }
        self.active_window = None;
    }

    pub fn focus_next_window(&mut self) {
        let ws = &self.workspaces[self.active_workspace];
        if ws.windows.is_empty() {
            self.keyboard_focus = None;
            self.active_window = None;
            return;
        }

        let next = match self.active_window {
            Some(idx) => {
                if let Some(pos) = ws.windows.iter().position(|&i| i == idx) {
                    ws.windows[(pos + 1) % ws.windows.len()]
                } else {
                    ws.windows[0]
                }
            }
            None => ws.windows[0],
        };

        self.active_window = Some(next);
        self.keyboard_focus = Some(self.windows[next].surface.wl_surface().clone());
        tracing::info!("Focused window: {} on workspace {}", next, self.active_workspace);
    }

    pub fn focus_previous_window(&mut self) {
        let ws = &self.workspaces[self.active_workspace];
        if ws.windows.is_empty() {
            self.keyboard_focus = None;
            self.active_window = None;
            return;
        }

        let prev = match self.active_window {
            Some(idx) => {
                if let Some(pos) = ws.windows.iter().position(|&i| i == idx) {
                    let new_pos = if pos == 0 { ws.windows.len() - 1 } else { pos - 1 };
                    ws.windows[new_pos]
                } else {
                    ws.windows[0]
                }
            }
            None => ws.windows[0],
        };

        self.active_window = Some(prev);
        self.keyboard_focus = Some(self.windows[prev].surface.wl_surface().clone());
    }

    pub fn close_active_window(&mut self) {
        if let Some(idx) = self.active_window {
            if idx < self.windows.len() {
                let surface = self.windows[idx].surface.wl_surface().clone();
                self.remove_window(&surface);
                self.focus_next_window();
            }
        }
    }

    pub fn switch_workspace(&mut self, target: usize) {
        if target >= self.workspaces.len() {
            return;
        }
        // Minimize all windows on current workspace
        let current_ws = self.active_workspace;
        for &idx in &self.workspaces[current_ws].windows.clone() {
            if idx < self.windows.len() {
                self.windows[idx].is_minimized = true;
            }
        }
        // Show all windows on target workspace
        for &idx in &self.workspaces[target].windows.clone() {
            if idx < self.windows.len() {
                self.windows[idx].is_minimized = false;
            }
        }
        self.active_workspace = target;
        self.active_window = None;
        self.keyboard_focus = None;
        self.focus_next_window();
        tracing::info!("Switched to workspace '{}'", self.workspaces[target].name);
    }

    pub fn move_window_to_workspace(&mut self, target: usize) {
        if target >= self.workspaces.len() {
            return;
        }
        if let Some(idx) = self.active_window {
            if idx < self.windows.len() {
                let old_ws = self.windows[idx].workspace;
                self.workspaces[old_ws].windows.retain(|&i| i != idx);
                self.windows[idx].workspace = target;
                self.workspaces[target].windows.push(idx);
                self.active_window = None;
                self.keyboard_focus = None;
                self.focus_next_window();
                tracing::info!("Moved window {} to workspace '{}'", idx, self.workspaces[target].name);
            }
        }
    }

    pub fn maximize_toggle(&mut self) {
        if let Some(idx) = self.active_window {
            if idx < self.windows.len() {
                self.windows[idx].is_maximized = !self.windows[idx].is_maximized;
            }
        }
    }

    pub fn minimize_active_window(&mut self) {
        if let Some(idx) = self.active_window {
            if idx < self.windows.len() {
                self.windows[idx].is_minimized = true;
                self.active_window = None;
                self.keyboard_focus = None;
                self.focus_next_window();
            }
        }
    }
}

impl ShmHandler for ForgeState {
    fn shm_state(&self) -> &ShmState {
        &self.shm_state
    }
}

impl SeatHandler for ForgeState {
    type KeyboardFocus = smithay::reexports::wayland_server::protocol::wl_surface::WlSurface;
    type PointerFocus = smithay::reexports::wayland_server::protocol::wl_surface::WlSurface;
    type TouchFocus = smithay::reexports::wayland_server::protocol::wl_surface::WlSurface;

    fn seat_state(&mut self) -> &mut SeatState<Self> {
        &mut self.seat_state
    }

    fn focus_changed(
        &mut self,
        _seat: &Seat<Self>,
        focused: Option<&smithay::reexports::wayland_server::protocol::wl_surface::WlSurface>,
    ) {
        self.keyboard_focus = focused.cloned();
    }

    fn cursor_image(
        &mut self,
        _seat: &Seat<Self>,
        _image: smithay::input::pointer::CursorImageStatus,
    ) {
    }
}
