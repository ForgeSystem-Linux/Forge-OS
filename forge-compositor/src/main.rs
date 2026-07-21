mod decorations;
#[cfg(feature = "drm")]
mod drm;
mod grabs;
mod handlers;
mod input;

pub mod state;

use std::sync::Arc;

use clap::Parser;
use smithay::backend::input::{InputEvent, KeyboardKeyEvent};
use smithay::backend::renderer::element::Kind;
use smithay::backend::renderer::gles::GlesRenderer;
use smithay::backend::renderer::{Color32F, Frame, Renderer};
use smithay::backend::winit::{self, WinitEvent};
use smithay::input::keyboard::FilterResult;
use smithay::reexports::wayland_server::{Display, ListeningSocket};
use smithay::wayland::compositor::{with_surface_tree_downward, SurfaceAttributes, TraversalAction};
use tracing_subscriber::{fmt, EnvFilter};
use ::winit::platform::pump_events::PumpStatus;

use state::{ClientState, ForgeState};

#[derive(Parser)]
#[command(name = "forge-compositor")]
#[command(about = "Forge Desktop Environment - Wayland Compositor")]
struct Cli {
    /// Backend to use (winit, drm)
    #[arg(short, long, default_value = "winit")]
    backend: String,

    /// Socket name for Wayland
    #[arg(short, long, default_value = "wayland-5")]
    socket: String,

    /// Launch a terminal on startup
    #[arg(short, long)]
    terminal: Option<String>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let cli = Cli::parse();

    tracing::info!("Starting Forge compositor v{}", env!("CARGO_PKG_VERSION"));
    tracing::info!("Backend: {}, Socket: {}", cli.backend, cli.socket);

    match cli.backend.as_str() {
        "winit" => run_winit(&cli),
        "drm" => {
            #[cfg(feature = "drm")]
            {
                let mut display: Display<ForgeState> = Display::new()?;
                let dh = display.handle();
                let mut state = ForgeState::new(dh.clone());
                drm::run_drm(&mut state)?;
                // DRM backend falls through to winit for now
                tracing::info!("DRM initialized, using winit for rendering");
                run_winit(&cli)
            }
            #[cfg(not(feature = "drm"))]
            {
                tracing::warn!("DRM backend not compiled in, falling back to winit");
                tracing::info!("To enable DRM, build with: cargo build --features drm");
                run_winit(&cli)
            }
        }
        _ => {
            tracing::error!("Unknown backend '{}', using winit", cli.backend);
            run_winit(&cli)
        }
    }
}

pub fn run_winit(cli: &Cli) -> Result<(), Box<dyn std::error::Error>> {
    let mut display: Display<ForgeState> = Display::new()?;
    let mut dh = display.handle();

    let mut state = ForgeState::new(dh.clone());

    let listener = ListeningSocket::bind(&cli.socket)?;
    let mut clients = Vec::new();

    let (mut backend, mut winit) = winit::init::<GlesRenderer>()?;

    let start_time = std::time::Instant::now();

    let keyboard = state.seat.add_keyboard(Default::default(), 200, 200)?;

    std::env::set_var("WAYLAND_DISPLAY", &cli.socket);

    if let Some(ref terminal) = cli.terminal {
        std::process::Command::new(terminal).spawn().ok();
    } else {
        std::process::Command::new("weston-terminal").spawn().ok();
    }

    tracing::info!("Compositor initialized, entering main loop");
    tracing::info!("Workspaces: {}", state.workspaces.len());

    loop {
        let status = winit.dispatch_new_events(|event| match event {
            WinitEvent::Resized { .. } => {}
            WinitEvent::Input(event) => match event {
                InputEvent::Keyboard { event } => {
                    let key_state = event.state();
                    keyboard.input::<(), _>(
                        &mut state,
                        event.key_code(),
                        key_state,
                        0.into(),
                        0,
                        |state, _mods, handle| {
                            input::handle_keyboard_shortcuts(state, &handle, key_state);
                            FilterResult::Forward
                        },
                    );

                    if let Some(focus) = state.keyboard_focus.clone() {
                        keyboard.set_focus(&mut state, Some(focus), 0.into());
                    }
                }
                InputEvent::PointerMotionAbsolute { .. } => {
                    if state.keyboard_focus.is_none() {
                        if let Some(surface) =
                            state.xdg_shell_state.toplevel_surfaces().iter().next().cloned()
                        {
                            let surface = surface.wl_surface().clone();
                            keyboard.set_focus(&mut state, Some(surface), 0.into());
                        }
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
            let elements = state
                .xdg_shell_state
                .toplevel_surfaces()
                .iter()
                .flat_map(|surface| {
                    smithay::backend::renderer::element::surface::render_elements_from_surface_tree(
                        renderer,
                        surface.wl_surface(),
                        (0, 0),
                        1.0,
                        1.0,
                        Kind::Unspecified,
                    )
                })
                .collect::<Vec<smithay::backend::renderer::element::surface::WaylandSurfaceRenderElement<GlesRenderer>>>();

            let mut frame = renderer.render(
                &mut framebuffer,
                size,
                smithay::utils::Transform::Flipped180,
            )?;
            frame.clear(Color32F::new(0.1, 0.0, 0.0, 1.0), &[damage])?;
            smithay::backend::renderer::utils::draw_render_elements(
                &mut frame,
                1.0,
                &elements,
                &[damage],
            )?;
            let _ = frame.finish()?;

            for surface in state.xdg_shell_state.toplevel_surfaces() {
                send_frames_surface_tree(
                    surface.wl_surface(),
                    start_time.elapsed().as_millis() as u32,
                );
            }

            if let Some(stream) = listener.accept()? {
                tracing::info!("Got a client");
                let client =
                    dh.insert_client(stream, Arc::new(ClientState::default()))?;
                clients.push(client);
            }

            display.dispatch_clients(&mut state)?;
            display.flush_clients()?;
        }

        backend.submit(Some(&[damage]))?;
    }
}

pub fn send_frames_surface_tree(
    surface: &smithay::reexports::wayland_server::protocol::wl_surface::WlSurface,
    time: u32,
) {
    with_surface_tree_downward(
        surface,
        (),
        |_, _, &()| TraversalAction::DoChildren(()),
        |_surf, states, &()| {
            for callback in states
                .cached_state
                .get::<SurfaceAttributes>()
                .current()
                .frame_callbacks
                .drain(..)
            {
                callback.done(time);
            }
        },
        |_, _, &()| true,
    );
}
