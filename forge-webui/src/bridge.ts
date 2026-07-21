/**
 * Forge DE - TypeScript Bridge
 * 
 * This module provides the bridge between TypeScript web components
 * and the Rust backend via QWebChannel.
 */

// QWebChannel transport interface
declare global {
  interface Window {
    qt: {
      webChannelTransport: {
        send: (message: string) => void;
        onmessage: (message: string) => void;
      };
    };
  }
}

export interface ForgeMessage {
  type: string;
  payload: any;
}

export class ForgeBridge {
  private transport: any;

  constructor() {
    this.transport = window.qt?.webChannelTransport;
  }

  send(message: ForgeMessage): void {
    if (this.transport) {
      this.transport.send(JSON.stringify(message));
    }
  }

  onMessage(callback: (message: ForgeMessage) => void): void {
    if (this.transport) {
      this.transport.onmessage = (raw: string) => {
        callback(JSON.parse(raw));
      };
    }
  }
}

export const bridge = new ForgeBridge();
