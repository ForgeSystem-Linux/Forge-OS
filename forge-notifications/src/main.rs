use anyhow::Result;
use serde::{Deserialize, Serialize};
use zbus::connection::Builder;
use zbus::interface;
use std::sync::Arc;
use tokio::sync::RwLock;

/// Notification data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Notification {
    pub id: u32,
    pub app_name: String,
    pub summary: String,
    pub body: String,
    pub app_icon: String,
    pub actions: Vec<String>,
    pub timestamp: u64,
}

/// Shared notification state
struct NotificationState {
    notifications: RwLock<Vec<Notification>>,
    next_id: RwLock<u32>,
}

struct Notifications {
    state: Arc<NotificationState>,
}

#[interface(name = "org.freedesktop.Notifications")]
impl Notifications {
    async fn notify(
        &self,
        app_name: &str,
        replaces_id: u32,
        app_icon: &str,
        summary: &str,
        body: &str,
        actions: Vec<&str>,
        _hints: std::collections::HashMap<&str, zbus::zvariant::Value<'_>>,
        _expire_timeout: i32,
    ) -> u32 {
        let mut state = self.state.notifications.write().await;
        let mut next_id = self.state.next_id.write().await;

        let id = if replaces_id > 0 {
            replaces_id
        } else {
            let id = *next_id;
            *next_id += 1;
            id
        };

        let notification = Notification {
            id,
            app_name: app_name.to_string(),
            summary: summary.to_string(),
            body: body.to_string(),
            app_icon: app_icon.to_string(),
            actions: actions.into_iter().map(String::from).collect(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };

        tracing::info!(
            "Notification from '{}': {} - {}",
            notification.app_name,
            notification.summary,
            notification.body
        );

        // Store notification
        if replaces_id > 0 {
            if let Some(existing) = state.iter_mut().find(|n| n.id == replaces_id) {
                *existing = notification.clone();
            } else {
                state.push(notification.clone());
            }
        } else {
            state.push(notification.clone());
        }

        // Emit signal for UI to pick up
        // TODO: Emit D-Bus signal to notify UI

        id
    }

    async fn close_notification(&self, id: u32) {
        let mut state = self.state.notifications.write().await;
        state.retain(|n| n.id != id);
        tracing::info!("Closed notification {}", id);
    }

    async fn get_server_information(&self) -> (&str, &str, &str, &str) {
        ("Forge Notification Server", "Forge DE", "0.1.0", "1.2")
    }

    async fn get_capabilities(&self) -> Vec<&str> {
        vec!["body", "body-markup", "icon-static", "persistence", "actions"]
    }

    /// Get all active notifications
    async fn get_notifications(&self) -> String {
        let state = self.state.notifications.read().await;
        serde_json::to_string(&*state).unwrap_or_else(|_| "[]".to_string())
    }

    /// Clear all notifications
    async fn clear_all(&self) {
        let mut state = self.state.notifications.write().await;
        state.clear();
        tracing::info!("Cleared all notifications");
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

    tracing::info!("Starting Forge notification daemon");

    let state = Arc::new(NotificationState {
        notifications: RwLock::new(Vec::new()),
        next_id: RwLock::new(1),
    });

    let notifications = Notifications {
        state: state.clone(),
    };

    let _conn = Builder::session()?
        .name("org.freedesktop.Notifications")?
        .serve_at("/org/freedesktop/Notifications", notifications)?
        .build()
        .await?;

    tracing::info!("Notification daemon running");

    std::future::pending::<()>().await;

    Ok(())
}
