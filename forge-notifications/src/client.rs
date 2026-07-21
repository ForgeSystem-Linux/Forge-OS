use anyhow::Result;
use zbus::proxy::Builder;

/// D-Bus proxy for the Forge notification server
#[zbus::proxy(
    interface = "org.freedesktop.Notifications",
    default_service = "org.freedesktop.Notifications",
    default_path = "/org/freedesktop/Notifications"
)]
trait Notifications {
    /// Send a notification
    async fn notify(
        &self,
        app_name: &str,
        replaces_id: u32,
        app_icon: &str,
        summary: &str,
        body: &str,
        actions: Vec<&str>,
        hints: std::collections::HashMap<&str, zbus::zvariant::Value<'_>>,
        expire_timeout: i32,
    ) -> zbus::Result<u32>;

    /// Close a notification
    async fn close_notification(&self, id: u32) -> zbus::Result<()>;

    /// Get server information
    async fn get_server_information(&self) -> zbus::Result<(String, String, String, String)>;

    /// Get capabilities
    async fn get_capabilities(&self) -> zbus::Result<Vec<String>>;

    /// Get all notifications as JSON
    async fn get_notifications(&self) -> zbus::Result<String>;

    /// Clear all notifications
    async fn clear_all(&self) -> zbus::Result<()>;
}

/// Client for the Forge notification server
pub struct NotificationClient {
    proxy: NotificationsProxy<'static>,
}

impl NotificationClient {
    /// Create a new notification client
    pub async fn new() -> Result<Self> {
        let connection = zbus::Connection::session().await?;
        let proxy = Builder::new(&connection).build().await?;
        Ok(Self { proxy })
    }

    /// Send a simple notification
    pub async fn notify(
        &self,
        app_name: &str,
        summary: &str,
        body: &str,
    ) -> Result<u32> {
        self.proxy
            .notify(
                app_name,
                0,
                "",
                summary,
                body,
                vec![],
                std::collections::HashMap::new(),
                5000,
            )
            .await
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Send a notification with actions
    pub async fn notify_with_actions(
        &self,
        app_name: &str,
        summary: &str,
        body: &str,
        actions: Vec<&str>,
    ) -> Result<u32> {
        self.proxy
            .notify(
                app_name,
                0,
                "",
                summary,
                body,
                actions,
                std::collections::HashMap::new(),
                5000,
            )
            .await
            .map_err(|e| anyhow::anyhow!(e))
    }

    /// Close a notification
    pub async fn close(&self, id: u32) -> Result<()> {
        self.proxy.close_notification(id).await.map_err(|e| anyhow::anyhow!(e))
    }

    /// Get server information
    pub async fn server_info(&self) -> Result<(String, String, String, String)> {
        self.proxy.get_server_information().await.map_err(|e| anyhow::anyhow!(e))
    }

    /// Get all notifications
    pub async fn get_notifications(&self) -> Result<String> {
        self.proxy.get_notifications().await.map_err(|e| anyhow::anyhow!(e))
    }

    /// Clear all notifications
    pub async fn clear_all(&self) -> Result<()> {
        self.proxy.clear_all().await.map_err(|e| anyhow::anyhow!(e))
    }
}
