"""Configuration management for SpiderNix."""

from pydantic import BaseModel, Field
from typing import Literal


class ProxyConfig(BaseModel):
    """Proxy rotation configuration."""
    
    urls: list[str] = Field(default_factory=list)
    rotate_on_block: bool = True
    rotation_strategy: Literal["round_robin", "random", "least_used"] = "random"


class StealthConfig(BaseModel):
    """Anti-detection configuration."""
    
    randomize_user_agent: bool = True
    randomize_fingerprint: bool = True
    human_like_delays: bool = True
    min_delay_ms: int = 500
    max_delay_ms: int = 3000


class CrawlerConfig(BaseModel):
    """Main crawler configuration."""
    
    # Request settings
    max_requests_per_crawl: int = 1000
    max_concurrent_requests: int = 10
    request_timeout_ms: int = 30000
    
    # Retry settings
    max_retries: int = 5
    retry_on_status_codes: list[int] = Field(default_factory=lambda: [429, 500, 502, 503, 504])
    
    # Browser settings
    use_browser: bool = False
    headless: bool = True
    browser_type: Literal["chromium", "firefox", "webkit"] = "chromium"
    
    # Anti-detection
    stealth: StealthConfig = Field(default_factory=StealthConfig)
    proxy: ProxyConfig = Field(default_factory=ProxyConfig)
    
    # Output
    output_format: Literal["json", "csv", "sqlite"] = "json"
    output_path: str = "output"


# Default aggressive configuration
AGGRESSIVE_CONFIG = CrawlerConfig(
    max_concurrent_requests=50,
    max_retries=10,
    stealth=StealthConfig(
        randomize_user_agent=True,
        randomize_fingerprint=True,
        human_like_delays=False,  # Faster
        min_delay_ms=100,
        max_delay_ms=500,
    ),
)
