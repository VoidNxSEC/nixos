# SSH Advanced Tools - Implementation Guide

## 📋 Document Purpose

This guide provides complete implementation details, security practices, and usage examples for SSH advanced tools in the SecureLLM Bridge MCP server.

---

## 🏗️ Implementation Roadmap

### Phase 1: Enhanced Connection Manager (Week 1)

#### 1.1 Connection Pooling
**File**: `src/tools/ssh/connection-manager.ts`

**Key Features**:
- Connection reuse to minimize overhead
- Health monitoring with automatic pruning
- Resource limits (max connections, memory)
- Connection lifecycle management

**Implementation Steps**:
1. Extend existing `SSHConnectionManager` class
2. Add connection pool with Map<string, Connection>
3. Implement getOrCreateConnection() for reuse
4. Add pruneIdleConnections() with configurable timeout
5. Implement health checking with ping/pong

**Code Structure**:
```typescript
class SSHConnectionManager {
  private pool: Map<string, Connection> = new Map();
  private config: ConnectionPoolConfig;
  private healthCheckInterval?: NodeJS.Timeout;
  
  constructor(config?: ConnectionPoolConfig) {
    this.config = {
      max_connections: config?.max_connections || 10,
      max_idle_time_ms: config?.max_idle_time_ms || 300000, // 5 min
      health_check_interval_ms: config?.health_check_interval_ms || 60000
    };
    this.startHealthMonitoring();
  }
  
  async getOrCreateConnection(config: SSHConfig): Promise<Connection> {
    const key = this.generateConnectionKey(config);
    let conn = this.pool.get(key);
    
    if (conn && conn.connected) {
      conn.last_used = new Date();
      return conn;
    }
    
    // Create new connection
    conn = await this.connect(config);
    this.pool.set(key, conn);
    return conn;
  }
  
  async pruneIdleConnections(maxIdleTime?: number): Promise<number> {
    const threshold = maxIdleTime || this.config.max_idle_time_ms;
    const now = Date.now();
    let pruned = 0;
    
    for (const [key, conn] of this.pool.entries()) {
      const idleTime = now - conn.last_used.getTime();
      if (idleTime > threshold) {
        conn.client.end();
        this.pool.delete(key);
        pruned++;
      }
    }
    
    return pruned;
  }
  
  private async healthCheck(conn: Connection): Promise<HealthStatus> {
    try {
      // Send keepalive packet
      const start = Date.now();
      await this.ping(conn.client);
      const latency = Date.now() - start;
      
      return {
        connection_id: conn.id,
        status: latency < 1000 ? 'healthy' : 'degraded',
        latency_ms: latency,
        uptime_seconds: (Date.now() - conn.created_at.getTime()) / 1000,
        last_check: new Date(),
        issues: latency > 1000 ? ['High latency'] : [],
        metrics: {
          success_rate: 1 - (conn.error_count / Math.max(conn.commands_executed, 1)),
          avg_latency_ms: latency,
          error_count: conn.error_count
        }
      };
    } catch (error) {
      return {
        connection_id: conn.id,
        status: 'failed',
        latency_ms: 0,
        uptime_seconds: 0,
        last_check: new Date(),
        issues: [error.message],
        metrics: {
          success_rate: 0,
          avg_latency_ms: 0,
          error_count: conn.error_count
        }
      };
    }
  }
  
  private generateConnectionKey(config: SSHConfig): string {
    return `${config.username}@${config.host}:${config.port || 22}`;
  }
}
```

#### 1.2 MFA Support
**Implementation**:
```typescript
async connectWithMFA(config: SSHConfig, mfaCode: string): Promise<Connection> {
  // Validate MFA code format
  if (!/^\d{6}$/.test(mfaCode)) {
    throw new Error('Invalid MFA code format');
  }
  
  // Connect with keyboard-interactive authentication
  const client = new Client();
  
  return new Promise((resolve, reject) => {
    client.on('keyboard-interactive', (name, instructions, lang, prompts, finish) => {
      // Respond to MFA prompt
      finish([mfaCode]);
    });
    
    client.on('ready', () => {
      const conn: Connection = {
        id: this.generateId(),
        config,
        client,
        connected: true,
        created_at: new Date(),
        last_used: new Date(),
        bytes_sent: 0,
        bytes_received: 0,
        commands_executed: 0,
        health_status: 'healthy',
        error_count: 0
      };
      resolve(conn);
    });
    
    client.on('error', reject);
    
    client.connect({
      host: config.host,
      port: config.port || 22,
      username: config.username,
      tryKeyboard: true,
      // ... other options
    });
  });
}
```

---

### Phase 2: Tunnel Manager (Week 2)

#### 2.1 Local Tunnel Implementation
**File**: `src/tools/ssh/tunnel-manager.ts`

**Features**:
- Local port forwarding: `-L localPort:remoteHost:remotePort`
- Automatic reconnection on failure
- Traffic monitoring
- Health checks

**Implementation**:
```typescript
class SSHTunnelManager {
  private tunnels: Map<string, Tunnel> = new Map();
  private connectionManager: SSHConnectionManager;
  
  constructor(connectionManager: SSHConnectionManager) {
    this.connectionManager = connectionManager;
  }
  
  async createLocalTunnel(config: LocalTunnelConfig): Promise<TunnelResult> {
    const conn = this.connectionManager.getConnection(config.connection_id);
    if (!conn) {
      throw new Error('Connection not found');
    }
    
    const tunnelId = this.generateTunnelId();
    
    return new Promise((resolve, reject) => {
      conn.client.forwardOut(
        config.bind_address || 'localhost',
        config.local_port,
        config.remote_host,
        config.remote_port,
        (err, stream) => {
          if (err) {
            reject(err);
            return;
          }
          
          // Create tunnel instance
          const tunnel: Tunnel = {
            id: tunnelId,
            config,
            connection_id: config.connection_id,
            status: 'active',
            created_at: new Date(),
            local_endpoint: `${config.bind_address || 'localhost'}:${config.local_port}`,
            remote_endpoint: `${config.remote_host}:${config.remote_port}`,
            bytes_transferred: 0,
            connections_count: 0,
            errors_count: 0,
            reconnect_attempts: 0
          };
          
          // Monitor traffic
          stream.on('data', (data: Buffer) => {
            tunnel.bytes_transferred += data.length;
          });
          
          stream.on('close', () => {
            if (config.keep_alive) {
              this.reconnectTunnel(tunnelId);
            } else {
              tunnel.status = 'closed';
            }
          });
          
          stream.on('error', (err: Error) => {
            tunnel.errors_count++;
            tunnel.last_error = err.message;
            
            if (config.auto_restart) {
              this.reconnectTunnel(tunnelId);
            }
          });
          
          this.tunnels.set(tunnelId, tunnel);
          
          resolve({
            success: true,
            data: {
              tunnel_id: tunnelId,
              type: 'local',
              local_endpoint: tunnel.local_endpoint,
              remote_endpoint: tunnel.remote_endpoint,
              status: 'active'
            },
            timestamp: new Date().toISOString()
          });
        }
      );
    });
  }
  
  async createRemoteTunnel(config: RemoteTunnelConfig): Promise<TunnelResult> {
    const conn = this.connectionManager.getConnection(config.connection_id);
    if (!conn) {
      throw new Error('Connection not found');
    }
    
    const tunnelId = this.generateTunnelId();
    
    return new Promise((resolve, reject) => {
      conn.client.forwardIn(
        config.bind_address || 'localhost',
        config.remote_port,
        (err) => {
          if (err) {
            reject(err);
            return;
          }
          
          conn.client.on('tcp connection', (info, accept, reject) => {
            const stream = accept();
            
            // Forward to local destination
            const localSocket = net.connect(
              config.local_port,
              config.local_host
            );
            
            stream.pipe(localSocket).pipe(stream);
            
            // Track metrics
            tunnel.connections_count++;
          });
          
          const tunnel: Tunnel = {
            id: tunnelId,
            config,
            connection_id: config.connection_id,
            status: 'active',
            created_at: new Date(),
            local_endpoint: `${config.local_host}:${config.local_port}`,
            remote_endpoint: `${config.bind_address || 'localhost'}:${config.remote_port}`,
            bytes_transferred: 0,
            connections_count: 0,
            errors_count: 0,
            reconnect_attempts: 0
          };
          
          this.tunnels.set(tunnelId, tunnel);
          
          resolve({
            success: true,
            data: {
              tunnel_id: tunnelId,
              type: 'remote',
              local_endpoint: tunnel.local_endpoint,
              remote_endpoint: tunnel.remote_endpoint,
              status: 'active'
            },
            timestamp: new Date().toISOString()
          });
        }
      );
    });
  }
  
  async createDynamicTunnel(config: DynamicTunnelConfig): Promise<TunnelResult> {
    const conn = this.connectionManager.getConnection(config.connection_id);
    if (!conn) {
      throw new Error('Connection not found');
    }
    
    const tunnelId = this.generateTunnelId();
    
    // Create SOCKS server
    const socksServer = socks.createServer((info, accept, deny) => {
      conn.client.forwardOut(
        info.srcAddr,
        info.srcPort,
        info.dstAddr,
        info.dstPort,
        (err, stream) => {
          if (err) {
            deny();
            return;
          }
          
          const clientSocket = accept(true);
          if (clientSocket) {
            stream.pipe(clientSocket).pipe(stream);
          }
        }
      );
    });
    
    socksServer.listen(config.socks_port, config.bind_address || 'localhost');
    
    const tunnel: Tunnel = {
      id: tunnelId,
      config,
      connection_id: config.connection_id,
      status: 'active',
      created_at: new Date(),
      local_endpoint: `socks${config.socks_version || 5}://${config.bind_address || 'localhost'}:${config.socks_port}`,
      remote_endpoint: 'dynamic',
      bytes_transferred: 0,
      connections_count: 0,
      errors_count: 0,
      reconnect_attempts: 0
    };
    
    this.tunnels.set(tunnelId, tunnel);
    
    return {
      success: true,
      data: {
        tunnel_id: tunnelId,
        type: 'dynamic',
        local_endpoint: tunnel.local_endpoint,
        remote_endpoint: tunnel.remote_endpoint,
        status: 'active'
      },
      timestamp: new Date().toISOString()
    };
  }
  
  private async reconnectTunnel(tunnelId: string): Promise<void> {
    const tunnel = this.tunnels.get(tunnelId);
    if (!tunnel) return;
    
    tunnel.reconnect_attempts++;
    
    if (tunnel.config.max_reconnect_attempts && 
        tunnel.reconnect_attempts > tunnel.config.max_reconnect_attempts) {
      tunnel.status = 'failed';
      return;
    }
    
    // Exponential backoff
    const delay = Math.min(1000 * Math.pow(2, tunnel.reconnect_attempts - 1), 30000);
    await new Promise(resolve => setTimeout(resolve, delay));
    
    try {
      // Recreate tunnel based on type
      if (tunnel.config.type === 'local') {
        await this.createLocalTunnel(tunnel.config as LocalTunnelConfig);
      } else if (tunnel.config.type === 'remote') {
        await this.createRemoteTunnel(tunnel.config as RemoteTunnelConfig);
      } else {
        await this.createDynamicTunnel(tunnel.config as DynamicTunnelConfig);
      }
      
      tunnel.reconnect_attempts = 0; // Reset on success
    } catch (error) {
      tunnel.errors_count++;
      tunnel.last_error = error.message;
    }
  }
  
  private generateTunnelId(): string {
    return `tunnel-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

---

### Phase 3: Jump Host Manager (Week 2-3)

#### 3.1 Jump Chain Implementation
**File**: `src/tools/ssh/jump-host-manager.ts`

**Features**:
- Multi-hop SSH connections
- Optimal path selection
- Latency-aware routing
- Failover support

**Implementation**:
```typescript
class JumpHostManager {
  private chains: Map<string, JumpChain> = new Map();
  private connectionManager: SSHConnectionManager;
  private pathCache: Map<string, { path: JumpHostConfig[]; expires: Date }> = new Map();
  
  async connectThroughJumps(config: JumpChainConfig): Promise<JumpChainResult> {
    const chainId = this.generateChainId();
    
    // Check cache if enabled
    if (config.cache_successful_path) {
      const cached = this.getCachedPath(config.target.host);
      if (cached) {
        config.jumps = cached;
      }
    }
    
    let path: Array<{ host: string; latency_ms: number; connected_at: Date }> = [];
    let currentConnection: Connection | null = null;
    
    try {
      // Strategy: sequential or optimal
      if (config.strategy === 'sequential') {
        path = await this.connectSequential(config);
      } else if (config.strategy === 'optimal') {
        path = await this.connectOptimal(config);
      } else {
        path = await this.connectWithFailover(config);
      }
      
      // Connect to final target through jump chain
      const finalConn = await this.connectThroughPath(path, config.target);
      
      const chain: JumpChain = {
        id: chainId,
        config,
        status: 'connected',
        connection_id: finalConn.id,
        actual_path: path,
        total_latency_ms: path.reduce((sum, hop) => sum + hop.latency_ms, 0),
        hop_count: path.length,
        created_at: new Date(),
        reconnect_attempts: 0
      };
      
      this.chains.set(chainId, chain);
      
      // Cache successful path
      if (config.cache_successful_path) {
        this.cachePath(config.target.host, config.jumps, config.cache_duration_minutes || 60);
      }
      
      return {
        success: true,
        data: {
          chain_id: chainId,
          connection_id: finalConn.id,
          target: config.target.host,
          jumps: config.jumps.map(j => j.host),
          path_taken: path.map(p => p.host),
          total_latency_ms: chain.total_latency_ms,
          hop_count: chain.hop_count
        },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        success: false,
        error: `Jump chain failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }
  
  private async connectSequential(config: JumpChainConfig): Promise<Array<{ host: string; latency_ms: number; connected_at: Date }>> {
    const path = [];
    
    for (const jump of config.jumps) {
      const start = Date.now();
      const conn = await this.connectionManager.connect(jump);
      const latency = Date.now() - start;
      
      path.push({
        host: jump.host,
        latency_ms: latency,
        connected_at: new Date()
      });
      
      // Check latency threshold
      if (jump.max_latency_ms && latency > jump.max_latency_ms) {
        throw new Error(`Jump host ${jump.host} exceeds latency threshold: ${latency}ms > ${jump.max_latency_ms}ms`);
      }
    }
    
    return path;
  }
  
  private async connectOptimal(config: JumpChainConfig): Promise<Array<{ host: string; latency_ms: number; connected_at: Date }>> {
    // Probe all jumps in parallel if enabled
    if (config.parallel_probe) {
      const probes = await Promise.all(
        config.jumps.map(jump => this.probeJump(jump))
      );
      
      // Sort by priority and latency
      const sorted = probes
        .filter(p => p.success)
        .sort((a, b) => {
          const priorityDiff = (b.priority || 0) - (a.priority || 0);
          if (priorityDiff !== 0) return priorityDiff;
          return a.latency_ms - b.latency_ms;
        });
      
      // Use best path
      return sorted;
    }
    
    return this.connectSequential(config);
  }
  
  private async probeJump(jump: JumpHostConfig): Promise<{ host: string; latency_ms: number; connected_at: Date; priority: number; success: boolean }> {
    try {
      const start = Date.now();
      const conn = await this.connectionManager.connect(jump);
      const latency = Date.now() - start;
      
      // Disconnect probe
      conn.client.end();
      
      return {
        host: jump.host,
        latency_ms: latency,
        connected_at: new Date(),
        priority: jump.priority || 0,
        success: true
      };
    } catch (error) {
      return {
        host: jump.host,
        latency_ms: Infinity,
        connected_at: new Date(),
        priority: jump.priority || 0,
        success: false
      };
    }
  }
  
  private cachePath(targetHost: string, path: JumpHostConfig[], durationMinutes: number): void {
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + durationMinutes);
    
    this.pathCache.set(targetHost, { path, expires });
  }
  
  private getCachedPath(targetHost: string): JumpHostConfig[] | null {
    const cached = this.pathCache.get(targetHost);
    if (!cached) return null;
    
    if (cached.expires < new Date()) {
      this.pathCache.delete(targetHost);
      return null;
    }
    
    return cached.path;
  }
  
  private generateChainId(): string {
    return `chain-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

---

### Phase 4: Session Persistence (Week 3-4)

#### 4.1 Session Manager Implementation
**File**: `src/tools/ssh/session-manager.ts`

**Features**:
- Save/restore sessions
- Auto-recovery on disconnect
- State persistence to disk
- Resource recreation

**Implementation**:
```typescript
import Database from 'better-sqlite3';

class SessionManager {
  private db: Database.Database;
  private sessions: Map<string, SessionInfo> = new Map();
  private recoveryTimers: Map<string, NodeJS.Timeout> = new Map();
  
  constructor(dbPath: string) {
    this.db = new Database(dbPath);
    this.initDatabase();
    this.loadSessions();
  }
  
  private initDatabase(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        session_id TEXT PRIMARY KEY,
        connection_config TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_active TEXT NOT NULL,
        persist INTEGER DEFAULT 0,
        auto_recover INTEGER DEFAULT 0,
        recovery_count INTEGER DEFAULT 0,
        state_data TEXT
      );
      
      CREATE TABLE IF NOT EXISTS session_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        resource_type TEXT NOT NULL,
        resource_config TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(session_id)
      );
    `);
  }
  
  async persistSession(config: SessionConfig): Promise<SessionData> {
    const sessionId = this.generateSessionId();
    const conn = this.connectionManager.getConnection(config.connection_id);
    
    if (!conn) {
      throw new Error('Connection not found');
    }
    
    const sessionData: SessionData = {
      session_id: sessionId,
      connection_config: conn.config,
      created_at: new Date().toISOString(),
      last_active: new Date().toISOString(),
      connection_metadata: {
        bytes_sent: conn.bytes_sent,
        bytes_received: conn.bytes_received,
        commands_executed: conn.commands_executed
      },
      tunnels: config.save_tunnel_state ? await this.getTunnelConfigs(config.connection_id) : undefined,
      port_forwards: config.save_port_forwards ? await this.getPortForwardConfigs(config.connection_id) : undefined,
      jump_chain: config.save_jump_chain ? await this.getJumpChainConfig(config.connection_id) : undefined,
      recovery_count: 0,
      recovery_state: 'stable'
    };
    
    // Save to database
    if (config.persist) {
      this.db.prepare(`
        INSERT INTO sessions (session_id, connection_config, created_at, last_active, persist, auto_recover, state_data)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(
        sessionId,
        JSON.stringify(sessionData.connection_config),
        sessionData.created_at,
        sessionData.last_active,
        1,
        config.auto_recover ? 1 : 0,
        JSON.stringify(sessionData)
      );
      
      // Save resources
      if (sessionData.tunnels) {
        for (const tunnel of sessionData.tunnels) {
          this.saveResource(sessionId, 'tunnel', tunnel);
        }
      }
    }
    
    const sessionInfo: SessionInfo = {
      session_id: sessionId,
      connection_id: config.connection_id,
      status: 'active',
      created_at: new Date(),
      last_active: new Date(),
      persisted: config.persist,
      auto_recover: config.auto_recover,
      recovery_count: 0,
      has_tunnels: !!sessionData.tunnels && sessionData.tunnels.length > 0,
      has_port_forwards: !!sessionData.port_forwards && sessionData.port_forwards.length > 0,
      has_jump_chain: !!sessionData.jump_chain
    };
    
    this.sessions.set(sessionId, sessionInfo);
    
    // Setup auto-recovery if enabled
    if (config.auto_recover) {
      this.setupAutoRecovery(sessionId, config);
    }
    
    return sessionData;
  }
  
  async restoreSession(sessionId: string): Promise<SessionRecoveryResult> {
    const row = this.db.prepare(`
      SELECT * FROM sessions WHERE session_id = ?
    `).get(sessionId);
    
    if (!row) {
      return {
        success: false,
        error: 'Session not found',
        timestamp: new Date().toISOString()
      };
    }
    
    const sessionData: SessionData = JSON.parse(row.state_data);
    const start = Date.now();
    
    try {
      // Reconnect
      const conn = await this.connectionManager.connect(sessionData.connection_config);
      
      // Restore resources
      const recoveredResources = {
        tunnels: 0,
        port_forwards: 0,
        jump_chain: false
      };
      
      if (sessionData.tunnels) {
        for (const tunnelConfig of sessionData.tunnels) {
          try {
            await this.tunnelManager.createTunnel(tunnelConfig);
            recoveredResources.tunnels++;
          } catch (error) {
            console.error(`Failed to restore tunnel: ${error.message}`);
          }
        }
      }
      
      if (sessionData.port_forwards) {
        // Restore port forwards
        recoveredResources.port_forwards = sessionData.port_forwards.length;
      }
      
      if (sessionData.jump_chain) {
        // Restore jump chain
        recoveredResources.jump_chain = true;
      }
      
      // Update session
      this.db.prepare(`
        UPDATE sessions 
        SET last_active = ?, recovery_count = recovery_count + 1
        WHERE session_id = ?
      `).run(new Date().toISOString(), sessionId);
      
      return {
        success: true,
        data: {
          session_id: sessionId,
          connection_id: conn.id,
          recovery_time_ms: Date.now() - start,
          recovered_resources: recoveredResources,
          warnings: []
        },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        success: false,
        error: `Session recovery failed: ${error.message}`,
        timestamp: new Date().toISOString()
      };
    }
  }
  
  private setupAutoRecovery(sessionId: string, config: SessionConfig): void {
    const maxAttempts = config.max_recovery_attempts || 3;
    const backoffMs = config.recovery_backoff_ms || 5000;
    
    const attemptRecovery = async (attempt: number = 1) => {
      if (attempt > maxAttempts) {
        console.error(`Session ${sessionId}: Max recovery attempts reached`);
        return;
      }
      
      const sessionInfo = this.sessions.get(sessionId);
      if (!sessionInfo) return;
      
      // Check if connection is still alive
      const conn = this.connectionManager.getConnection(sessionInfo.connection_id!);
      if (conn && conn.connected) {
        // Connection is fine, reset timer
        this.scheduleNextCheck(sessionId, config);
        return;
      }
      
      // Connection lost, attempt recovery
      console.log(`Session ${sessionId}: Attempting recovery (attempt ${attempt}/${maxAttempts})`);
      
      try {
        const result = await this.restoreSession(sessionId);
        if (result.success) {
          console.log(`Session ${sessionId}: Recovery successful`);
          this.scheduleNextCheck(sessionId, config);
        } else {
          // Retry with backoff
          const delay = this.calculateBackoff(attempt, backoffMs, config.recovery_strategy);
          setTimeout(() => attemptRecovery(attempt + 1), delay);
        }
      } catch (error) {
        console.error(`Session ${sessionId}: Recovery failed: ${error.message}`);
        const delay = this.calculateBackoff(attempt, backoffMs, config.recovery_strategy);
        setTimeout(() => attemptRecovery(attempt + 1), delay);
      }
    };
    
    this.scheduleNextCheck(sessionId, config, attemptRecovery);
  }
  
  private scheduleNextCheck(sessionId: string, config: SessionConfig, callback?: () => void): void {
    // Clear existing timer
    const existing = this.recoveryTimers.get(sessionId);
    if (existing) {
      clearTimeout(existing);
    }
    
    // Schedule next check
    const timer = setTimeout(callback || (() => this.setupAutoRecovery(sessionId, config)), 30000);
    this.recoveryTimers.set(sessionId, timer);
  }
  
  private calculateBackoff(attempt: number, baseMs: number, strategy?: string): number {
    if (strategy === 'exponential') {
      return Math.min(baseMs * Math.pow(2, attempt - 1), 60000);
    } else if (strategy === 'linear') {
      return baseMs * attempt;
    }
    return baseMs;
  }
  
  private saveResource(sessionId: string, type: string, config: any): void {
    this.db.prepare(`
      INSERT INTO session_resources (session_id, resource_type, resource_config)
      VALUES (?, ?, ?)
    `).run(sessionId, type, JSON.stringify(config));
  }
  
  private generateSessionId(): string {
    return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

---

## 🔒 Security Best Practices

### 1. Host Whitelisting (MANDATORY)
```typescript
const ALLOWED_HOSTS = [
  'bastion.company.com',
  'prod-server.internal',
  '10.0.0.0/8' // CIDR notation support
];

function validateHost(host: string): boolean {
  // Check exact match
  if (ALLOWED_HOSTS.includes(host)) return true;
  
  // Check CIDR ranges
  for (const allowed of ALLOWED_HOSTS) {
    if (allowed.includes('/')) {
      if (isInCIDR(host, allowed)) return true;
    }
  }
  
  return false;
}
```

### 2. Command Whitelisting
```typescript
const ALLOWED_COMMANDS = [
  /^ls(\s|$)/,
  /^cat\s+/,
  /^systemctl\s+status/,
  /^journalctl/
];

function validateCommand(cmd: string): boolean {
  return ALLOWED_COMMANDS.some(pattern => pattern.test(cmd));
}
```

### 3. Authentication Security
- **Prefer SSH keys** over passwords
- **Use passphrases** on private keys
- **Enable MFA** for production environments
- **Rotate credentials** regularly
- **Use certificate-based auth** when available

### 4. Connection Security
- **Enable strict host key checking**
- **Use known_hosts file**
- **Enable compression** only if needed
- **Set connection timeouts**
- **Limit max connections per user**

### 5. Tunnel Security
- **Bind to localhost** by default
- **Validate port ranges**
- **Monitor traffic patterns**
- **Log all tunnel creation**
- **Auto-close idle tunnels**

### 6. Audit Logging
```typescript
function logSecurityEvent(event: {
  type: string;
  severity: 'info' | 'warning' | 'critical';
  user: string;
  action: string;
  details: any;
}): void {
  const logEntry = {
    timestamp: new Date().toISOString(),
    ...event
  };
  
  // Log to file
  fs.appendFileSync('/var/log/mcp-ssh-audit.log', JSON.stringify(logEntry) + '\n');
  
  // Alert on critical events
  if (event.severity === 'critical') {
    sendAlert(logEntry);
  }
}
```

---

## 📚 Usage Examples

### Example 1: Database Tunnel with Auto-Reconnect
```typescript
// Create connection
const connection = await mcp.callTool('ssh_connect', {
  host: 'bastion.company.com',
  username: 'devops',
  auth_method: 'key',
  key_path: '~/.ssh/production_key'
});

// Create tunnel to internal database
const tunnel = await mcp.callTool('ssh_tunnel', {
  type: 'local',
  connection_id: connection.data.connection_id,
  local_port: 5432,
  remote_host: 'postgres.internal.company.com',
  remote_port: 5432,
  keep_alive: true,
  auto_restart: true
});

// Now connect to database via localhost:5432
// psql -h localhost -p 5432 -U dbuser production_db
```

### Example 2: Multi-Hop Jump to Private Server
```typescript
const jumpConnection = await mcp.callTool('ssh_jump_host', {
  target: {
    host: '10.0.1.100',
    username: 'admin',
    auth_method: 'key',
    key_path: '~/.ssh/private_server_key'
  },
  jumps: [
    {
      host: 'bastion1.company.com',
      username: 'jumpuser',
      auth_method: 'key',
      key_path: '~/.ssh/bastion1_key',
      forward_agent: true
    },
    {
      host: 'bastion2.internal.company.com',
      username: 'jumpuser',
      auth_method: 'key',
      key_path: '~/.ssh/bastion2_key',
      forward_agent: true
    }
  ],
  strategy: 'optimal',
  cache_successful_path: true
});

// Execute commands on private server
const result = await mcp.callTool('ssh_execute', {
  connection_id: jumpConnection.data.connection_id,
  command: 'systemctl status nginx'
});
```

### Example 3: SOCKS Proxy for Browser Traffic
```typescript
// Create dynamic SOCKS proxy
const proxy = await mcp.callTool('ssh_tunnel', {
  type: 'dynamic',
  connection_id: connection.data.connection_id,
  socks_port: 1080,
  socks_version: 5,
  keep_alive: true
});

// Configure browser to use SOCKS5 proxy at localhost:1080
// All traffic will be tunneled through SSH connection
```

### Example 4: Persistent Session with Auto-Recovery
```typescript
// Create and persist session
const session = await mcp.callTool('ssh_session_manager', {
  action: 'save',
  connection_id: connection.data.connection_id,
  persist: true,
  auto_recover: true,
  max_recovery_attempts: 5
});

// Session will automatically reconnect if connection drops

// Later, restore session
const restored = await mcp.callTool('ssh_session_manager', {
  action: 'restore',
  session_id: session.data.session_id
});
```

### Example 5: Multiple Port Forwards
```typescript
const forwards = await mcp.callTool('ssh_port_forward', {
  connection_id: connection.data.connection_id,
  forwards: [
    {
      local_port: 5432,
      remote_host: 'postgres.internal',
      remote_port: 5432
    },
    {
      local_port: 6379,
      remote_host: 'redis.internal',
      remote_port: 6379
    },
    {
      local_port: 9200,
      remote_host: 'elasticsearch.internal',
      remote_port: 9200
    }
  ],
  auto_reconnect: true
});
```

---

## 🎯 Testing Strategy

### Unit Tests
```typescript
describe('SSHTunnelManager', () => {
  it('should create local tunnel', async () => {
    const tunnel = await tunnelManager.createLocalTunnel({
      type: 'local',
      connection_id: 'test-conn',
      local_port: 8080,
      remote_host: 'example.com',
      remote_port: 80
    });
    
    expect(tunnel.success).toBe(true);
    expect(tunnel.data.type).toBe('local');
  });
  
  it('should auto-reconnect on failure', async () => {
    // Test auto-reconnect logic
  });
});
```

### Integration Tests
```typescript
describe('Jump Chain', () => {
  it('should connect through multiple jumps', async () => {
    const chain = await jumpHostManager.connectThroughJumps({
      target: { host: 'target.internal', username: 'admin', auth_method: 'key' },
      jumps: [
        { host: 'bastion.com', username: 'jump', auth_method: 'key' }
      ],
      strategy: 'sequential'
    });
    
    expect(chain.success).toBe(true);
    expect(chain.data.hop_count).toBe(1);
  });
});
```

---

## 📊 Performance Considerations

### Connection Pooling
- Reuse connections when possible
- Set appropriate idle timeout
- Monitor pool size
- Implement backpressure

### Tunnel Optimization
- Use compression for slow links
- Monitor bandwidth usage
- Implement rate limiting
- Close unused tunnels

### Memory Management
- Limit max concurrent connections
- Clean up closed connections
- Monitor memory usage
- Implement connection limits

---

## 🚀 Deployment Checklist

- [ ] All security controls enabled
- [ ] Host whitelist configured
- [ ] Command whitelist configured
- [ ] MFA setup tested
- [ ] Audit logging enabled
- [ ] Connection limits set
- [ ] Monitoring configured
- [ ] Backup strategy in place
- [ ] Documentation updated
- [ ] Team training completed

---

**Document Status**: Complete Implementation Guide  
**Version**: 1.0  
**Last Updated**: 2025-11-26  
**Related Documents**:
- [SSH-ADVANCED-TOOLS-ARCHITECTURE.md](./SSH-ADVANCED-TOOLS-ARCHITECTURE.md)
- [SSH-TYPES-SPECIFICATION.md](./SSH-TYPES-SPECIFICATION.md)