#!/usr/bin/env python3
"""
Notion Database Exporter
=========================
Export your Notion databases to Markdown and JSON for platform migration.

Features:
- Export to Markdown (human-readable)
- Export to JSON (structured data)
- Preserve metadata (tags, status, dates, people)
- Hierarchical block structure
- Progress tracking
- Batch processing

Usage:
    python notion-exporter.py --token <TOKEN> --database <DB_ID> --output ./export
"""

import argparse
import json
import logging
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import requests

# API Configuration
NOTION_BASE_URL = "https://api.notion.com/v1"
DATABASE_URL = f"{NOTION_BASE_URL}/databases/{{database_id}}/query"
BLOCK_URL = f"{NOTION_BASE_URL}/blocks/{{block_id}}/children"
NOTION_VERSION = "2022-06-28"

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(levelname)-8s │ %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger(__name__)


class NotionExporter:
    """Export Notion database to various formats."""
    
    def __init__(
        self,
        integration_token: str,
        database_id: str,
        timeout: int = 30
    ):
        if not integration_token:
            raise ValueError("Integration token required")
        if not database_id:
            raise ValueError("Database ID required")
        
        self.token = integration_token
        self.database_id = database_id
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Notion-Version": NOTION_VERSION,
        }
        self.timeout = timeout
    
    def export_all(
        self,
        output_dir: Path,
        formats: List[str] = ["markdown", "json"]
    ) -> Dict[str, int]:
        """Export database to specified formats."""
        output_dir.mkdir(parents=True, exist_ok=True)
        
        log.info(f"🔍 Fetching pages from Notion database...")
        pages = self._fetch_all_pages()
        
        log.info(f"📦 Found {len(pages)} pages to export")
        
        stats = {"total": len(pages), "exported": 0, "errors": 0}
        
        # Process each page
        for i, page_data in enumerate(pages, 1):
            try:
                log.info(f"Processing {i}/{len(pages)}: {self._get_title(page_data)}")
                
                # Load full page content
                page = self._load_page(page_data)
                
                # Export to requested formats
                if "markdown" in formats:
                    self._export_markdown(page, output_dir)
                if "json" in formats:
                    self._export_json(page, output_dir)
                
                stats["exported"] += 1
            
            except Exception as e:
                log.error(f"❌ Failed to export page: {e}")
                stats["errors"] += 1
        
        log.info(f"\n✅ Export complete!")
        log.info(f"   Exported: {stats['exported']}/{stats['total']}")
        if stats['errors']:
            log.warning(f"   Errors: {stats['errors']}")
        
        return stats
    
    def _fetch_all_pages(self) -> List[Dict[str, Any]]:
        """Fetch all pages from database with pagination."""
        pages = []
        has_more = True
        start_cursor = None
        
        while has_more:
            query = {"page_size": 100}
            if start_cursor:
                query["start_cursor"] = start_cursor
            
            response = self._request(
                DATABASE_URL.format(database_id=self.database_id),
                method="POST",
                json_data=query
            )
            
            pages.extend(response.get("results", []))
            has_more = response.get("has_more", False)
            start_cursor = response.get("next_cursor")
        
        return pages
    
    def _load_page(self, page_data: Dict[str, Any]) -> Dict[str, Any]:
        """Load complete page with content and metadata."""
        page_id = page_data["id"]
        
        # Extract metadata
        metadata = self._extract_metadata(page_data)
        
        # Load content blocks
        content = self._load_blocks(page_id)
        
        return {
            "id": page_id,
            "url": page_data.get("url", ""),
            "title": self._get_title(page_data),
            "metadata": metadata,
            "content": content,
            "raw": page_data  # Keep for JSON export
        }
    
    def _extract_metadata(self, page_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract all metadata from page properties."""
        metadata = {}
        
        for prop_name, prop_data in page_data.get("properties", {}).items():
            prop_type = prop_data["type"]
            value = None
            
            if prop_type == "title":
                value = self._concat_rich_text(prop_data["title"])
            elif prop_type == "rich_text":
                value = self._concat_rich_text(prop_data["rich_text"])
            elif prop_type == "multi_select":
                value = [item["name"] for item in prop_data.get("multi_select", [])]
            elif prop_type == "select":
                value = prop_data["select"]["name"] if prop_data.get("select") else None
            elif prop_type == "status":
                value = prop_data["status"]["name"] if prop_data.get("status") else None
            elif prop_type == "date":
                date_obj = prop_data.get("date")
                if date_obj:
                    value = {
                        "start": date_obj.get("start"),
                        "end": date_obj.get("end")
                    }
            elif prop_type == "people":
                value = [p.get("name", "Unknown") for p in prop_data.get("people", [])]
            elif prop_type == "url":
                value = prop_data.get("url")
            elif prop_type == "email":
                value = prop_data.get("email")
            elif prop_type == "phone_number":
                value = prop_data.get("phone_number")
            elif prop_type == "checkbox":
                value = prop_data.get("checkbox", False)
            elif prop_type == "number":
                value = prop_data.get("number")
            elif prop_type == "created_time":
                value = prop_data.get("created_time")
            elif prop_type == "last_edited_time":
                value = prop_data.get("last_edited_time")
            
            if value is not None:
                metadata[prop_name] = value
        
        return metadata
    
    def _load_blocks(self, block_id: str, indent: int = 0) -> str:
        """Recursively load all blocks and children."""
        lines = []
        cursor = None
        has_more = True
        
        while has_more:
            url = BLOCK_URL.format(block_id=block_id)
            if cursor:
                url += f"?start_cursor={cursor}"
            
            response = self._request(url)
            
            for block in response.get("results", []):
                block_type = block["type"]
                block_content = block.get(block_type, {})
                
                # Extract text from rich_text
                if "rich_text" in block_content:
                    text = self._concat_rich_text(block_content["rich_text"])
                    if text:
                        prefix = "  " * indent
                        
                        # Format based on block type
                        if block_type == "heading_1":
                            lines.append(f"{prefix}# {text}")
                        elif block_type == "heading_2":
                            lines.append(f"{prefix}## {text}")
                        elif block_type == "heading_3":
                            lines.append(f"{prefix}### {text}")
                        elif block_type == "bulleted_list_item":
                            lines.append(f"{prefix}- {text}")
                        elif block_type == "numbered_list_item":
                            lines.append(f"{prefix}1. {text}")
                        elif block_type == "to_do":
                            checked = "x" if block_content.get("checked") else " "
                            lines.append(f"{prefix}- [{checked}] {text}")
                        elif block_type == "toggle":
                            lines.append(f"{prefix}▶ {text}")
                        elif block_type == "quote":
                            lines.append(f"{prefix}> {text}")
                        elif block_type == "code":
                            lang = block_content.get("language", "")
                            lines.append(f"{prefix}```{lang}")
                            lines.append(f"{prefix}{text}")
                            lines.append(f"{prefix}```")
                        else:
                            lines.append(f"{prefix}{text}")
                
                # Recursively load children
                if block.get("has_children"):
                    child_content = self._load_blocks(block["id"], indent + 1)
                    if child_content:
                        lines.append(child_content)
            
            has_more = response.get("has_more", False)
            cursor = response.get("next_cursor")
        
        return "\n".join(lines)
    
    def _get_title(self, page_data: Dict[str, Any]) -> str:
        """Extract page title."""
        for prop_data in page_data.get("properties", {}).values():
            if prop_data["type"] == "title":
                return self._concat_rich_text(prop_data["title"]) or "Untitled"
        return "Untitled"
    
    def _concat_rich_text(self, rich_text_array: List[Dict[str, Any]]) -> str:
        """Concatenate rich text array to plain text."""
        return "".join(item.get("plain_text", "") for item in rich_text_array)
    
    def _sanitize_filename(self, name: str) -> str:
        """Sanitize string for use as filename."""
        # Remove invalid characters
        name = re.sub(r'[<>:"/\\|?*]', '', name)
        # Replace spaces with underscores
        name = name.replace(' ', '_')
        # Limit length
        return name[:100]
    
    def _export_markdown(self, page: Dict[str, Any], output_dir: Path) -> None:
        """Export page as Markdown file."""
        filename = self._sanitize_filename(page["title"]) + ".md"
        filepath = output_dir / "markdown" / filename
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Build Markdown content
        md_lines = [
            f"# {page['title']}",
            "",
            "---",
            ""
        ]
        
        # Add metadata as frontmatter
        if page["metadata"]:
            md_lines.append("## Metadata")
            md_lines.append("")
            for key, value in page["metadata"].items():
                if key != page["title"]:  # Skip redundant title
                    if isinstance(value, list):
                        value = ", ".join(str(v) for v in value)
                    md_lines.append(f"- **{key}**: {value}")
            md_lines.append("")
            md_lines.append("---")
            md_lines.append("")
        
        # Add content
        if page["content"]:
            md_lines.append(page["content"])
        
        # Add footer
        md_lines.append("")
        md_lines.append("---")
        md_lines.append(f"*Exported from Notion on {datetime.now().isoformat()}*")
        md_lines.append(f"*Original URL: {page['url']}*")
        
        filepath.write_text("\n".join(md_lines))
    
    def _export_json(self, page: Dict[str, Any], output_dir: Path) -> None:
        """Export page as JSON file."""
        filename = self._sanitize_filename(page["title"]) + ".json"
        filepath = output_dir / "json" / filename
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Create export object
        export_data = {
            "id": page["id"],
            "title": page["title"],
            "url": page["url"],
            "metadata": page["metadata"],
            "content": page["content"],
            "exported_at": datetime.now().isoformat(),
            "raw_notion_data": page["raw"]
        }
        
        filepath.write_text(json.dumps(export_data, indent=2, ensure_ascii=False))
    
    def _request(
        self,
        url: str,
        method: str = "GET",
        json_data: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Make HTTP request to Notion API."""
        response = requests.request(
            method,
            url,
            headers=self.headers,
            json=json_data,
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()


def main():
    parser = argparse.ArgumentParser(
        description="Export Notion database to Markdown and JSON",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Export to markdown only
  notion-exporter.py --token secret_xxx --database abc123 --output ./export --format markdown
  
  # Export to both formats
  notion-exporter.py --token secret_xxx --database abc123 --output ./export
  
  # Use environment variables
  export NOTION_TOKEN=secret_xxx
  export NOTION_DATABASE=abc123
  notion-exporter.py --output ./my-notes
        """
    )
    
    parser.add_argument(
        "--token", "-t",
        default=os.getenv("NOTION_TOKEN"),
        help="Notion integration token (or set NOTION_TOKEN env var)"
    )
    parser.add_argument(
        "--database", "-d",
        default=os.getenv("NOTION_DATABASE"),
        help="Notion database ID (or set NOTION_DATABASE env var)"
    )
    parser.add_argument(
        "--output", "-o",
        default="./notion-export",
        help="Output directory (default: ./notion-export)"
    )
    parser.add_argument(
        "--format", "-f",
        choices=["markdown", "json", "both"],
        default="both",
        help="Export format (default: both)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Request timeout in seconds (default: 30)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.token:
        parser.error("--token required (or set NOTION_TOKEN environment variable)")
    if not args.database:
        parser.error("--database required (or set NOTION_DATABASE environment variable)")
    
    # Determine formats
    if args.format == "both":
        formats = ["markdown", "json"]
    else:
        formats = [args.format]
    
    try:
        log.info("🚀 Notion Database Exporter")
        log.info(f"   Database: {args.database}")
        log.info(f"   Output: {args.output}")
        log.info(f"   Formats: {', '.join(formats)}")
        log.info("")
        
        exporter = NotionExporter(args.token, args.database, args.timeout)
        stats = exporter.export_all(Path(args.output), formats)
        
        log.info(f"\n📁 Files exported to: {args.output}")
        
    except KeyboardInterrupt:
        log.warning("\n⚠️  Export interrupted by user")
    except Exception as e:
        log.error(f"\n❌ Export failed: {e}")
        import traceback
        traceback.print_exc()
        exit(1)


if __name__ == "__main__":
    main()
