use smithay::backend::renderer::gles::GlesRenderer;
use smithay::backend::renderer::{Color32F, Frame, Renderer};
use smithay::backend::winit::{self, WinitEvent};
use smithay::backend::input::{InputEvent, KeyboardKeyEvent};
use smithay::reexports::wayland_server::Display;
use tracing_subscriber::{fmt, EnvFilter};
use ::winit::platform::pump_events::PumpStatus;

mod pam_auth;
mod session;

struct GreeterState {
    username: String,
    password: String,
    error_message: String,
    users: Vec<UserEntry>,
    selected_user: usize,
}

#[derive(Debug, Clone)]
struct UserEntry {
    name: String,
    home_dir: String,
    shell: String,
}

impl GreeterState {
    fn new() -> Self {
        let users = list_users();
        Self {
            username: String::new(),
            password: String::new(),
            error_message: String::new(),
            users,
            selected_user: 0,
        }
    }
}

fn list_users() -> Vec<UserEntry> {
    let mut users = Vec::new();

    if let Ok(content) = std::fs::read_to_string("/etc/passwd") {
        for line in content.lines() {
            let parts: Vec<&str> = line.split(':').collect();
            if parts.len() >= 7 {
                let uid: u32 = parts[2].parse().unwrap_or(0);
                let shell = parts[6].to_string();

                if uid >= 1000 && !shell.ends_with("/nologin") && !shell.ends_with("/false") {
                    users.push(UserEntry {
                        name: parts[0].to_string(),
                        home_dir: parts[5].to_string(),
                        shell,
                    });
                }
            }
        }
    }

    users.sort_by(|a, b| a.name.cmp(&b.name));
    users
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    tracing::info!("Starting Forge Greeter v{}", env!("CARGO_PKG_VERSION"));

    let greeter_state = GreeterState::new();
    tracing::info!("Found {} users", greeter_state.users.len());

    let (mut backend, mut winit) = winit::init::<GlesRenderer>()?;

    tracing::info!("Greeter initialized, entering main loop");

    loop {
        let status = winit.dispatch_new_events(|event| match event {
            WinitEvent::Resized { .. } => {}
            WinitEvent::Input(event) => match event {
                InputEvent::Keyboard { event } => {
                    if event.state() == smithay::backend::input::KeyState::Pressed {
                        // Handle keyboard for login
                    }
                }
                _ => {}
            },
            _ => (),
        });

        match status {
            PumpStatus::Continue => (),
            PumpStatus::Exit(_) => return Ok(()),
        };

        let size = backend.window_size();
        let damage = smithay::utils::Rectangle::from_size(size);
        {
            let (renderer, mut framebuffer) = backend.bind()?;
            let mut frame = renderer.render(&mut framebuffer, size, smithay::utils::Transform::Flipped180)?;
            frame.clear(Color32F::new(0.11, 0.11, 0.18, 1.0), &[damage])?;
            let _ = frame.finish()?;
        }

        backend.submit(None)?;
    }
}
