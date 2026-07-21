.PHONY: all clean install uninstall dev test shell

# Default target
all: release

# Development build
dev:
	cargo build

# Release build
release:
	cargo build --release

# Clean build artifacts
clean:
	cargo clean

# Run in development mode
run-dev: dev
	./target/debug/forge-compositor --backend winit

# Run greeter in development mode
run-greeter: dev
	sudo ./target/debug/forge-greeter

# Run shell in direct mode (window inside existing compositor)
shell:
	./forge-shell/direct/forge-shell-direct

# Install system-wide
install: release
	@echo "Installing Forge DE..."
	install -Dm755 target/release/forge-compositor $(DESTDIR)/usr/bin/forge-compositor
	install -Dm755 target/release/forge-shell $(DESTDIR)/usr/bin/forge-shell
	install -Dm755 target/release/forge-settings $(DESTDIR)/usr/bin/forge-settings
	install -Dm755 target/release/forge-notifications $(DESTDIR)/usr/bin/forge-notifications
	install -Dm755 target/release/forge-privilege $(DESTDIR)/usr/bin/forge-privilege
	install -Dm755 target/release/forge-session $(DESTDIR)/usr/bin/forge-session
	install -Dm755 target/release/forge-greeter $(DESTDIR)/usr/bin/forge-greeter
	install -Dm755 target/release/forge-clip $(DESTDIR)/usr/bin/forge-clip
	install -Dm755 target/release/forge-screenshot $(DESTDIR)/usr/bin/forge-screenshot
	
	@echo "Installing systemd services..."
	install -Dm644 systemd/forge-compositor.service $(DESTDIR)/etc/systemd/system/forge-compositor.service
	install -Dm644 systemd/forge-notifications.service $(DESTDIR)/etc/systemd/system/forge-notifications.service
	install -Dm644 systemd/forge-privilege.service $(DESTDIR)/etc/systemd/system/forge-privilege.service
	install -Dm644 systemd/forge-session.service $(DESTDIR)/etc/systemd/system/forge-session.service
	install -Dm644 systemd/forge-greeter.service $(DESTDIR)/etc/systemd/system/forge-greeter.service
	
	@echo "Installing PAM configuration..."
	install -Dm644 pam/forge-greeter $(DESTDIR)/etc/pam.d/forge-greeter
	install -Dm644 pam/forge-session $(DESTDIR)/etc/pam.d/forge-session
	
	@echo "Installing D-Bus configuration..."
	install -Dm644 forge-privilege/org.forge.Privilege.conf $(DESTDIR)/etc/dbus-1/system.d/org.forge.Privilege.conf
	
	@echo "Installing PolicyKit policy..."
	install -Dm644 forge-privilege/org.forge.Privilege.policy $(DESTDIR)/usr/share/polkit-1/actions/org.forge.Privilege.policy
	
	@echo "Installing XDG session..."
	install -Dm644 xdg-autostart/forge.desktop $(DESTDIR)/usr/share/wayland-sessions/forge.desktop
	
	@echo "Installing QML files..."
	install -Dm644 forge-shell/qml/*.qml $(DESTDIR)/usr/share/forge/qml/
	install -Dm755 forge-shell/direct/forge-shell-direct $(DESTDIR)/usr/bin/forge-shell-direct
	install -Dm644 forge-shell/direct/forge-shell-direct.qml $(DESTDIR)/usr/share/forge/forge-shell-direct.qml
	
	@echo "Installation complete!"
	@echo ""
	@echo "To enable the display manager:"
	@echo "  sudo systemctl enable forge-greeter"
	@echo "  sudo systemctl start forge-greeter"
	@echo ""
	@echo "To use as a user session:"
	@echo "  forge-compositor --backend winit"

# Uninstall
uninstall:
	@echo "Uninstalling Forge DE..."
	rm -f $(DESTDIR)/usr/bin/forge-compositor
	rm -f $(DESTDIR)/usr/bin/forge-shell
	rm -f $(DESTDIR)/usr/bin/forge-settings
	rm -f $(DESTDIR)/usr/bin/forge-notifications
	rm -f $(DESTDIR)/usr/bin/forge-privilege
	rm -f $(DESTDIR)/usr/bin/forge-session
	rm -f $(DESTDIR)/usr/bin/forge-greeter
	rm -f $(DESTDIR)/usr/bin/forge-clip
	rm -f $(DESTDIR)/usr/bin/forge-screenshot
	rm -f $(DESTDIR)/etc/systemd/system/forge-*.service
	rm -f $(DESTDIR)/etc/pam.d/forge-*
	rm -f $(DESTDIR)/etc/dbus-1/system.d/org.forge.Privilege.conf
	rm -f $(DESTDIR)/usr/share/polkit-1/actions/org.forge.Privilege.policy
	rm -f $(DESTDIR)/usr/share/wayland-sessions/forge.desktop
	rm -rf $(DESTDIR)/usr/share/forge/
	@echo "Uninstallation complete!"

# Test
test:
	cargo test

# Lint
lint:
	cargo clippy -- -D warnings

# Format
format:
	cargo fmt

# Check all crates
check:
	cargo check

# Build documentation
docs:
	cargo doc --open
