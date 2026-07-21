use anyhow::{Context, Result};
use nix::unistd::{fork, ForkResult, execv, setuid, setgid, Uid, Gid};
use users::os::unix::UserExt;
use std::ffi::CString;

pub struct SessionLauncher;

impl SessionLauncher {
    pub fn launch(username: &str) -> Result<u32> {
        let user = users::get_user_by_name(username)
            .context(format!("User '{}' not found", username))?;

        let uid = user.uid();
        let gid = user.primary_group_id();
        let home_dir = user.home_dir().to_string_lossy().to_string();
        let shell = user.shell().to_string_lossy().to_string();

        tracing::info!(
            "Launching session for {} (uid={}, gid={}, home={}, shell={})",
            username, uid, gid, home_dir, shell
        );

        match unsafe { fork() } {
            Ok(ForkResult::Parent { child }) => {
                tracing::info!("Session process forked with PID: {}", child);
                Ok(child.as_raw() as u32)
            }
            Ok(ForkResult::Child) => {
                std::env::set_var("HOME", &home_dir);
                std::env::set_var("USER", username);
                std::env::set_var("SHELL", &shell);
                std::env::set_var("LOGNAME", username);
                std::env::set_var("PATH", "/usr/local/bin:/usr/bin:/bin");
                std::env::set_var("XDG_RUNTIME_DIR", format!("/run/user/{}", uid));
                std::env::set_var("XDG_SESSION_TYPE", "wayland");
                std::env::set_var("XDG_CURRENT_DESKTOP", "Forge");
                std::env::set_var("WAYLAND_DISPLAY", "wayland-0");

                if let Err(e) = nix::unistd::chdir(&*home_dir) {
                    tracing::error!("Failed to chdir to {}: {}", home_dir, e);
                    let _ = nix::unistd::chdir("/");
                }

                if let Err(e) = setgid(Gid::from_raw(gid)) {
                    tracing::error!("Failed to setgid: {}", e);
                }
                if let Err(e) = setuid(Uid::from_raw(uid)) {
                    tracing::error!("Failed to setuid: {}", e);
                }

                let compositor = CString::new("forge-compositor").unwrap();
                let arg0 = CString::new("forge-compositor").unwrap();
                let arg1 = CString::new("--backend=winit").unwrap();
                let arg2 = CString::new("--socket=wayland-0").unwrap();

                match execv(&compositor, &[arg0, arg1, arg2]) {
                    Ok(_) => unreachable!(),
                    Err(e) => {
                        tracing::error!("Failed to exec compositor: {}", e);
                        let shell_c = CString::new(shell.as_str()).unwrap();
                        let shell_arg = CString::new("-l").unwrap();
                        let _ = execv(&shell_c, &[shell_c.clone(), shell_arg]);
                        std::process::exit(1);
                    }
                }
            }
            Err(e) => {
                anyhow::bail!("Failed to fork: {}", e);
            }
        }
    }
}
