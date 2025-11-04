#!/usr/bin/env python3
"""
Intelligent Dataset Downloader
Automatically downloads and preprocesses popular ML datasets
Supports parallel downloads, caching, and validation
"""

import asyncio
import aiohttp
import hashlib
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor
import zipfile
import tarfile
import gzip
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TimeElapsedColumn
from rich.table import Table
import pandas as pd

console = Console()


@dataclass
class Dataset:
    """Dataset metadata"""
    name: str
    url: str
    filename: str
    description: str
    size_mb: float
    checksum: Optional[str] = None
    extract: bool = True
    format: str = 'zip'


# Curated list of popular datasets
DATASETS = {
    'mnist': Dataset(
        name='MNIST',
        url='http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz',
        filename='mnist.gz',
        description='Handwritten digits dataset',
        size_mb=9.9,
        format='gz'
    ),
    'cifar10': Dataset(
        name='CIFAR-10',
        url='https://www.cs.toronto.edu/~kriz/cifar-10-python.tar.gz',
        filename='cifar10.tar.gz',
        description='60k 32x32 color images in 10 classes',
        size_mb=163,
        format='tar.gz'
    ),
    'imdb': Dataset(
        name='IMDB Reviews',
        url='https://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz',
        filename='imdb.tar.gz',
        description='Movie reviews for sentiment analysis',
        size_mb=84,
        format='tar.gz'
    ),
    'titanic': Dataset(
        name='Titanic',
        url='https://web.stanford.edu/class/archive/cs/cs109/cs109.1166/stuff/titanic.csv',
        filename='titanic.csv',
        description='Titanic passenger survival data',
        size_mb=0.06,
        extract=False,
        format='csv'
    ),
    'boston': Dataset(
        name='Boston Housing',
        url='https://raw.githubusercontent.com/selva86/datasets/master/BostonHousing.csv',
        filename='boston.csv',
        description='Boston house prices',
        size_mb=0.04,
        extract=False,
        format='csv'
    )
}


class DatasetDownloader:
    """Intelligent dataset downloader with caching and parallel processing"""
    
    def __init__(self, data_dir: str = './data/raw'):
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.cache_file = self.data_dir / '.cache.json'
        self.executor = ThreadPoolExecutor(max_workers=4)
    
    async def download_file(
        self,
        session: aiohttp.ClientSession,
        dataset: Dataset,
        progress: Progress,
        task_id
    ):
        """Download a single file with progress tracking"""
        
        filepath = self.data_dir / dataset.filename
        
        # Check if already downloaded
        if filepath.exists():
            console.print(f"[yellow]✓[/yellow] {dataset.name} already exists, skipping")
            progress.update(task_id, completed=100)
            return filepath
        
        try:
            async with session.get(dataset.url) as response:
                response.raise_for_status()
                total = int(response.headers.get('content-length', 0))
                
                downloaded = 0
                with open(filepath, 'wb') as f:
                    async for chunk in response.content.iter_chunked(8192):
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total:
                            progress.update(task_id, completed=(downloaded / total * 100))
                
                console.print(f"[green]✓[/green] Downloaded {dataset.name}")
                return filepath
                
        except Exception as e:
            console.print(f"[red]✗ Failed to download {dataset.name}: {e}[/red]")
            if filepath.exists():
                filepath.unlink()
            return None
    
    def extract_file(self, filepath: Path, dataset: Dataset):
        """Extract compressed files"""
        
        if not dataset.extract:
            return
        
        extract_dir = self.data_dir / dataset.name.lower().replace(' ', '_')
        extract_dir.mkdir(exist_ok=True)
        
        console.print(f"[cyan]Extracting {dataset.name}...[/cyan]")
        
        try:
            if dataset.format == 'zip':
                with zipfile.ZipFile(filepath, 'r') as zip_ref:
                    zip_ref.extractall(extract_dir)
            
            elif dataset.format == 'tar.gz':
                with tarfile.open(filepath, 'r:gz') as tar_ref:
                    tar_ref.extractall(extract_dir)
            
            elif dataset.format == 'gz':
                output = extract_dir / filepath.stem
                with gzip.open(filepath, 'rb') as f_in:
                    with open(output, 'wb') as f_out:
                        f_out.write(f_in.read())
            
            console.print(f"[green]✓[/green] Extracted to {extract_dir}")
            
        except Exception as e:
            console.print(f"[red]✗ Failed to extract {dataset.name}: {e}[/red]")
    
    async def download_datasets(self, dataset_names: List[str]):
        """Download multiple datasets in parallel"""
        
        datasets = [DATASETS[name] for name in dataset_names if name in DATASETS]
        
        if not datasets:
            console.print("[red]No valid datasets specified[/red]")
            return
        
        # Display what will be downloaded
        table = Table(title="Datasets to Download")
        table.add_column("Name", style="cyan")
        table.add_column("Description", style="green")
        table.add_column("Size (MB)", style="yellow")
        
        total_size = 0
        for ds in datasets:
            table.add_row(ds.name, ds.description, f"{ds.size_mb:.2f}")
            total_size += ds.size_mb
        
        table.add_row("", "TOTAL", f"[bold]{total_size:.2f}[/bold]")
        console.print(table)
        console.print()
        
        # Download with progress bars
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TimeElapsedColumn(),
            console=console
        ) as progress:
            
            async with aiohttp.ClientSession() as session:
                tasks = []
                for ds in datasets:
                    task_id = progress.add_task(f"[cyan]{ds.name}", total=100)
                    tasks.append(self.download_file(session, ds, progress, task_id))
                
                results = await asyncio.gather(*tasks)
        
        # Extract files
        console.print("\n[cyan]Extracting datasets...[/cyan]")
        for filepath, ds in zip(results, datasets):
            if filepath:
                self.extract_file(filepath, ds)
        
        console.print("\n[green]✓ All downloads complete![/green]")
    
    def list_datasets(self):
        """List all available datasets"""
        
        table = Table(title="Available Datasets")
        table.add_column("Name", style="cyan")
        table.add_column("Description", style="green")
        table.add_column("Size", style="yellow")
        table.add_column("Format", style="blue")
        
        for name, ds in DATASETS.items():
            table.add_row(name, ds.description, f"{ds.size_mb:.2f} MB", ds.format)
        
        console.print(table)
    
    def validate_dataset(self, dataset_name: str) -> bool:
        """Validate downloaded dataset"""
        
        if dataset_name not in DATASETS:
            return False
        
        dataset = DATASETS[dataset_name]
        filepath = self.data_dir / dataset.filename
        
        if not filepath.exists():
            return False
        
        # Validate checksum if provided
        if dataset.checksum:
            console.print(f"[cyan]Validating {dataset.name}...[/cyan]")
            with open(filepath, 'rb') as f:
                file_hash = hashlib.sha256(f.read()).hexdigest()
            
            if file_hash != dataset.checksum:
                console.print(f"[red]✗ Checksum mismatch for {dataset.name}[/red]")
                return False
        
        console.print(f"[green]✓ {dataset.name} is valid[/green]")
        return True
    
    def get_dataset_info(self, dataset_name: str):
        """Get detailed information about a dataset"""
        
        if dataset_name not in DATASETS:
            console.print(f"[red]Dataset '{dataset_name}' not found[/red]")
            return
        
        ds = DATASETS[dataset_name]
        extract_dir = self.data_dir / ds.name.lower().replace(' ', '_')
        
        console.print(f"\n[bold cyan]{ds.name}[/bold cyan]")
        console.print(f"Description: {ds.description}")
        console.print(f"Size: {ds.size_mb:.2f} MB")
        console.print(f"Format: {ds.format}")
        console.print(f"URL: {ds.url}")
        
        if extract_dir.exists():
            files = list(extract_dir.rglob('*'))
            console.print(f"\n[green]Downloaded: ✓[/green]")
            console.print(f"Files extracted: {len([f for f in files if f.is_file()])}")
            console.print(f"Location: {extract_dir}")
        else:
            console.print(f"\n[yellow]Not downloaded yet[/yellow]")


def main():
    """CLI interface for dataset downloader"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Intelligent Dataset Downloader")
    parser.add_argument("--list", action="store_true", help="List available datasets")
    parser.add_argument("--download", nargs='+', help="Download specific datasets")
    parser.add_argument("--all", action="store_true", help="Download all datasets")
    parser.add_argument("--info", help="Show dataset information")
    parser.add_argument("--validate", help="Validate downloaded dataset")
    parser.add_argument("--data-dir", default="./data/raw", help="Data directory")
    
    args = parser.parse_args()
    
    downloader = DatasetDownloader(args.data_dir)
    
    if args.list:
        downloader.list_datasets()
    
    elif args.download:
        asyncio.run(downloader.download_datasets(args.download))
    
    elif args.all:
        all_datasets = list(DATASETS.keys())
        asyncio.run(downloader.download_datasets(all_datasets))
    
    elif args.info:
        downloader.get_dataset_info(args.info)
    
    elif args.validate:
        downloader.validate_dataset(args.validate)
    
    else:
        parser.print_help()


if __name__ == "__main__":
    console.print(Panel.fit(
        "[bold cyan]Intelligent Dataset Downloader[/bold cyan]\n"
        "Download and manage ML datasets efficiently",
        border_style="cyan"
    ))
    
    main()
