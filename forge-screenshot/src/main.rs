use anyhow::Result;
use clap::Parser;
use std::process::Command;

#[derive(Parser)]
#[command(name = "forge-screenshot")]
#[command(about = "Forge DE Screenshot Tool")]
struct Cli {
    /// Capture full screen
    #[arg(short, long)]
    fullscreen: bool,

    /// Capture active window
    #[arg(short, long)]
    window: bool,

    /// Capture selection area
    #[arg(short, long)]
    area: bool,

    /// Copy to clipboard instead of saving
    #[arg(short, long)]
    clipboard: bool,

    /// Custom output path
    #[arg(short, long)]
    output: Option<String>,

    /// Delay in seconds before capture
    #[arg(short, long, default_value = "0")]
    delay: u32,
}

fn get_screenshot_path() -> String {
    let pictures_dir = dirs::picture_dir()
        .unwrap_or_else(|| std::path::PathBuf::from("."))
        .join("Screenshots");

    std::fs::create_dir_all(&pictures_dir).ok();

    let timestamp = chrono::Local::now().format("%Y-%m-%d_%H-%M-%S");
    pictures_dir
        .join(format!("forge-screenshot-{}.png", timestamp))
        .to_string_lossy()
        .to_string()
}

fn take_screenshot(args: &Cli) -> Result<()> {
    if args.delay > 0 {
        tracing::info!("Waiting {} seconds...", args.delay);
        std::thread::sleep(std::time::Duration::from_secs(args.delay as u64));
    }

    let output_path = args.output.clone().unwrap_or_else(get_screenshot_path);

    // Try different screenshot tools in order of preference
    let tools = [
        // grim (Wayland native)
        if args.fullscreen {
            vec!["grim".to_string(), output_path.clone()]
        } else if args.window {
            vec![
                "grim".to_string(),
                "-g".to_string(),
                "$(slurp -w)".to_string(),
                output_path.clone(),
            ]
        } else if args.area {
            vec![
                "grim".to_string(),
                "-g".to_string(),
                "$(slurp)".to_string(),
                output_path.clone(),
            ]
        } else {
            vec![
                "grim".to_string(),
                "-g".to_string(),
                "$(slurp)".to_string(),
                output_path.clone(),
            ]
        },
        // scrot (X11 fallback)
        vec!["scrot".to_string(), output_path.clone()],
    ];

    for tool in &tools {
        let cmd = &tool[0];
        let args_list = &tool[1..];

        if Command::new("which").arg(cmd).output().is_ok() {
            tracing::info!("Using {} for screenshot", cmd);
            let output = Command::new(cmd)
                .args(args_list)
                .output();

            match output {
                Ok(out) => {
                    if out.status.success() {
                        tracing::info!("Screenshot saved to: {}", output_path);

                        // Copy to clipboard if requested
                        if args.clipboard {
                            copy_to_clipboard(&output_path)?;
                        }

                        // Send notification
                        send_notification(&output_path)?;

                        return Ok(());
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to run {}: {}", cmd, e);
                }
            }
        }
    }

    anyhow::bail!("No screenshot tool found. Install grim or scrot.")
}

fn copy_to_clipboard(path: &str) -> Result<()> {
    // Try wl-copy (Wayland)
    if Command::new("which").arg("wl-copy").output().is_ok() {
        let output = Command::new("wl-copy")
            .arg("--type")
            .arg("image/png")
            .stdin(std::process::Stdio::piped())
            .spawn();

        if let Ok(mut child) = output {
            if let Some(ref mut stdin) = child.stdin {
                use std::io::Write;
                let data = std::fs::read(path)?;
                let _ = stdin.write_all(&data);
            }
            child.wait()?;
        }
    }

    // Try xclip (X11 fallback)
    if Command::new("which").arg("xclip").output().is_ok() {
        let _ = Command::new("xclip")
            .args(["-selection", "clipboard", "-t", "image/png", "-i", path])
            .output();
    }

    Ok(())
}

fn send_notification(path: &str) -> Result<()> {
    // Try notify-send
    if Command::new("which").arg("notify-send").output().is_ok() {
        let _ = Command::new("notify-send")
            .args([
                "--icon=camera-photo",
                "Screenshot Saved",
                &format!("Saved to: {}", path),
            ])
            .output();
    }

    Ok(())
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let args = Cli::parse();

    tracing::info!("Forge Screenshot Tool");

    take_screenshot(&args)
}
