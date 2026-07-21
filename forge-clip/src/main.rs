use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use tokio::sync::RwLock;
use zbus::connection::Builder;
use zbus::interface;
use std::sync::Arc;

/// Clipboard entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClipboardEntry {
    pub content: String,
    pub mime_type: String,
    pub timestamp: u64,
    pub source_app: String,
}

/// Clipboard state
struct ClipboardState {
    history: RwLock<VecDeque<ClipboardEntry>>,
    max_history: usize,
    current: RwLock<Option<ClipboardEntry>>,
}

impl ClipboardState {
    fn new(max_history: usize) -> Self {
        Self {
            history: RwLock::new(VecDeque::with_capacity(max_history)),
            max_history,
            current: RwLock::new(None),
        }
    }

    async fn push(&self, entry: ClipboardEntry) {
        let mut history = self.history.write().await;
        let mut current = self.current.write().await;

        *current = Some(entry.clone());

        if history.len() >= self.max_history {
            history.pop_front();
        }
        history.push_back(entry);
    }
}

struct ClipboardManager {
    state: Arc<ClipboardState>,
}

#[interface(name = "org.forge.Clipboard")]
impl ClipboardManager {
    /// Copy content to clipboard
    async fn copy(&self, content: String, mime_type: String, source_app: String) -> bool {
        let entry = ClipboardEntry {
            content,
            mime_type,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            source_app,
        };

        self.state.push(entry).await;
        tracing::info!("Copied to clipboard");
        true
    }

    /// Paste content from clipboard
    async fn paste(&self) -> (String, String) {
        let current = self.state.current.read().await;
        match &*current {
            Some(entry) => (entry.content.clone(), entry.mime_type.clone()),
            None => (String::new(), String::new()),
        }
    }

    /// Get clipboard history
    async fn get_history(&self, count: i32) -> String {
        let history = self.state.history.read().await;
        let entries: Vec<&ClipboardEntry> = history.iter().rev().take(count as usize).collect();
        serde_json::to_string(&entries).unwrap_or_else(|_| "[]".to_string())
    }

    /// Clear clipboard history
    async fn clear(&self) {
        let mut history = self.state.history.write().await;
        let mut current = self.state.current.write().await;
        history.clear();
        *current = None;
        tracing::info!("Clipboard cleared");
    }

    /// Get current clipboard content
    async fn get_current(&self) -> String {
        let current = self.state.current.read().await;
        match &*current {
            Some(entry) => entry.content.clone(),
            None => String::new(),
        }
    }

    /// Get history count
    async fn get_count(&self) -> i32 {
        let history = self.state.history.read().await;
        history.len() as i32
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

    tracing::info!("Starting Forge Clipboard Manager");

    let state = Arc::new(ClipboardState::new(100));

    let clipboard = ClipboardManager {
        state: state.clone(),
    };

    let _conn = Builder::session()?
        .name("org.forge.Clipboard")?
        .serve_at("/org/forge/Clipboard", clipboard)?
        .build()
        .await?;

    tracing::info!("Clipboard manager running");

    std::future::pending::<()>().await;

    Ok(())
}
