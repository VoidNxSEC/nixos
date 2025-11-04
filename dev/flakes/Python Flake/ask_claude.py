#!/usr/bin/env python3
"""
Advanced LLM Integration Script
Integrates with Claude API, supports streaming, function calling, and RAG
"""

import os
import sys
import json
from typing import List, Dict, Any, Optional
from pathlib import Path
import anthropic
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel
import chromadb
from chromadb.config import Settings

console = Console()


class LLMOrchestrator:
    """Advanced LLM orchestrator with RAG and function calling"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("ANTHROPIC_API_KEY")
        if not self.api_key:
            console.print("[red]Error: ANTHROPIC_API_KEY not set[/red]")
            sys.exit(1)
            
        self.client = anthropic.Anthropic(api_key=self.api_key)
        self.model = "claude-sonnet-4-20250514"
        
        # Setup ChromaDB for RAG
        self.chroma_client = chromadb.Client(Settings(
            chroma_db_impl="duckdb+parquet",
            persist_directory="./chroma_db"
        ))
        
        try:
            self.collection = self.chroma_client.get_collection("knowledge_base")
        except:
            self.collection = self.chroma_client.create_collection("knowledge_base")
    
    def add_to_knowledge_base(self, text: str, metadata: Dict[str, Any]):
        """Add document to vector database"""
        self.collection.add(
            documents=[text],
            metadatas=[metadata],
            ids=[f"doc_{len(self.collection.get()['ids'])}"]
        )
        console.print(f"[green]✓[/green] Added to knowledge base")
    
    def query_knowledge_base(self, query: str, n_results: int = 3) -> List[str]:
        """Query vector database for relevant context"""
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results
        )
        return results['documents'][0] if results['documents'] else []
    
    def chat(
        self,
        prompt: str,
        system: Optional[str] = None,
        use_rag: bool = False,
        stream: bool = True,
        max_tokens: int = 4096
    ):
        """Chat with Claude, optionally using RAG"""
        
        # Get relevant context if RAG enabled
        context = ""
        if use_rag:
            docs = self.query_knowledge_base(prompt)
            if docs:
                context = "\n\n".join([f"Context {i+1}:\n{doc}" for i, doc in enumerate(docs)])
                console.print(Panel(f"[cyan]Using {len(docs)} context documents[/cyan]"))
        
        # Build messages
        messages = [{
            "role": "user",
            "content": f"{context}\n\n{prompt}" if context else prompt
        }]
        
        # Stream response
        if stream:
            console.print("\n[bold cyan]Claude:[/bold cyan]\n")
            with self.client.messages.stream(
                model=self.model,
                max_tokens=max_tokens,
                messages=messages,
                system=system
            ) as stream:
                response_text = ""
                for text in stream.text_stream:
                    console.print(text, end="")
                    response_text += text
                console.print("\n")
                return response_text
        else:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=max_tokens,
                messages=messages,
                system=system
            )
            return response.content[0].text
    
    def analyze_code(self, code: str, language: str = "python"):
        """Analyze code for bugs, security issues, and improvements"""
        system = """You are an expert code reviewer and security analyst.
        Analyze the provided code for:
        1. Bugs and logic errors
        2. Security vulnerabilities
        3. Performance issues
        4. Code quality and best practices
        5. Suggestions for improvement"""
        
        prompt = f"""Analyze this {language} code:

```{language}
{code}
```

Provide a detailed analysis."""
        
        return self.chat(prompt, system=system, stream=False)
    
    def explain_assembly(self, assembly: str, architecture: str = "x86_64"):
        """Explain assembly code in detail"""
        system = f"""You are an expert in {architecture} assembly language and reverse engineering.
        Explain assembly code in detail, including what each instruction does."""
        
        prompt = f"""Explain this {architecture} assembly code:

```asm
{assembly}
```"""
        
        return self.chat(prompt, system=system)
    
    def generate_exploit(self, vulnerability_description: str):
        """Generate exploit code based on vulnerability description"""
        system = """You are a security researcher helping to understand vulnerabilities.
        Generate proof-of-concept exploit code for educational and defensive purposes only."""
        
        console.print("[yellow]⚠️  Generating exploit for educational purposes only[/yellow]")
        
        prompt = f"""Generate a proof-of-concept exploit for this vulnerability:

{vulnerability_description}

Include:
1. Explanation of the vulnerability
2. Step-by-step exploit strategy
3. Python exploit code
4. Mitigation recommendations"""
        
        return self.chat(prompt, system=system)


def main():
    """CLI interface for LLM orchestrator"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Advanced LLM Integration")
    parser.add_argument("--mode", choices=["chat", "analyze", "asm", "exploit", "add-knowledge"],
                       default="chat", help="Operation mode")
    parser.add_argument("--prompt", type=str, help="Input prompt or question")
    parser.add_argument("--file", type=Path, help="Input file path")
    parser.add_argument("--language", default="python", help="Programming language")
    parser.add_argument("--arch", default="x86_64", help="Architecture for assembly")
    parser.add_argument("--rag", action="store_true", help="Use RAG")
    parser.add_argument("--system", type=str, help="System prompt")
    
    args = parser.parse_args()
    
    orchestrator = LLMOrchestrator()
    
    # Read from file if provided
    content = ""
    if args.file:
        content = args.file.read_text()
    
    if args.mode == "chat":
        prompt = args.prompt or input("You: ")
        response = orchestrator.chat(prompt, system=args.system, use_rag=args.rag)
        
    elif args.mode == "analyze":
        code = content or args.prompt
        if not code:
            console.print("[red]Error: Provide code via --file or --prompt[/red]")
            sys.exit(1)
        
        console.print(Panel("[cyan]Analyzing code...[/cyan]"))
        analysis = orchestrator.analyze_code(code, args.language)
        console.print(Markdown(analysis))
        
    elif args.mode == "asm":
        asm = content or args.prompt
        if not asm:
            console.print("[red]Error: Provide assembly via --file or --prompt[/red]")
            sys.exit(1)
        
        console.print(Panel("[cyan]Explaining assembly...[/cyan]"))
        explanation = orchestrator.explain_assembly(asm, args.arch)
        
    elif args.mode == "exploit":
        vuln = content or args.prompt
        if not vuln:
            console.print("[red]Error: Provide vulnerability description[/red]")
            sys.exit(1)
        
        exploit = orchestrator.generate_exploit(vuln)
        
    elif args.mode == "add-knowledge":
        if not args.file:
            console.print("[red]Error: Provide file with --file[/red]")
            sys.exit(1)
        
        orchestrator.add_to_knowledge_base(
            content,
            {"source": str(args.file), "type": "document"}
        )


if __name__ == "__main__":
    # Example usage
    console.print(Panel.fit(
        "[bold cyan]Advanced LLM Integration[/bold cyan]\n"
        "Integrates Claude with RAG, code analysis, and more",
        border_style="cyan"
    ))
    
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        import traceback
        console.print(traceback.format_exc())
        sys.exit(1)
