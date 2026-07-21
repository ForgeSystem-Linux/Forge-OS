use anyhow::Result;
use forge_config::ForgeConfig;

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    tracing::info!("Starting Forge settings");

    let config = ForgeConfig::load()?;
    tracing::info!("Loaded config: {:?}", config);

    tracing::info!("TODO: Initialize Qt 6 application");
    tracing::info!("TODO: Load SettingsWindow.qml");

    Ok(())
}
