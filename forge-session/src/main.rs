use anyhow::Result;
use tokio::process::Command;
use zbus::connection::Builder;
use zbus::interface;

struct SessionManager;

#[interface(name = "org.forge.Session")]
impl SessionManager {
    async fn logout(&self) {
        tracing::info!("Logout requested");
        // Try systemd-logind first, then fallback to killing processes
        let _ = Command::new("loginctl")
            .args(["terminate-user", &std::env::var("USER").unwrap_or_default()])
            .output()
            .await;
    }

    async fn reboot(&self) {
        tracing::info!("Reboot requested");
        let _ = Command::new("systemctl")
            .arg("reboot")
            .output()
            .await;
    }

    async fn power_off(&self) {
        tracing::info!("Power off requested");
        let _ = Command::new("systemctl")
            .arg("poweroff")
            .output()
            .await;
    }

    async fn suspend(&self) {
        tracing::info!("Suspend requested");
        let _ = Command::new("systemctl")
            .arg("suspend")
            .output()
            .await;
    }

    async fn hibernate(&self) {
        tracing::info!("Hibernate requested");
        let _ = Command::new("systemctl")
            .arg("hibernate")
            .output()
            .await;
    }

    async fn lock_screen(&self) {
        tracing::info!("Lock screen requested");
        let _ = Command::new("loginctl")
            .arg("lock-session")
            .output()
            .await;
    }

    async fn switch_user(&self, username: String) {
        tracing::info!("Switch user requested: {}", username);
        let _ = Command::new("loginctl")
            .args(["activate", &username])
            .output()
            .await;
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

    tracing::info!("Starting Forge session manager");

    let _conn = Builder::session()?
        .name("org.forge.Session")?
        .serve_at("/org/forge/Session", SessionManager)?
        .build()
        .await?;

    tracing::info!("Session manager running");

    std::future::pending::<()>().await;

    Ok(())
}
