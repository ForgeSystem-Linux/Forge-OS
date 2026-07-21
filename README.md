<div align="center">

# Forge

**A modern Wayland desktop environment built with Rust and Qt 6**

![Forge](https://img.shields.io/badge/Forge-DE-blue?style=for-the-badge)
![Rust](https://img.shields.io/badge/Rust-2021-orange?style=for-the-badge&logo=rust)
![Qt](https://img.shields.io/badge/Qt-6-green?style=for-the-badge&logo=qt)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

</div>

---

## What is Forge?

Forge is a complete desktop environment for Linux, built from scratch using **Rust** for the compositor and system services, **QML/Qt 6** for the user interface, and **Shell scripts** for system integration.

### Features

- **Custom Wayland Compositor** - Built on Smithay with DRM/KMS support via libliftoff
- **Desktop Shell** - Panel, start menu, desktop icons, system tray
- **Display Manager** - Custom login screen with user selection
- **System Installer** - Full installation wizard
- **Session Manager** - User session handling
- **Notification System** - D-Bus notification daemon
- **Clipboard Manager** - Clipboard history and management
- **Screenshot Tool** - Screen capture with multiple modes
- **Privilege Escalation** - Secure pkexec integration
- **Settings App** - System configuration
- **Immutable System** - Flatpak-only app model (planned)

## Architecture

```
forge/
├── forge-compositor/      # Wayland compositor (Rust + Smithay)
├── forge-shell/           # Desktop shell (QML/Qt 6)
├── forge-greeter/         # Display manager
├── forge-installer/       # System installer
├── forge-notifications/   # Notification daemon
├── forge-session/         # Session manager
├── forge-privilege/       # pkexec helper
├── forge-clip/            # Clipboard manager
├── forge-screenshot/      # Screenshot tool
├── forge-settings/        # Settings app
├── forge-system/          # System configs (Limine, Plymouth)
└── forge-drm-sys/         # DRM bindings (libliftoff)
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Compositor | Rust + Smithay 0.7 |
| DRM Backend | libliftoff + libdisplay-info |
| UI Framework | QML + Qt 6 |
| IPC | D-Bus (zbus) |
| Session | systemd-logind |
| Authentication | PAM |
| Bootloader | Limine |
| Display Manager | Custom Wayland greeter |

## Quick Start

### Test the Shell (in Hyprland/Sway)

```bash
# Install Qt QML tools
sudo pacman -S qt6-declarative

# Run the shell as a window
forge-shell-direct
```

### Test the Display Manager

```bash
# Run DM in test mode (windowed)
forge-dm --test
```

### Test the Installer

```bash
# Run installer in test mode (no changes made)
forge-installer --test
```

## Building

### Prerequisites

```bash
# Arch Linux
sudo pacman -S rust cmake qt6-base qt6-declarative qt6-wayland \
    wayland libinput libseat libgbm mesalib xkbcommon \
    polkit pam
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/ForgeSystem-Linux/Forge-OS.git
cd Forge-OS

# Build all components
cargo build --release

# Or use Make
make release

# Install to ~/.local/bin
make install
```

### Build ISO

```bash
# Install archiso
sudo pacman -S archiso

# Build the ISO
sudo ./forge-system/build.sh
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super` | Toggle start menu |
| `Super+Space` | App launcher |
| `Alt+Tab` | Switch windows |
| `Alt+F4` | Close window |
| `Ctrl+Alt+T` | Open terminal |
| `Super+1-4` | Switch workspace |
| `Super+Shift+1-4` | Move window to workspace |

## Configuration

Configuration is stored in `~/.config/forge/config.toml`:

```toml
language = "en"
accent_color = "#89b4fa"
wallpaper = ""
keyboard_layout = "us"
theme = "dark"
```

## Roadmap

- [x] Wayland compositor with Smithay
- [x] Desktop shell with real app icons
- [x] Display manager
- [x] System installer
- [x] DRM backend with libliftoff
- [x] Clipboard manager
- [x] Screenshot tool
- [ ] Full DRM mode setting
- [ ] XWayland support
- [ ] Multi-monitor support
- [ ] Window tiling
- [ ] Plugin system
- [ ] Plymouth theme
- [ ] Immutable system support

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Smithay](https://github.com/Smithay/smithay) - Wayland compositor library
- [libliftoff](https://gitlab.freedesktop.org/emersion/libliftoff) - DRM output management
- [Catppuccin](https://github.com/catppuccin/catppuccin) - Color palette
- [Arch Linux](https://archlinux.org/) - Base distribution
