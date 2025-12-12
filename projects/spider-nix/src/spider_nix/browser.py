"""Browser-based crawler using Playwright for JavaScript-heavy sites."""

import asyncio
from typing import Callable

from rich.console import Console

from .config import CrawlerConfig
from .proxy import ProxyRotator
from .stealth import StealthEngine
from .storage import CrawlResult, StorageBackend

console = Console()


class BrowserCrawler:
    """Playwright-based crawler for JavaScript-heavy sites."""
    
    def __init__(
        self,
        config: CrawlerConfig | None = None,
        proxy_rotator: ProxyRotator | None = None,
    ):
        self.config = config or CrawlerConfig(use_browser=True)
        self.proxy = proxy_rotator or ProxyRotator(
            proxies=self.config.proxy.urls,
            strategy=self.config.proxy.rotation_strategy,
        )
        self.stealth = StealthEngine()
        self._results: list[CrawlResult] = []
    
    async def crawl(
        self,
        start_url: str,
        max_pages: int | None = None,
        follow_links: bool = False,
        link_filter: Callable[[str], bool] | None = None,
        storage: StorageBackend | None = None,
        wait_for: str | None = None,
        screenshot: bool = False,
    ) -> list[CrawlResult]:
        """
        Crawl using headless browser.
        
        Args:
            start_url: Starting URL
            max_pages: Max pages to crawl
            follow_links: Follow links on pages
            link_filter: Filter function for links
            storage: Storage backend
            wait_for: CSS selector to wait for before capturing
            screenshot: Take screenshots
        """
        try:
            from playwright.async_api import async_playwright
        except ImportError:
            console.print("[red]Playwright not installed. Run: pip install playwright && playwright install[/]")
            return []
        
        max_pages = max_pages or self.config.max_requests_per_crawl
        self._results.clear()
        visited: set[str] = set()
        queue = [start_url]
        
        async with async_playwright() as p:
            # Launch browser
            browser_type = getattr(p, self.config.browser_type)
            
            launch_args = {
                "headless": self.config.headless,
                "args": [
                    "--disable-blink-features=AutomationControlled",
                    "--disable-dev-shm-usage",
                    "--no-sandbox",
                ],
            }
            
            # Add proxy if available
            proxy_url = self.proxy.get_next()
            if proxy_url:
                launch_args["proxy"] = {"server": proxy_url}
            
            browser = await browser_type.launch(**launch_args)
            
            # Create context with stealth
            fingerprint = self.stealth.get_fingerprint()
            context = await browser.new_context(
                viewport={
                    "width": fingerprint["screen"]["width"],
                    "height": fingerprint["screen"]["height"],
                },
                user_agent=self.stealth.get_user_agent(),
                locale=fingerprint["language"],
                timezone_id=fingerprint["timezone"],
            )
            
            # Inject stealth script
            await context.add_init_script(self.stealth.get_playwright_stealth_script())
            
            page = await context.new_page()
            
            while queue and len(visited) < max_pages:
                url = queue.pop(0)
                
                if url in visited:
                    continue
                
                visited.add(url)
                
                try:
                    result = await self._fetch_page(
                        page, url, wait_for, screenshot
                    )
                    
                    if result:
                        self._results.append(result)
                        
                        if storage:
                            await storage.save(result)
                        
                        console.print(f"[green]✓[/] [browser] {url}")
                        
                        # Follow links
                        if follow_links and result.status_code == 200:
                            links = await self._extract_links(page, url)
                            for link in links:
                                if link not in visited:
                                    if link_filter is None or link_filter(link):
                                        queue.append(link)
                        
                        # Human-like delay
                        if self.config.stealth.human_like_delays:
                            delay = self.stealth.get_random_delay_ms(
                                self.config.stealth.min_delay_ms,
                                self.config.stealth.max_delay_ms,
                            ) / 1000
                            await asyncio.sleep(delay)
                
                except Exception as e:
                    console.print(f"[red]✗[/] [browser] {url}: {e}")
            
            await browser.close()
        
        if storage:
            await storage.close()
        
        return self._results
    
    async def _fetch_page(
        self,
        page,
        url: str,
        wait_for: str | None,
        screenshot: bool,
    ) -> CrawlResult | None:
        """Fetch a single page with browser."""
        import time
        
        start = time.monotonic()
        
        try:
            response = await page.goto(url, wait_until="networkidle")
            
            if wait_for:
                await page.wait_for_selector(wait_for, timeout=10000)
            
            # Get rendered content
            content = await page.content()
            elapsed_ms = (time.monotonic() - start) * 1000
            
            metadata = {
                "elapsed_ms": elapsed_ms,
                "browser": self.config.browser_type,
                "rendered": True,
            }
            
            # Screenshot if requested
            if screenshot:
                screenshot_path = f"screenshots/{url.replace('/', '_')[:50]}.png"
                await page.screenshot(path=screenshot_path)
                metadata["screenshot"] = screenshot_path
            
            return CrawlResult(
                url=url,
                status_code=response.status if response else 0,
                content=content,
                headers=dict(response.headers) if response else {},
                metadata=metadata,
            )
            
        except Exception as e:
            console.print(f"[red]Browser error:[/] {e}")
            return None
    
    async def _extract_links(self, page, base_url: str) -> list[str]:
        """Extract links using browser."""
        from urllib.parse import urljoin, urlparse
        
        links = await page.eval_on_selector_all(
            "a[href]",
            "elements => elements.map(el => el.href)"
        )
        
        # Filter to same domain
        base_domain = urlparse(base_url).netloc
        return [
            link for link in links
            if urlparse(link).netloc == base_domain
        ]
