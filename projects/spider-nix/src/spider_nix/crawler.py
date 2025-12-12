"""Core crawler implementation using httpx with stealth."""

import asyncio
import time
from typing import AsyncGenerator, Callable
from urllib.parse import urljoin, urlparse

import httpx
from rich.console import Console

from .config import CrawlerConfig
from .proxy import ProxyRotator
from .stealth import StealthEngine
from .storage import CrawlResult, StorageBackend, get_storage

console = Console()


class SpiderNix:
    """Enterprise web crawler with anti-detection and proxy rotation."""
    
    def __init__(
        self,
        config: CrawlerConfig | None = None,
        proxy_rotator: ProxyRotator | None = None,
    ):
        self.config = config or CrawlerConfig()
        self.proxy = proxy_rotator or ProxyRotator(
            proxies=self.config.proxy.urls,
            strategy=self.config.proxy.rotation_strategy,
        )
        self.stealth = StealthEngine()
        self._visited: set[str] = set()
        self._queue: asyncio.Queue[str] = asyncio.Queue()
        self._results: list[CrawlResult] = []
        self._running = False
    
    async def crawl(
        self,
        start_url: str,
        max_pages: int | None = None,
        follow_links: bool = False,
        link_filter: Callable[[str], bool] | None = None,
        storage: StorageBackend | None = None,
    ) -> list[CrawlResult]:
        """
        Crawl starting from a URL.
        
        Args:
            start_url: Starting URL
            max_pages: Max pages to crawl (overrides config)
            follow_links: Whether to follow links on pages
            link_filter: Function to filter which links to follow
            storage: Optional storage backend for results
        """
        max_pages = max_pages or self.config.max_requests_per_crawl
        self._running = True
        self._visited.clear()
        self._results.clear()
        
        await self._queue.put(start_url)
        
        tasks = []
        for _ in range(self.config.max_concurrent_requests):
            task = asyncio.create_task(
                self._worker(max_pages, follow_links, link_filter, storage)
            )
            tasks.append(task)
        
        # Wait for queue to empty
        await self._queue.join()
        self._running = False
        
        # Cancel workers
        for task in tasks:
            task.cancel()
        
        if storage:
            await storage.close()
        
        return self._results
    
    async def _worker(
        self,
        max_pages: int,
        follow_links: bool,
        link_filter: Callable[[str], bool] | None,
        storage: StorageBackend | None,
    ):
        """Worker coroutine that processes URLs from queue."""
        async with httpx.AsyncClient(
            timeout=self.config.request_timeout_ms / 1000,
            follow_redirects=True,
        ) as client:
            while self._running:
                try:
                    url = await asyncio.wait_for(self._queue.get(), timeout=2)
                except asyncio.TimeoutError:
                    continue
                
                try:
                    if url in self._visited or len(self._visited) >= max_pages:
                        continue
                    
                    self._visited.add(url)
                    result = await self._fetch_with_retry(client, url)
                    
                    if result:
                        self._results.append(result)
                        
                        if storage:
                            await storage.save(result)
                        
                        console.print(f"[green]✓[/] {url} ({result.status_code})")
                        
                        # Follow links
                        if follow_links and result.status_code == 200:
                            links = self._extract_links(result.content, url)
                            for link in links:
                                if link not in self._visited:
                                    if link_filter is None or link_filter(link):
                                        await self._queue.put(link)
                    
                finally:
                    self._queue.task_done()
    
    async def _fetch_with_retry(
        self,
        client: httpx.AsyncClient,
        url: str,
    ) -> CrawlResult | None:
        """Fetch URL with retry logic and proxy rotation."""
        last_error = None
        
        for attempt in range(self.config.max_retries):
            proxy_url = self.proxy.get_next()
            headers = self.stealth.get_headers()
            
            try:
                start = time.monotonic()
                
                # Configure proxy if available
                if proxy_url:
                    client._mounts = {
                        "http://": httpx.HTTPTransport(proxy=proxy_url),
                        "https://": httpx.HTTPTransport(proxy=proxy_url),
                    }
                
                response = await client.get(url, headers=headers)
                elapsed_ms = (time.monotonic() - start) * 1000
                
                # Report proxy stats
                if proxy_url:
                    if response.status_code in self.config.retry_on_status_codes:
                        self.proxy.report_blocked(proxy_url)
                    else:
                        self.proxy.report_success(proxy_url, elapsed_ms)
                
                # Check if blocked
                if response.status_code in self.config.retry_on_status_codes:
                    console.print(f"[yellow]⚠[/] {url} blocked ({response.status_code}), retrying...")
                    
                    # Human-like delay before retry
                    if self.config.stealth.human_like_delays:
                        delay = self.stealth.get_random_delay_ms(
                            self.config.stealth.min_delay_ms,
                            self.config.stealth.max_delay_ms,
                        ) / 1000
                        await asyncio.sleep(delay)
                    
                    continue
                
                return CrawlResult(
                    url=url,
                    status_code=response.status_code,
                    content=response.text,
                    headers=dict(response.headers),
                    metadata={
                        "elapsed_ms": elapsed_ms,
                        "proxy": proxy_url,
                        "attempt": attempt + 1,
                    }
                )
                
            except httpx.RequestError as e:
                last_error = e
                if proxy_url:
                    self.proxy.report_failure(proxy_url)
                console.print(f"[red]✗[/] {url} error: {e}, retrying...")
                await asyncio.sleep(1)
        
        console.print(f"[red]✗[/] {url} failed after {self.config.max_retries} attempts")
        return None
    
    def _extract_links(self, html: str, base_url: str) -> list[str]:
        """Extract links from HTML."""
        import re
        
        links = []
        for match in re.finditer(r'href=["\']([^"\']+)["\']', html):
            href = match.group(1)
            # Convert relative to absolute
            full_url = urljoin(base_url, href)
            # Only same domain
            if urlparse(full_url).netloc == urlparse(base_url).netloc:
                links.append(full_url)
        
        return list(set(links))


async def quick_crawl(url: str, pages: int = 10) -> list[CrawlResult]:
    """Quick crawl helper function."""
    spider = SpiderNix()
    return await spider.crawl(url, max_pages=pages)
