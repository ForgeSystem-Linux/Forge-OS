use anyhow::Result;

pub struct PamAuth;

impl PamAuth {
    pub fn authenticate(username: &str, password: &str) -> Result<()> {
        tracing::info!("PAM authentication for user: {}", username);

        // Use a subprocess to run the PAM check via `su` or `login`
        // This is simpler and more reliable than raw PAM FFI
        let result = std::process::Command::new("su")
            .arg("-c")
            .arg("echo ok")
            .arg(username)
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn();

        match result {
            Ok(mut child) => {
                if let Some(ref mut stdin) = child.stdin {
                    use std::io::Write;
                    let _ = stdin.write_all(password.as_bytes());
                    let _ = stdin.write_all(b"\n");
                    let _ = stdin.flush();
                }

                let output = child.wait_with_output()?;
                if output.status.success() {
                    tracing::info!("PAM authentication successful for: {}", username);
                    Ok(())
                } else {
                    let stderr = String::from_utf8_lossy(&output.stderr);
                    anyhow::bail!("Authentication failed: {}", stderr.trim())
                }
            }
            Err(e) => {
                anyhow::bail!("Failed to run auth command: {}", e)
            }
        }
    }
}
