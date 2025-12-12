"""CLI interface for SpiderNix."""

import asyncio
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.table import Table

from . import __version__
from .config import CrawlerConfig, AGGRESSIVE_CONFIG
from .crawler import SpiderNix
from .browser import BrowserCrawler
from .proxy import ProxyRotator, fetch_public_proxies
from .storage import get_storage

app = typer.Typer(
    name="spider-nix",
    help="🕷️ Enterprise web crawler for public data collection",
    add_completion=False,
)
console = Console()


@app.command()
def crawl(
    url: str = typer.Argument(..., help="URL to crawl"),
    pages: int = typer.Option(10, "--pages", "-p", help="Max pages to crawl"),
    output: Optional[str] = typer.Option(None, "--output", "-o", help="Output file path"),
    format: str = typer.Option("json", "--format", "-f", help="Output format: json, csv, sqlite"),
    browser: bool = typer.Option(False, "--browser", "-b", help="Use browser for JS sites"),
    headless: bool = typer.Option(True, "--headless", help="Run browser headless"),
    follow: bool = typer.Option(False, "--follow", "-F", help="Follow links on pages"),
    proxy_file: Optional[Path] = typer.Option(None, "--proxy-file", help="File with proxy list"),
    concurrent: int = typer.Option(10, "--concurrent", "-c", help="Concurrent requests"),
    aggressive: bool = typer.Option(False, "--aggressive", "-a", help="Aggressive mode (fast, no delays)"),
    timeout: int = typer.Option(30, "--timeout", "-t", help="Request timeout in seconds"),
):
    """Crawl a URL and extract data."""
    
    console.print(f"\n[bold]🕷️ SpiderNix v{__version__}[/]\n")
    
    # Build config
    if aggressive:
        config = AGGRESSIVE_CONFIG.model_copy()
    else:
        config = CrawlerConfig()
    
    config.max_requests_per_crawl = pages
    config.max_concurrent_requests = concurrent
    config.request_timeout_ms = timeout * 1000
    config.use_browser = browser
    config.headless = headless
    
    # Load proxies if provided
    proxy_rotator = None
    if proxy_file:
        proxy_rotator = ProxyRotator.from_file(str(proxy_file))
        console.print(f"[cyan]Loaded {len(proxy_rotator.proxies)} proxies[/]")
    
    # Setup storage
    storage = None
    if output:
        storage = get_storage(output, format)
        console.print(f"[cyan]Output: {output} ({format})[/]")
    
    console.print(f"[cyan]Target: {url}[/]")
    console.print(f"[cyan]Mode: {'Browser' if browser else 'HTTP'} | Pages: {pages} | Concurrent: {concurrent}[/]\n")
    
    # Run crawler
    async def run():
        if browser:
            crawler = BrowserCrawler(config=config, proxy_rotator=proxy_rotator)
        else:
            crawler = SpiderNix(config=config, proxy_rotator=proxy_rotator)
        
        results = await crawler.crawl(
            url,
            max_pages=pages,
            follow_links=follow,
            storage=storage,
        )
        
        return results
    
    results = asyncio.run(run())
    
    # Summary
    console.print(f"\n[bold green]✓ Crawled {len(results)} pages[/]")
    if output:
        console.print(f"[green]Saved to: {output}[/]")


@app.command()
def proxy_fetch():
    """Fetch public proxies (unreliable, for testing only)."""
    
    console.print("[yellow]Fetching public proxies...[/]")
    
    async def run():
        return await fetch_public_proxies()
    
    proxies = asyncio.run(run())
    
    console.print(f"[green]Found {len(proxies)} proxies[/]\n")
    
    # Save to file
    with open("proxies.txt", "w") as f:
        for proxy in proxies:
            f.write(proxy + "\n")
    
    console.print("[green]Saved to: proxies.txt[/]")


@app.command()
def proxy_stats(
    proxy_file: Path = typer.Argument(..., help="Proxy file to analyze"),
    test: bool = typer.Option(False, "--test", "-t", help="Test proxies"),
):
    """Show proxy statistics."""
    
    rotator = ProxyRotator.from_file(str(proxy_file))
    
    console.print(f"[bold]Proxies: {len(rotator.proxies)}[/]\n")
    
    if test:
        console.print("[yellow]Testing proxies...[/]\n")
        
        import httpx
        
        async def test_proxy(proxy: str) -> tuple[str, bool, float]:
            try:
                async with httpx.AsyncClient(
                    proxy=proxy,
                    timeout=10,
                ) as client:
                    import time
                    start = time.monotonic()
                    resp = await client.get("https://httpbin.org/ip")
                    elapsed = (time.monotonic() - start) * 1000
                    return proxy, resp.status_code == 200, elapsed
            except Exception:
                return proxy, False, 0
        
        async def run():
            tasks = [test_proxy(p) for p in rotator.proxies[:20]]  # Test first 20
            return await asyncio.gather(*tasks)
        
        results = asyncio.run(run())
        
        table = Table(title="Proxy Test Results")
        table.add_column("Proxy", style="cyan")
        table.add_column("Status", style="green")
        table.add_column("Latency", style="yellow")
        
        for proxy, ok, latency in results:
            status = "✓ OK" if ok else "✗ Failed"
            lat = f"{latency:.0f}ms" if ok else "-"
            table.add_row(proxy[:50], status, lat)
        
        console.print(table)


@app.command()
def version():
    """Show version."""
    console.print(f"[bold]SpiderNix v{__version__}[/]")


if __name__ == "__main__":
    app()
