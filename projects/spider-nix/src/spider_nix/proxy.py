"""Proxy rotation engine for SpiderNix."""

import random
from dataclasses import dataclass, field
from typing import Literal


@dataclass
class ProxyStats:
    """Track proxy performance stats."""
    
    url: str
    requests: int = 0
    failures: int = 0
    blocked: int = 0
    avg_response_ms: float = 0.0
    
    @property
    def success_rate(self) -> float:
        if self.requests == 0:
            return 1.0
        return (self.requests - self.failures - self.blocked) / self.requests
    
    @property
    def is_healthy(self) -> bool:
        return self.success_rate > 0.5 and self.blocked < 10


@dataclass
class ProxyRotator:
    """Intelligent proxy rotation with health tracking."""
    
    proxies: list[str] = field(default_factory=list)
    strategy: Literal["round_robin", "random", "least_used", "best_performer"] = "random"
    rotate_on_block: bool = True
    
    _current_index: int = field(default=0, init=False)
    _stats: dict[str, ProxyStats] = field(default_factory=dict, init=False)
    
    def __post_init__(self):
        for proxy in self.proxies:
            self._stats[proxy] = ProxyStats(url=proxy)
    
    def add_proxy(self, url: str) -> None:
        """Add a proxy to the pool."""
        if url not in self.proxies:
            self.proxies.append(url)
            self._stats[url] = ProxyStats(url=url)
    
    def remove_proxy(self, url: str) -> None:
        """Remove a proxy from the pool."""
        if url in self.proxies:
            self.proxies.remove(url)
            del self._stats[url]
    
    def get_next(self) -> str | None:
        """Get next proxy based on strategy."""
        healthy = [p for p in self.proxies if self._stats[p].is_healthy]
        if not healthy:
            healthy = self.proxies  # Fallback to all
        
        if not healthy:
            return None
        
        if self.strategy == "round_robin":
            self._current_index = (self._current_index + 1) % len(healthy)
            return healthy[self._current_index]
        
        elif self.strategy == "random":
            return random.choice(healthy)
        
        elif self.strategy == "least_used":
            return min(healthy, key=lambda p: self._stats[p].requests)
        
        elif self.strategy == "best_performer":
            return max(healthy, key=lambda p: self._stats[p].success_rate)
        
        return healthy[0]
    
    def report_success(self, proxy: str, response_ms: float) -> None:
        """Report successful request."""
        if proxy in self._stats:
            stats = self._stats[proxy]
            stats.requests += 1
            # Rolling average
            stats.avg_response_ms = (stats.avg_response_ms * 0.9) + (response_ms * 0.1)
    
    def report_failure(self, proxy: str) -> None:
        """Report failed request."""
        if proxy in self._stats:
            self._stats[proxy].requests += 1
            self._stats[proxy].failures += 1
    
    def report_blocked(self, proxy: str) -> None:
        """Report blocked/rate-limited request."""
        if proxy in self._stats:
            self._stats[proxy].requests += 1
            self._stats[proxy].blocked += 1
            
            # Auto-remove if too many blocks
            if self._stats[proxy].blocked > 20:
                self.remove_proxy(proxy)
    
    def get_stats(self) -> dict[str, ProxyStats]:
        """Get all proxy stats."""
        return self._stats.copy()
    
    @classmethod
    def from_file(cls, filepath: str, **kwargs) -> "ProxyRotator":
        """Load proxies from file (one per line)."""
        with open(filepath) as f:
            proxies = [line.strip() for line in f if line.strip() and not line.startswith("#")]
        return cls(proxies=proxies, **kwargs)


# Public proxy sources (for testing - not reliable for production)
PUBLIC_PROXY_SOURCES = [
    "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt",
    "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt",
    "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt",
]


async def fetch_public_proxies() -> list[str]:
    """Fetch free public proxies (unreliable, for testing only)."""
    import httpx
    
    proxies = []
    async with httpx.AsyncClient(timeout=10) as client:
        for url in PUBLIC_PROXY_SOURCES:
            try:
                resp = await client.get(url)
                if resp.status_code == 200:
                    for line in resp.text.splitlines():
                        line = line.strip()
                        if line and ":" in line:
                            proxies.append(f"http://{line}")
            except Exception:
                pass
    
    return list(set(proxies))  # Dedupe
