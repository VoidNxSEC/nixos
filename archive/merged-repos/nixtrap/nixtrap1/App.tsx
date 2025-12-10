import { useState, useEffect } from 'react';
import useSWR from 'swr';
import { 
  Server, 
  Cpu, 
  HardDrive, 
  Network, 
  Activity,
  AlertCircle,
  CheckCircle,
  Clock,
  TrendingUp,
  Database
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

// Types
interface SystemMetrics {
  timestamp: string;
  system: {
    hostname: string;
    uptime_seconds: number;
    load_average: {
      '1min': number;
      '5min': number;
      '15min': number;
    };
  };
  cpu: {
    count: number;
    usage_percent: number;
  };
  memory: {
    total_gb: number;
    used_gb: number;
    available_gb: number;
    used_percent: number;
  };
  disk: {
    root: {
      total: string;
      used: string;
      available: string;
      used_percent: string;
    };
    nix_store: {
      size: string;
      path_count: number;
    };
  };
  network: {
    connections: {
      established: number;
      time_wait: number;
      listen: number;
    };
  };
  services: {
    nix_serve: { active: string; memory_mb: number };
    nginx: { active: string; memory_mb: number };
    prometheus: { active: string };
  };
}

interface HealthStatus {
  status: 'healthy' | 'warning' | 'unhealthy';
  timestamp: string;
  checks: {
    disk_space: boolean;
    nix_serve: boolean;
    nginx: boolean;
  };
}

// Fetcher para SWR
const fetcher = (url: string) => fetch(url).then(res => res.json());

// Componentes
const MetricCard = ({ 
  icon: Icon, 
  title, 
  value, 
  subtitle, 
  status 
}: { 
  icon: any; 
  title: string; 
  value: string; 
  subtitle?: string;
  status?: 'good' | 'warning' | 'error';
}) => {
  const statusColors = {
    good: 'bg-green-500',
    warning: 'bg-yellow-500',
    error: 'bg-red-500'
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200 hover:shadow-lg transition-shadow">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className={`p-2 rounded-lg ${status ? statusColors[status] : 'bg-blue-500'} bg-opacity-10`}>
            <Icon className={`w-6 h-6 ${status ? `text-${status === 'good' ? 'green' : status === 'warning' ? 'yellow' : 'red'}-600` : 'text-blue-600'}`} />
          </div>
          <h3 className="text-sm font-medium text-gray-600">{title}</h3>
        </div>
        {status && (
          <div className={`w-2 h-2 rounded-full ${statusColors[status]}`} />
        )}
      </div>
      <div className="space-y-1">
        <p className="text-2xl font-bold text-gray-900">{value}</p>
        {subtitle && <p className="text-sm text-gray-500">{subtitle}</p>}
      </div>
    </div>
  );
};

const ServiceStatus = ({ 
  name, 
  active, 
  memory 
}: { 
  name: string; 
  active: string; 
  memory?: number;
}) => {
  const isActive = active === 'active';
  
  return (
    <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
      <div className="flex items-center space-x-3">
        {isActive ? (
          <CheckCircle className="w-5 h-5 text-green-500" />
        ) : (
          <AlertCircle className="w-5 h-5 text-red-500" />
        )}
        <span className="font-medium text-gray-900">{name}</span>
      </div>
      <div className="flex items-center space-x-4">
        <span className={`text-sm ${isActive ? 'text-green-600' : 'text-red-600'}`}>
          {isActive ? 'Ativo' : 'Inativo'}
        </span>
        {memory !== undefined && memory > 0 && (
          <span className="text-sm text-gray-500">{memory} MB</span>
        )}
      </div>
    </div>
  );
};

function App() {
  const [metricsHistory, setMetricsHistory] = useState<Array<{time: string, cpu: number, memory: number}>>([]);
  
  // Polling de métricas a cada 5 segundos
  const { data: metrics, error: metricsError } = useSWR<SystemMetrics>(
    '/api/metrics',
    fetcher,
    { refreshInterval: 5000 }
  );

  const { data: health } = useSWR<HealthStatus>(
    '/api/health',
    fetcher,
    { refreshInterval: 10000 }
  );

  // Atualizar histórico para o gráfico
  useEffect(() => {
    if (metrics) {
      const now = new Date().toLocaleTimeString();
      setMetricsHistory(prev => {
        const newHistory = [...prev, {
          time: now,
          cpu: metrics.cpu.usage_percent,
          memory: metrics.memory.used_percent
        }];
        // Manter apenas os últimos 20 pontos
        return newHistory.slice(-20);
      });
    }
  }, [metrics]);

  // Formatar uptime
  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  if (metricsError) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-lg max-w-md">
          <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-center mb-2">Erro ao conectar</h2>
          <p className="text-gray-600 text-center">
            Não foi possível conectar ao servidor de métricas. 
            Verifique se o API server está rodando.
          </p>
        </div>
      </div>
    );
  }

  if (!metrics) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="flex items-center space-x-3">
          <Activity className="w-8 h-8 text-blue-500 animate-pulse" />
          <span className="text-xl text-gray-600">Carregando métricas...</span>
        </div>
      </div>
    );
  }

  const diskUsagePercent = parseInt(metrics.disk.root.used_percent);
  const memoryUsagePercent = metrics.memory.used_percent;

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Server className="w-8 h-8 text-blue-600" />
              <div>
                <h1 className="text-2xl font-bold text-gray-900">NixOS Cache Server</h1>
                <p className="text-sm text-gray-500">{metrics.system.hostname}</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <Clock className="w-5 h-5 text-gray-400" />
                <span className="text-sm text-gray-600">
                  Uptime: {formatUptime(metrics.system.uptime_seconds)}
                </span>
              </div>
              {health && (
                <div className={`flex items-center space-x-2 px-3 py-1 rounded-full ${
                  health.status === 'healthy' ? 'bg-green-100 text-green-700' :
                  health.status === 'warning' ? 'bg-yellow-100 text-yellow-700' :
                  'bg-red-100 text-red-700'
                }`}>
                  {health.status === 'healthy' ? (
                    <CheckCircle className="w-4 h-4" />
                  ) : (
                    <AlertCircle className="w-4 h-4" />
                  )}
                  <span className="text-sm font-medium capitalize">{health.status}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* System Metrics Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <MetricCard
            icon={Cpu}
            title="CPU"
            value={`${metrics.cpu.usage_percent.toFixed(1)}%`}
            subtitle={`${metrics.cpu.count} cores | Load: ${metrics.system.load_average['1min']}`}
            status={metrics.cpu.usage_percent > 80 ? 'warning' : 'good'}
          />
          
          <MetricCard
            icon={Activity}
            title="Memória"
            value={`${memoryUsagePercent.toFixed(1)}%`}
            subtitle={`${metrics.memory.used_gb}GB / ${metrics.memory.total_gb}GB usado`}
            status={memoryUsagePercent > 85 ? 'warning' : 'good'}
          />
          
          <MetricCard
            icon={HardDrive}
            title="Disco"
            value={metrics.disk.root.used_percent}
            subtitle={`${metrics.disk.root.used} / ${metrics.disk.root.total} usado`}
            status={diskUsagePercent > 85 ? 'warning' : diskUsagePercent > 70 ? 'warning' : 'good'}
          />
          
          <MetricCard
            icon={Database}
            title="Nix Store"
            value={metrics.disk.nix_store.size}
            subtitle={`${metrics.disk.nix_store.path_count.toLocaleString()} paths`}
            status="good"
          />
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* CPU History */}
          <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <TrendingUp className="w-5 h-5 mr-2 text-blue-600" />
              Histórico de CPU
            </h3>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={metricsHistory}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis domain={[0, 100]} />
                <Tooltip />
                <Line 
                  type="monotone" 
                  dataKey="cpu" 
                  stroke="#3b82f6" 
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Memory History */}
          <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <TrendingUp className="w-5 h-5 mr-2 text-green-600" />
              Histórico de Memória
            </h3>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={metricsHistory}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis domain={[0, 100]} />
                <Tooltip />
                <Line 
                  type="monotone" 
                  dataKey="memory" 
                  stroke="#10b981" 
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Services & Network */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Services Status */}
          <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <Server className="w-5 h-5 mr-2 text-blue-600" />
              Status dos Serviços
            </h3>
            <div className="space-y-3">
              <ServiceStatus 
                name="nix-serve" 
                active={metrics.services.nix_serve.active}
                memory={metrics.services.nix_serve.memory_mb}
              />
              <ServiceStatus 
                name="nginx" 
                active={metrics.services.nginx.active}
                memory={metrics.services.nginx.memory_mb}
              />
              <ServiceStatus 
                name="prometheus" 
                active={metrics.services.prometheus.active}
              />
            </div>
          </div>

          {/* Network */}
          <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <Network className="w-5 h-5 mr-2 text-purple-600" />
              Conexões de Rede
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Estabelecidas</span>
                <span className="text-2xl font-bold text-green-600">
                  {metrics.network.connections.established}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Aguardando</span>
                <span className="text-2xl font-bold text-yellow-600">
                  {metrics.network.connections.time_wait}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Escutando</span>
                <span className="text-2xl font-bold text-blue-600">
                  {metrics.network.connections.listen}
                </span>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between text-sm text-gray-500">
            <span>Última atualização: {new Date(metrics.timestamp).toLocaleString('pt-BR')}</span>
            <span>Auto-refresh: 5s</span>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
