"""Anti-detection stealth module for SpiderNix."""

import random
from typing import Any
from fake_useragent import UserAgent


# Pool of realistic browser fingerprints
SCREEN_RESOLUTIONS = [
    (1920, 1080), (1366, 768), (1536, 864), (1440, 900),
    (1280, 720), (2560, 1440), (3840, 2160), (1600, 900),
]

WEBGL_VENDORS = [
    "Google Inc. (NVIDIA)",
    "Google Inc. (Intel)",
    "Google Inc. (AMD)",
    "Intel Inc.",
    "NVIDIA Corporation",
]

LANGUAGES = [
    "en-US,en;q=0.9",
    "en-GB,en;q=0.9",
    "pt-BR,pt;q=0.9,en;q=0.8",
    "es-ES,es;q=0.9,en;q=0.8",
    "de-DE,de;q=0.9,en;q=0.8",
]

TIMEZONES = [
    "America/New_York", "America/Los_Angeles", "America/Chicago",
    "America/Sao_Paulo", "Europe/London", "Europe/Berlin",
]


class StealthEngine:
    """Generate realistic browser fingerprints to avoid detection."""
    
    def __init__(self, seed: int | None = None):
        self._rng = random.Random(seed)
        self._ua = UserAgent(browsers=["chrome", "firefox", "edge"])
    
    def get_user_agent(self) -> str:
        """Get random realistic user agent."""
        return self._ua.random
    
    def get_headers(self) -> dict[str, str]:
        """Generate realistic request headers."""
        ua = self.get_user_agent()
        
        return {
            "User-Agent": ua,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": self._rng.choice(LANGUAGES),
            "Accept-Encoding": "gzip, deflate, br",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Cache-Control": "max-age=0",
        }
    
    def get_fingerprint(self) -> dict[str, Any]:
        """Generate randomized browser fingerprint."""
        resolution = self._rng.choice(SCREEN_RESOLUTIONS)
        
        return {
            "screen": {
                "width": resolution[0],
                "height": resolution[1],
                "colorDepth": 24,
                "pixelRatio": self._rng.choice([1, 1.25, 1.5, 2]),
            },
            "webgl": {
                "vendor": self._rng.choice(WEBGL_VENDORS),
                "renderer": f"ANGLE (NVIDIA, NVIDIA GeForce GTX {self._rng.randint(1060, 4090)})",
            },
            "timezone": self._rng.choice(TIMEZONES),
            "language": self._rng.choice(LANGUAGES).split(",")[0],
            "platform": self._rng.choice(["Win32", "Linux x86_64", "MacIntel"]),
            "hardwareConcurrency": self._rng.choice([4, 8, 12, 16]),
            "deviceMemory": self._rng.choice([4, 8, 16, 32]),
        }
    
    def get_random_delay_ms(self, min_ms: int = 500, max_ms: int = 3000) -> int:
        """Get humanized random delay."""
        # Use log-normal distribution for more human-like delays
        mean = (min_ms + max_ms) / 2
        return int(self._rng.gauss(mean, (max_ms - min_ms) / 4))
    
    def get_playwright_stealth_script(self) -> str:
        """JavaScript to inject for Playwright stealth."""
        fingerprint = self.get_fingerprint()
        
        return f"""
        // Override navigator properties
        Object.defineProperty(navigator, 'webdriver', {{ get: () => undefined }});
        Object.defineProperty(navigator, 'languages', {{ get: () => ['{fingerprint["language"]}', 'en'] }});
        Object.defineProperty(navigator, 'platform', {{ get: () => '{fingerprint["platform"]}' }});
        Object.defineProperty(navigator, 'hardwareConcurrency', {{ get: () => {fingerprint["hardwareConcurrency"]} }});
        Object.defineProperty(navigator, 'deviceMemory', {{ get: () => {fingerprint["deviceMemory"]} }});
        
        // Override screen
        Object.defineProperty(screen, 'width', {{ get: () => {fingerprint["screen"]["width"]} }});
        Object.defineProperty(screen, 'height', {{ get: () => {fingerprint["screen"]["height"]} }});
        Object.defineProperty(screen, 'colorDepth', {{ get: () => {fingerprint["screen"]["colorDepth"]} }});
        
        // Override WebGL
        const getParameter = WebGLRenderingContext.prototype.getParameter;
        WebGLRenderingContext.prototype.getParameter = function(parameter) {{
            if (parameter === 37445) return '{fingerprint["webgl"]["vendor"]}';
            if (parameter === 37446) return '{fingerprint["webgl"]["renderer"]}';
            return getParameter.call(this, parameter);
        }};
        
        // Disable automation flags
        delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
        delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
        delete window.cdc_adoQpoasnfa76pfcZLmcfl_Symbol;
        """
