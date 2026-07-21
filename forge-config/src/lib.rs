use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

/// Main configuration for Forge DE
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ForgeConfig {
    pub general: GeneralConfig,
    pub appearance: AppearanceConfig,
    pub keybindings: KeybindingsConfig,
    pub panel: PanelConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneralConfig {
    pub compositor_backend: String,
    pub seat_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppearanceConfig {
    pub theme: String,
    pub icon_theme: String,
    pub cursor_theme: String,
    pub font: String,
    pub font_size: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeybindingsConfig {
    pub terminal: String,
    pub launcher: String,
    pub close_window: String,
    pub maximize_window: String,
    pub tile_left: String,
    pub tile_right: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PanelConfig {
    pub position: String,
    pub height: u32,
    pub show_tray: bool,
    pub show_clock: bool,
}

impl Default for ForgeConfig {
    fn default() -> Self {
        Self {
            general: GeneralConfig {
                compositor_backend: "winit".to_string(),
                seat_name: "forge-seat".to_string(),
            },
            appearance: AppearanceConfig {
                theme: "Adwaita".to_string(),
                icon_theme: "Adwaita".to_string(),
                cursor_theme: "Adwaita".to_string(),
                font: "Sans".to_string(),
                font_size: 11,
            },
            keybindings: KeybindingsConfig {
                terminal: "Return".to_string(),
                launcher: "Super".to_string(),
                close_window: "Q".to_string(),
                maximize_window: "M".to_string(),
                tile_left: "Left".to_string(),
                tile_right: "Right".to_string(),
            },
            panel: PanelConfig {
                position: "bottom".to_string(),
                height: 40,
                show_tray: true,
                show_clock: true,
            },
        }
    }
}

impl ForgeConfig {
    /// Load configuration from file or create default
    pub fn load() -> Result<Self> {
        let config_path = Self::config_path()?;

        if config_path.exists() {
            let content = fs::read_to_string(&config_path)?;
            let config: Self = toml::from_str(&content)?;
            Ok(config)
        } else {
            let config = Self::default();
            config.save()?;
            Ok(config)
        }
    }

    /// Save configuration to file
    pub fn save(&self) -> Result<()> {
        let config_path = Self::config_path()?;

        // Create config directory if it doesn't exist
        if let Some(parent) = config_path.parent() {
            fs::create_dir_all(parent)?;
        }

        let content = toml::to_string_pretty(self)?;
        fs::write(&config_path, content)?;
        Ok(())
    }

    /// Get the path to the configuration file
    fn config_path() -> Result<PathBuf> {
        let config_dir = dirs::config_dir()
            .ok_or_else(|| anyhow::anyhow!("Could not determine config directory"))?;
        Ok(config_dir.join("forge").join("config.toml"))
    }
}
