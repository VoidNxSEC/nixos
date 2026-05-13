#!/usr/bin/env python3
"""
Advanced performance profiler for Dev Assistant Hub
Measures CPU, memory, network, and disk I/O metrics
"""

import psutil
import requests
import time
import json
import threading
import statistics
from datetime import datetime
from pathlib import Path

class PerformanceProfiler:
    def __init__(self, base_url="http://localhost:3000", duration=60):
        self.base_url = base_url
        self.duration = duration
        self.metrics = {
            'cpu_usage': [],
            'memory_usage': [],
            'network_io': [],
            'disk_io': [],
            'response_times': [],
            'error_count': 0,
            'request_count': 0
        }
        self.running = False
        self.start_time = None
        
    def find_app_process(self):
        """Find the Node.js process running the app"""
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if 'node' in proc.info['name'].lower():
                    cmdline = ' '.join(proc.info['cmdline'])
                    if 'next dev' in cmdline or 'dev-assistant-hub' in cmdline:
                        return psutil.Process(proc.info['pid'])
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        return None
    
    def collect_system_metrics(self):
        """Collect system-wide metrics"""
        while self.running:
            try:
                # CPU usage
                cpu_percent = psutil.cpu_percent(interval=1)
                self.metrics['cpu_usage'].append({
                    'timestamp': time.time(),
                    'value': cpu_percent
                })
                
                # Memory usage
                memory = psutil.virtual_memory()
                self.metrics['memory_usage'].append({
                    'timestamp': time.time(),
                    'total': memory.total,
                    'available': memory.available,
                    'percent': memory.percent,
                    'used': memory.used
                })
                
                # Network I/O
                net_io = psutil.net_io_counters()
                self.metrics['network_io'].append({
                    'timestamp': time.time(),
                    'bytes_sent': net_io.bytes_sent,
                    'bytes_recv': net_io.bytes_recv,
                    'packets_sent': net_io.packets_sent,
                    'packets_recv': net_io.packets_recv
                })
                
                # Disk I/O
                disk_io = psutil.disk_io_counters()
                if disk_io:
                    self.metrics['disk_io'].append({
                        'timestamp': time.time(),
                        'read_bytes': disk_io.read_bytes,
                        'write_bytes': disk_io.write_bytes,
                        'read_count': disk_io.read_count,
                        'write_count': disk_io.write_count
                    })
                
            except Exception as e:
                print(f"Error collecting metrics: {e}")
            
            time.sleep(1)
    
    def collect_app_metrics(self):
        """Collect application-specific metrics"""
        app_process = self.find_app_process()
        
        while self.running:
            try:
                if app_process and app_process.is_running():
                    # Process-specific metrics
                    cpu_percent = app_process.cpu_percent()
                    memory_info = app_process.memory_info()
                    
                    self.metrics.setdefault('app_cpu', []).append({
                        'timestamp': time.time(),
                        'value': cpu_percent
                    })
                    
                    self.metrics.setdefault('app_memory', []).append({
                        'timestamp': time.time(),
                        'rss': memory_info.rss,
                        'vms': memory_info.vms
                    })
                
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                app_process = self.find_app_process()
            except Exception as e:
                print(f"Error collecting app metrics: {e}")
            
            time.sleep(1)
    
    def stress_test_endpoints(self):
        """Stress test various endpoints"""
        endpoints = [
            '/api/health',
            '/api/code-analysis',
            '/api/llm-providers',
            '/api/agents'
        ]
        
        while self.running:
            for endpoint in endpoints:
                try:
                    start_time = time.time()
                    response = requests.get(
                        f"{self.base_url}{endpoint}",
                        timeout=10
                    )
                    end_time = time.time()
                    
                    response_time = (end_time - start_time) * 1000  # Convert to ms
                    
                    self.metrics['response_times'].append({
                        'endpoint': endpoint,
                        'timestamp': start_time,
                        'response_time_ms': response_time,
                        'status_code': response.status_code
                    })
                    
                    self.metrics['request_count'] += 1
                    
                    if response.status_code >= 400:
                        self.metrics['error_count'] += 1
                        
                except requests.RequestException as e:
                    self.metrics['error_count'] += 1
                    print(f"Request error: {e}")
                
                time.sleep(0.5)  # Small delay between requests
    
    def run_profile(self):
        """Run the complete performance profile"""
        print(f"🔍 Starting performance profiling for {self.duration} seconds...")
        print(f"📊 Target: {self.base_url}")
        
        self.running = True
        self.start_time = time.time()
        
        # Start metric collection threads
        threads = [
            threading.Thread(target=self.collect_system_metrics),
            threading.Thread(target=self.collect_app_metrics),
            threading.Thread(target=self.stress_test_endpoints)
        ]
        
        for thread in threads:
            thread.daemon = True
            thread.start()
        
        # Run for specified duration
        time.sleep(self.duration)
        
        self.running = False
        
        # Wait for threads to finish
        for thread in threads:
            thread.join(timeout=5)
        
        return self.generate_report()
    
    def generate_report(self):
        """Generate comprehensive performance report"""
        end_time = time.time()
        total_duration = end_time - self.start_time
        
        report = {
            'metadata': {
                'start_time': datetime.fromtimestamp(self.start_time).isoformat(),
                'end_time': datetime.fromtimestamp(end_time).isoformat(),
                'duration_seconds': total_duration,
                'base_url': self.base_url
            },
            'summary': {
                'total_requests': self.metrics['request_count'],
                'total_errors': self.metrics['error_count'],
                'error_rate_percent': (self.metrics['error_count'] / max(self.metrics['request_count'], 1)) * 100,
                'requests_per_second': self.metrics['request_count'] / total_duration
            }
        }
        
        # CPU statistics
        if self.metrics['cpu_usage']:
            cpu_values = [m['value'] for m in self.metrics['cpu_usage']]
            report['cpu'] = {
                'avg_percent': statistics.mean(cpu_values),
                'max_percent': max(cpu_values),
                'min_percent': min(cpu_values),
                'median_percent': statistics.median(cpu_values)
            }
        
        # Memory statistics
        if self.metrics['memory_usage']:
            memory_values = [m['percent'] for m in self.metrics['memory_usage']]
            report['memory'] = {
                'avg_percent': statistics.mean(memory_values),
                'max_percent': max(memory_values),
                'min_percent': min(memory_values),
                'median_percent': statistics.median(memory_values)
            }
        
        # Response time statistics
        if self.metrics['response_times']:
            response_times = [r['response_time_ms'] for r in self.metrics['response_times']]
            report['response_times'] = {
                'avg_ms': statistics.mean(response_times),
                'max_ms': max(response_times),
                'min_ms': min(response_times),
                'median_ms': statistics.median(response_times),
                'p95_ms': self.percentile(response_times, 95),
                'p99_ms': self.percentile(response_times, 99)
            }
            
            # Per-endpoint breakdown
            endpoint_stats = {}
            for response in self.metrics['response_times']:
                endpoint = response['endpoint']
                if endpoint not in endpoint_stats:
                    endpoint_stats[endpoint] = []
                endpoint_stats[endpoint].append(response['response_time_ms'])
            
            report['endpoints'] = {}
            for endpoint, times in endpoint_stats.items():
                report['endpoints'][endpoint] = {
                    'count': len(times),
                    'avg_ms': statistics.mean(times),
                    'max_ms': max(times),
                    'min_ms': min(times)
                }
        
        # App-specific metrics
        if 'app_cpu' in self.metrics and self.metrics['app_cpu']:
            app_cpu_values = [m['value'] for m in self.metrics['app_cpu']]
            report['app_performance'] = {
                'cpu_avg_percent': statistics.mean(app_cpu_values),
                'cpu_max_percent': max(app_cpu_values)
            }
            
            if 'app_memory' in self.metrics and self.metrics['app_memory']:
                app_memory_values = [m['rss'] for m in self.metrics['app_memory']]
                report['app_performance']['memory_avg_mb'] = statistics.mean(app_memory_values) / (1024 * 1024)
                report['app_performance']['memory_max_mb'] = max(app_memory_values) / (1024 * 1024)
        
        return report
    
    def percentile(self, data, percentile):
        """Calculate percentile of a dataset"""
        sorted_data = sorted(data)
        index = int((percentile / 100) * len(sorted_data))
        return sorted_data[min(index, len(sorted_data) - 1)]

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Performance profiler for Dev Assistant Hub')
    parser.add_argument('--url', default='http://localhost:3000', help='Base URL to test')
    parser.add_argument('--duration', type=int, default=60, help='Test duration in seconds')
    parser.add_argument('--output', help='Output file for results')
    
    args = parser.parse_args()
    
    profiler = PerformanceProfiler(args.url, args.duration)
    report = profiler.run_profile()
    
    print("\n📊 Performance Profile Results:")
    print("=" * 40)
    print(json.dumps(report, indent=2))
    
    # Save results
    if args.output:
        output_file = args.output
    else:
        results_dir = Path(__file__).parent / 'results'
        results_dir.mkdir(exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        output_file = results_dir / f'performance-profile-{timestamp}.json'
    
    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_file}")

if __name__ == '__main__':
    main()
