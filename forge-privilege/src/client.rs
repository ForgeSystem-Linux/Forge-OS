use anyhow::Result;
use zbus::proxy::Builder;

/// D-Bus proxy for the Forge privilege escalation service
#[zbus::proxy(
    interface = "org.forge.Privilege",
    default_service = "org.forge.Privilege",
    default_path = "/org/forge/Privilege"
)]
trait ForgePrivilege {
    /// Execute a command with root privileges via pkexec
    async fn execute(
        &self,
        command: Vec<String>,
        env_vars: std::collections::HashMap<String, String>,
    ) -> zbus::Result<(i32, String, String)>;

    /// Check if a command is available
    async fn check_command(&self, command: String) -> zbus::Result<bool>;

    /// Get the current user
    async fn get_user(&self) -> zbus::Result<String>;

    /// Check if running as root
    async fn is_root(&self) -> zbus::Result<bool>;
}

/// Client for the Forge privilege escalation service
pub struct PrivilegeClient {
    proxy: ForgePrivilegeProxy<'static>,
}

impl PrivilegeClient {
    /// Create a new privilege client
    pub async fn new() -> Result<Self> {
        let connection = zbus::Connection::session().await?;
        let proxy = Builder::new(&connection).build().await?;
        Ok(Self { proxy })
    }

    /// Execute a command with root privileges
    pub async fn execute(
        &self,
        command: Vec<String>,
        env_vars: std::collections::HashMap<String, String>,
    ) -> Result<(i32, String, String)> {
        self.proxy.execute(command, env_vars).await.map_err(|e| anyhow::anyhow!(e))
    }

    /// Execute a simple command (no environment variables)
    pub async fn execute_simple(&self, command: Vec<String>) -> Result<(i32, String, String)> {
        self.execute(command, std::collections::HashMap::new()).await
    }

    /// Check if a command is available
    pub async fn check_command(&self, command: &str) -> Result<bool> {
        self.proxy.check_command(command.to_string()).await.map_err(|e| anyhow::anyhow!(e))
    }

    /// Get the current user
    pub async fn get_user(&self) -> Result<String> {
        self.proxy.get_user().await.map_err(|e| anyhow::anyhow!(e))
    }

    /// Check if running as root
    pub async fn is_root(&self) -> Result<bool> {
        self.proxy.is_root().await.map_err(|e| anyhow::anyhow!(e))
    }
}
