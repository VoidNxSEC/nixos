package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/miekg/dns"
)

const (
	defaultCacheSize     = 10000
	defaultCacheTTL      = 300 // 5 minutes
	defaultListenAddr    = "127.0.0.1:53"
	defaultUpstream      = "1.1.1.1:53"
	defaultTimeout       = 5 * time.Second
)

type Config struct {
	ListenAddr  string   `json:"listen_addr"`
	Upstreams   []string `json:"upstreams"`
	CacheSize   int      `json:"cache_size"`
	CacheTTL    int      `json:"cache_ttl"`
	Timeout     int      `json:"timeout"`
	EnableStats bool     `json:"enable_stats"`
}

type CacheEntry struct {
	Response  *dns.Msg
	ExpiresAt time.Time
}

type DNSCache struct {
	mu      sync.RWMutex
	entries map[string]*CacheEntry
	maxSize int
}

type Stats struct {
	mu           sync.RWMutex
	queries      uint64
	cacheHits    uint64
	cacheMisses  uint64
	errors       uint64
	avgQueryTime time.Duration
	queryTimes   []time.Duration
}

type DNSProxy struct {
	config    *Config
	cache     *DNSCache
	stats     *Stats
	upstreams []*dns.Client
}

func NewDNSCache(maxSize int) *DNSCache {
	return &DNSCache{
		entries: make(map[string]*CacheEntry),
		maxSize: maxSize,
	}
}

func (c *DNSCache) Get(key string) (*dns.Msg, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.entries[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(entry.ExpiresAt) {
		return nil, false
	}

	return entry.Response.Copy(), true
}

func (c *DNSCache) Set(key string, response *dns.Msg, ttl int) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Simple eviction: remove oldest entry if cache is full
	if len(c.entries) >= c.maxSize {
		// Remove first entry (simple strategy)
		for k := range c.entries {
			delete(c.entries, k)
			break
		}
	}

	c.entries[key] = &CacheEntry{
		Response:  response.Copy(),
		ExpiresAt: time.Now().Add(time.Duration(ttl) * time.Second),
	}
}

func (c *DNSCache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.entries = make(map[string]*CacheEntry)
}

func (s *Stats) RecordQuery(duration time.Duration, cached bool, err error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.queries++
	if cached {
		s.cacheHits++
	} else {
		s.cacheMisses++
	}
	if err != nil {
		s.errors++
	}

	s.queryTimes = append(s.queryTimes, duration)
	if len(s.queryTimes) > 1000 {
		s.queryTimes = s.queryTimes[1:]
	}

	total := time.Duration(0)
	for _, t := range s.queryTimes {
		total += t
	}
	s.avgQueryTime = total / time.Duration(len(s.queryTimes))
}

func (s *Stats) String() string {
	s.mu.RLock()
	defer s.mu.RUnlock()

	hitRate := float64(0)
	if s.queries > 0 {
		hitRate = float64(s.cacheHits) / float64(s.queries) * 100
	}

	return fmt.Sprintf("Queries: %d | Cache Hits: %d (%.2f%%) | Misses: %d | Errors: %d | Avg Time: %s",
		s.queries, s.cacheHits, hitRate, s.cacheMisses, s.errors, s.avgQueryTime)
}

func NewDNSProxy(config *Config) *DNSProxy {
	upstreams := make([]*dns.Client, len(config.Upstreams))
	for i := range config.Upstreams {
		upstreams[i] = &dns.Client{
			Net:     "udp",
			Timeout: time.Duration(config.Timeout) * time.Second,
		}
	}

	return &DNSProxy{
		config:    config,
		cache:     NewDNSCache(config.CacheSize),
		stats:     &Stats{queryTimes: make([]time.Duration, 0, 1000)},
		upstreams: upstreams,
	}
}

func (p *DNSProxy) makeKey(q dns.Question) string {
	return fmt.Sprintf("%s:%d:%d", q.Name, q.Qtype, q.Qclass)
}

func (p *DNSProxy) queryUpstream(msg *dns.Msg) (*dns.Msg, error) {
	var lastErr error

	for i, upstream := range config.Upstreams {
		client := p.upstreams[i]
		response, _, err := client.Exchange(msg, upstream)
		if err == nil && response != nil {
			return response, nil
		}
		lastErr = err
		log.Printf("Failed to query upstream %s: %v", upstream, err)
	}

	return nil, fmt.Errorf("all upstreams failed: %v", lastErr)
}

func (p *DNSProxy) handleDNS(w dns.ResponseWriter, r *dns.Msg) {
	start := time.Now()
	var cached bool
	var err error

	defer func() {
		p.stats.RecordQuery(time.Since(start), cached, err)
	}()

	// Create response message
	msg := new(dns.Msg)
	msg.SetReply(r)
	msg.RecursionAvailable = true

	if len(r.Question) == 0 {
		msg.Rcode = dns.RcodeFormatError
		w.WriteMsg(msg)
		return
	}

	question := r.Question[0]
	cacheKey := p.makeKey(question)

	// Check cache
	if cachedResponse, found := p.cache.Get(cacheKey); found {
		cachedResponse.Id = r.Id
		cached = true
		if err := w.WriteMsg(cachedResponse); err != nil {
			log.Printf("Error writing cached response: %v", err)
		}
		return
	}

	// Query upstream
	response, err := p.queryUpstream(r)
	if err != nil {
		log.Printf("Error querying upstream for %s: %v", question.Name, err)
		msg.Rcode = dns.RcodeServerFailure
		w.WriteMsg(msg)
		return
	}

	// Cache the response
	if response.Rcode == dns.RcodeSuccess && len(response.Answer) > 0 {
		p.cache.Set(cacheKey, response, p.config.CacheTTL)
	}

	// Send response
	response.Id = r.Id
	if err := w.WriteMsg(response); err != nil {
		log.Printf("Error writing response: %v", err)
	}
}

func loadConfig(path string) (*Config, error) {
	// Default configuration
	config := &Config{
		ListenAddr:  defaultListenAddr,
		Upstreams:   []string{defaultUpstream, "8.8.8.8:53", "9.9.9.9:53"},
		CacheSize:   defaultCacheSize,
		CacheTTL:    defaultCacheTTL,
		Timeout:     int(defaultTimeout.Seconds()),
		EnableStats: true,
	}

	if path == "" {
		return config, nil
	}

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return config, nil
		}
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	if err := json.Unmarshal(data, config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %v", err)
	}

	return config, nil
}

var config *Config

func main() {
	configPath := flag.String("config", "/etc/dns-proxy/config.json", "Path to configuration file")
	flag.Parse()

	var err error
	config, err = loadConfig(*configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	log.Printf("Starting DNS Proxy on %s", config.ListenAddr)
	log.Printf("Upstreams: %v", config.Upstreams)
	log.Printf("Cache size: %d entries, TTL: %d seconds", config.CacheSize, config.CacheTTL)

	proxy := NewDNSProxy(config)

	// Setup DNS server
	dns.HandleFunc(".", proxy.handleDNS)

	server := &dns.Server{
		Addr: config.ListenAddr,
		Net:  "udp",
	}

	// Handle graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	// Start stats printer if enabled
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if config.EnableStats {
		go func() {
			ticker := time.NewTicker(30 * time.Second)
			defer ticker.Stop()
			for {
				select {
				case <-ticker.C:
					log.Printf("Stats: %s", proxy.stats.String())
				case <-ctx.Done():
					return
				}
			}
		}()
	}

	// Start server in goroutine
	go func() {
		if err := server.ListenAndServe(); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	log.Printf("DNS Proxy is running. Press Ctrl+C to stop.")

	// Wait for signal
	<-sigCh
	log.Println("Shutting down...")

	cancel()
	if err := server.Shutdown(); err != nil {
		log.Printf("Error during shutdown: %v", err)
	}

	log.Printf("Final stats: %s", proxy.stats.String())
	log.Println("DNS Proxy stopped.")
}
