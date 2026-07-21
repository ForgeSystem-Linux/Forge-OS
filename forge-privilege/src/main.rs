use anyhow::Result;
use tokio::process::Command;
use zbus::connection::Builder;
use zbus::interface;

pub mod client;

/// Forge privilege escalation service
/// Provides D-Bus interface for running commands as root via pkexec
struct ForgePrivilege;

#[interface(name = "org.forge.Privilege")]
impl ForgePrivilege {
    /// Execute a command with root privileges via pkexec
    /// Returns (exit_code, stdout, stderr)
    async fn execute(
        &self,
        command: Vec<String>,
        env_vars: std::collections::HashMap<String, String>,
    ) -> (i32, String, String) {
        if command.is_empty() {
            return (-1, String::new(), "No command provided".to_string());
        }

        let cmd = &command[0];
        let args = &command[1..];

        tracing::info!(
            "Executing privileged command: {} {}",
            cmd,
            args.join(" ")
        );

        // Build pkexec command
        let mut pkexec = Command::new("pkexec");
        pkexec.arg(cmd);
        pkexec.args(args);

        // Set environment variables
        for (key, value) in &env_vars {
            pkexec.env(key, value);
        }

        match pkexec.output().await {
            Ok(output) => {
                let exit_code = output.status.code().unwrap_or(-1);
                let stdout = String::from_utf8_lossy(&output.stdout).to_string();
                let stderr = String::from_utf8_lossy(&output.stderr).to_string();

                tracing::info!("Command exited with code: {}", exit_code);

                (exit_code, stdout, stderr)
            }
            Err(e) => {
                tracing::error!("Failed to execute command: {}", e);
                (-1, String::new(), format!("Failed to execute: {}", e))
            }
        }
    }

    /// Check if a command is available
    async fn check_command(&self, command: String) -> bool {
        Command::new("which")
            .arg(&command)
            .output()
            .await
            .map(|output| output.status.success())
            .unwrap_or(false)
    }

    /// Get the current user
    async fn get_user(&self) -> String {
        std::env::var("USER").unwrap_or_else(|_| "unknown".to_string())
    }

    /// Check if running as root
    async fn is_root(&self) -> bool {
        unsafe { libc::getuid() == 0 }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    tracing::info!("Starting Forge privilege escalation service");

    let _conn = Builder::session()?
        .name("org.forge.Privilege")?
        .serve_at("/org/forge/Privilege", ForgePrivilege)?
        .build()
        .await?;

    tracing::info!("Privilege escalation service running");

    std::future::pending::<()>().await;

    Ok(())
}
