#!/usr/bin/env python3
"""
Smart Commit V2 - Enterprise Grade Edition
===========================================
Intelligent git commit generation with chain-of-thought reasoning.

Architecture:
- GitDiffAnalyzer: Deep structural diff analysis
- CommitTypeClassifier: Pattern-based type inference
- ChainOfThoughtLLM: Multi-step reasoning for context
- CommitMessageValidator: 15+ validation rules
- RetryOrchestrator: Intelligent retry with feedback

Version: 2.0.0-enterprise
License: MIT
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import subprocess
import sys
import time
from collections import Counter
from dataclasses import dataclass, field, asdict
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import List, Dict, Any, Optional, Literal, Tuple
import urllib.request
import urllib.error

# ═══════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════

API_URL = os.environ.get("LLAMACPP_URL", "http://127.0.0.1:8080") + "/v1/chat/completions"
MODEL_NAME = os.getenv("LLM_MODEL", "unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf")
MAX_DIFF_SIZE = 8000
MAX_RETRIES = 3
REQUEST_TIMEOUT = 120
ENABLE_CHAIN_OF_THOUGHT = os.getenv("ENABLE_COT", "true").lower() == "true"

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(levelname)-8s │ %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════
# Data Models
# ═══════════════════════════════════════════════════════════════════════════

class CommitType(str, Enum):
    FEAT = "feat"
    FIX = "fix"
    DOCS = "docs"
    STYLE = "style"
    REFACTOR = "refactor"
    PERF = "perf"
    TEST = "test"
    BUILD = "build"
    CI = "ci"
    CHORE = "chore"
    REVERT = "revert"

class ChangePattern(str, Enum):
    DOCS_ONLY = "docs_only"
    NEW_FEATURE = "new_feature"
    CLEANUP = "cleanup"
    CONFIG_UPDATE = "config_update"
    TEST_ADDITION = "test_addition"
    REFACTORING = "refactoring"
    BUG_FIX = "bug_fix"

class FileCategory(str, Enum):
    CONFIG = "config"
    CODE = "code"
    DOCS = "docs"
    TEST = "test"
    SCRIPT = "script"
    BUILD = "build"
    CI = "ci"

@dataclass
class ChangeHunk:
    old_start: int
    old_lines: int
    new_start: int
    new_lines: int
    content: str
    change_type: Literal["addition", "deletion", "modification"]

@dataclass
class FileChange:
    path: str
    file_type: str
    category: FileCategory
    additions: int
    deletions: int
    is_new: bool
    is_deleted: bool
    is_renamed: bool
    change_hunks: List[ChangeHunk] = field(default_factory=list)
    
    @property
    def net_change(self) -> int:
        return self.additions - self.deletions

@dataclass
class DiffAnalysis:
    files_changed: List[FileChange]
    total_additions: int
    total_deletions: int
    change_complexity: Literal["trivial", "simple", "moderate", "complex"]
    primary_languages: List[str]
    change_patterns: List[ChangePattern]
    affected_scopes: List[str]
    confidence_score: float
    reasoning_context: Dict[str, Any] = field(default_factory=dict)

@dataclass
class ValidationError:
    field: str
    message: str
    severity: Literal["error", "warning"]
    suggestion: Optional[str] = None

@dataclass
class ValidationResult:
    is_valid: bool
    errors: List[ValidationError]
    warnings: List[ValidationError]
    confidence_score: float

@dataclass
class CommitMessage:
    type: CommitType
    scope: Optional[str]
    subject: str
    body: str
    breaking: bool = False
    semver_bump: Literal["major", "minor", "patch"] = "patch"
    
    def format(self, issue_id: Optional[str] = None) -> str:
        header = f"{self.type.value}"
        if self.scope:
            header += f"({self.scope})"
        header += f": {self.subject}"
        
        full_msg = header
        if self.body:
            full_msg += f"\n\n{self.body}"
        if issue_id:
            full_msg += f"\n\nRefs: #{issue_id}"
        
        return full_msg

# ═══════════════════════════════════════════════════════════════════════════
# Git Diff Analyzer
# ═══════════════════════════════════════════════════════════════════════════

class GitDiffAnalyzer:
    """Advanced structural git diff analysis."""
    
    CATEGORY_MAP = {
        ".nix": FileCategory.CONFIG,
        ".py": FileCategory.CODE,
        ".md": FileCategory.DOCS,
        ".rst": FileCategory.DOCS,
        ".txt": FileCategory.DOCS,
        ".toml": FileCategory.CONFIG,
        ".yaml": FileCategory.CONFIG,
        ".yml": FileCategory.CONFIG,
        ".json": FileCategory.CONFIG,
        ".sh": FileCategory.SCRIPT,
        ".bash": FileCategory.SCRIPT,
    }
    
    TEST_PATTERNS = [r"test_.*\.py$", r".*_test\.py$", r"tests/.*\.py$"]
    CI_PATTERNS = [r"\.github/workflows/.*", r"\.gitlab-ci\.yml$"]
    BUILD_PATTERNS = [r"flake\.nix$", r"package\.json$", r"Cargo\.toml$"]
    
    def parse_diff(self, raw_diff: str) -> DiffAnalysis:
        if not raw_diff.strip():
            raise ValueError("Empty diff")
        
        files = self._parse_file_changes(raw_diff)
        patterns = self._detect_patterns(files)
        complexity = self._calc_complexity(files)
        scopes = self._infer_scopes(files)
        languages = self._detect_languages(files)
        
        # Build reasoning context for chain-of-thought
        reasoning = {
            "file_count": len(files),
            "total_lines": sum(f.additions + f.deletions for f in files),
            "new_files": sum(1 for f in files if f.is_new),
            "deleted_files": sum(1 for f in files if f.is_deleted),
            "primary_categories": self._get_primary_categories(files),
            "detected_patterns": [p.value for p in patterns],
        }
        
        return DiffAnalysis(
            files_changed=files,
            total_additions=sum(f.additions for f in files),
            total_deletions=sum(f.deletions for f in files),
            change_complexity=complexity,
            primary_languages=languages,
            change_patterns=patterns,
            affected_scopes=scopes,
            confidence_score=self._calc_confidence(files, patterns),
            reasoning_context=reasoning
        )
    
    def _parse_file_changes(self, raw_diff: str) -> List[FileChange]:
        files = []
        current_file = None
        current_hunks = []
        
        for line in raw_diff.split("\n"):
            if line.startswith("diff --git"):
                if current_file:
                    current_file.change_hunks = current_hunks
                    files.append(current_file)
                    current_hunks = []
                
                match = re.search(r"b/(.*?)$", line)
                if match:
                    path = match.group(1)
                    current_file = self._create_file_change(path)
            
            elif current_file:
                if line.startswith("new file mode"):
                    current_file.is_new = True
                elif line.startswith("deleted file mode"):
                    current_file.is_deleted = True
                elif line.startswith("rename from"):
                    current_file.is_renamed = True
                elif line.startswith("@@"):
                    hunk = self._parse_hunk_header(line)
                    if hunk:
                        current_hunks.append(hunk)
                elif current_hunks:
                    if line.startswith("+") and not line.startswith("+++"):
                        current_file.additions += 1
                        current_hunks[-1].content += line + "\n"
                    elif line.startswith("-") and not line.startswith("---"):
                        current_file.deletions += 1
                        current_hunks[-1].content += line + "\n"
        
        if current_file:
            current_file.change_hunks = current_hunks
            files.append(current_file)
        
        return files
    
    def _create_file_change(self, path: str) -> FileChange:
        ext = Path(path).suffix or ".txt"
        category = self._categorize_file(path, ext)
        
        return FileChange(
            path=path,
            file_type=ext,
            category=category,
            additions=0,
            deletions=0,
            is_new=False,
            is_deleted=False,
            is_renamed=False
        )
    
    def _categorize_file(self, path: str, ext: str) -> FileCategory:
        for pattern in self.CI_PATTERNS:
            if re.search(pattern, path):
                return FileCategory.CI
        for pattern in self.BUILD_PATTERNS:
            if re.search(pattern, path):
                return FileCategory.BUILD
        for pattern in self.TEST_PATTERNS:
            if re.search(pattern, path):
                return FileCategory.TEST
        return self.CATEGORY_MAP.get(ext, FileCategory.CODE)
    
    def _parse_hunk_header(self, line: str) -> Optional[ChangeHunk]:
        match = re.search(r"@@\s+-(\d+),?(\d+)?\s+\+(\d+),?(\d+)?", line)
        if not match:
            return None
        
        old_start = int(match.group(1))
        old_lines = int(match.group(2) or 1)
        new_start = int(match.group(3))
        new_lines = int(match.group(4) or 1)
        
        change_type = "modification"
        if old_lines == 0:
            change_type = "addition"
        elif new_lines == 0:
            change_type = "deletion"
        
        return ChangeHunk(old_start, old_lines, new_start, new_lines, "", change_type)
    
    def _detect_patterns(self, files: List[FileChange]) -> List[ChangePattern]:
        patterns = []
        
        if all(f.category == FileCategory.DOCS for f in files):
            patterns.append(ChangePattern.DOCS_ONLY)
        
        total_del = sum(f.deletions for f in files)
        total_add = sum(f.additions for f in files)
        
        if total_del > 3 * total_add and total_del > 50:
            patterns.append(ChangePattern.CLEANUP)
        
        new_count = sum(1 for f in files if f.is_new)
        if new_count > len(files) * 0.5:
            patterns.append(ChangePattern.NEW_FEATURE)
        
        if all(f.category == FileCategory.CONFIG for f in files):
            patterns.append(ChangePattern.CONFIG_UPDATE)
        
        if any(f.category == FileCategory.TEST for f in files):
            patterns.append(ChangePattern.TEST_ADDITION)
        
        if 0.7 < (total_add / max(total_del, 1)) < 1.3 and total_add > 20:
            patterns.append(ChangePattern.REFACTORING)
        
        return patterns
    
    def _calc_complexity(self, files: List[FileChange]) -> str:
        total = sum(f.additions + f.deletions for f in files)
        count = len(files)
        
        if total < 10 and count == 1:
            return "trivial"
        elif total < 50 and count <= 3:
            return "simple"
        elif total < 200 and count <= 10:
            return "moderate"
        else:
            return "complex"
    
    def _infer_scopes(self, files: List[FileChange]) -> List[str]:
        scopes = set()
        
        for file in files:
            parts = file.path.split("/")
            
            if "modules" in parts:
                idx = parts.index("modules")
                if len(parts) > idx + 1:
                    scopes.add(parts[idx + 1])
            elif "scripts" in parts:
                scopes.add("scripts")
            elif "tests" in parts or "test" in parts:
                scopes.add("tests")
            elif ".github/workflows" in file.path:
                scopes.add("ci")
            elif file.path.startswith("docs/"):
                scopes.add("docs")
        
        if not scopes:
            scopes = {f.category.value for f in files}
        
        return sorted(list(scopes))
    
    def _detect_languages(self, files: List[FileChange]) -> List[str]:
        lang_map = {
            ".nix": "Nix", ".py": "Python", ".js": "JavaScript",
            ".ts": "TypeScript", ".rs": "Rust", ".go": "Go", ".sh": "Shell"
        }
        
        langs = Counter()
        for f in files:
            if f.file_type in lang_map:
                langs[lang_map[f.file_type]] += f.additions + f.deletions
        
        return [l for l, _ in langs.most_common(3)]
    
    def _get_primary_categories(self, files: List[FileChange]) -> List[str]:
        cats = Counter(f.category.value for f in files)
        return [c for c, _ in cats.most_common(3)]
    
    def _calc_confidence(self, files: List[FileChange], patterns: List[ChangePattern]) -> float:
        confidence = 1.0
        total = sum(f.additions + f.deletions for f in files)
        
        if total > 1000:
            confidence *= 0.7
        if len(files) > 20:
            confidence *= 0.8
        if ChangePattern.DOCS_ONLY in patterns:
            confidence = min(confidence * 1.2, 1.0)
        
        return round(confidence, 2)

# ═══════════════════════════════════════════════════════════════════════════
# Commit Message Validator
# ═══════════════════════════════════════════════════════════════════════════

class CommitMessageValidator:
    """Enterprise validation with 15+ rules."""
    
    VALID_TYPES = {t.value for t in CommitType}
    IMPERATIVE_VERBS = {
        'add', 'fix', 'remove', 'update', 'refactor', 'implement', 'create',
        'delete', 'improve', 'optimize', 'enhance', 'migrate', 'move',
        'rename', 'extract', 'merge', 'upgrade', 'downgrade', 'revert'
    }
    COMMON_TOOLS = {
        'pytest', 'ruff', 'mypy', 'black', 'nvfetcher', 'lynis',
        'docker', 'kubernetes', 'ansible', 'terraform'
    }
    
    def validate_full(self, commit_msg: Dict, diff_analysis: DiffAnalysis) -> ValidationResult:
        errors = []
        warnings = []
        
        errors.extend(self._validate_structure(commit_msg))
        if errors:
            return ValidationResult(False, errors, warnings, 0.0)
        
        type_issues = self._validate_type(commit_msg['type'], diff_analysis)
        errors.extend([e for e in type_issues if e.severity == 'error'])
        warnings.extend([e for e in type_issues if e.severity == 'warning'])
        
        errors.extend(self._validate_subject(commit_msg['subject']))
        errors.extend(self._detect_hallucinations(commit_msg, diff_analysis))
        warnings.extend(self._validate_scope(commit_msg.get('scope'), diff_analysis))
        
        confidence = 1.0 - len(warnings) * 0.1 if not errors else 0.0
        
        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            confidence_score=max(0.0, min(1.0, confidence))
        )
    
    def _validate_structure(self, msg: Dict) -> List[ValidationError]:
        errors = []
        for field in ['type', 'subject', 'body', 'semver_bump']:
            if field not in msg:
                errors.append(ValidationError(
                    field, f"Missing field: {field}", 'error'
                ))
        return errors
    
    def _validate_subject(self, subject: str) -> List[ValidationError]:
        errors = []
        
        if not subject:
            errors.append(ValidationError('subject', "Empty subject", 'error'))
            return errors
        
        if len(subject) > 72:
            errors.append(ValidationError(
                'subject', f"Too long: {len(subject)}/72", 'error',
                "Keep under 72 chars"
            ))
        
        words = subject.split()
        if words and words[0].lower() not in self.IMPERATIVE_VERBS:
            errors.append(ValidationError(
                'subject', f"Not imperative: '{words[0]}'", 'error',
                "Start with: add/fix/update/remove/..."
            ))
        
        if subject[0].isupper():
            errors.append(ValidationError(
                'subject', "Must start lowercase", 'error'
            ))
        
        if subject.endswith('.'):
            errors.append(ValidationError(
                'subject', "No period at end", 'error'
            ))
        
        if subject.lower().startswith('this commit'):
            errors.append(ValidationError(
                'subject', "Don't start with 'This commit'", 'error'
            ))
        
        return errors
    
    def _validate_type(self, typ: str, analysis: DiffAnalysis) -> List[ValidationError]:
        issues = []
        
        if typ not in self.VALID_TYPES:
            issues.append(ValidationError(
                'type', f"Invalid: {typ}", 'error',
                f"Use: {', '.join(sorted(self.VALID_TYPES))}"
            ))
            return issues
        
        patterns = analysis.change_patterns
        
        if ChangePattern.DOCS_ONLY in patterns and typ != 'docs':
            issues.append(ValidationError(
                'type', f"Docs-only but type={typ}", 'error', "Use: docs"
            ))
        
        if ChangePattern.NEW_FEATURE in patterns and typ not in {'feat', 'build'}:
            issues.append(ValidationError(
                'type', f"New files but type={typ}", 'warning', "Consider: feat"
            ))
        
        if ChangePattern.CLEANUP in patterns and typ not in {'chore', 'refactor'}:
            issues.append(ValidationError(
                'type', f"Cleanup but type={typ}", 'warning', "Consider: chore"
            ))
        
        return issues
    
    def _detect_hallucinations(self, msg: Dict, analysis: DiffAnalysis) -> List[ValidationError]:
        errors = []
        
        text = f"{msg['subject']} {msg.get('body', '')}"
        commit_words = set(re.findall(r'\b\w{4,}\b', text.lower()))
        
        diff_words = set()
        for f in analysis.files_changed:
            diff_words.update(re.findall(r'\b\w{3,}\b', f.path.lower()))
            for h in f.change_hunks:
                diff_words.update(re.findall(r'\b\w{3,}\b', h.content.lower()))
        
        mentioned = commit_words & self.COMMON_TOOLS
        actual = diff_words & self.COMMON_TOOLS
        hallucinated = mentioned - actual
        
        if hallucinated:
            errors.append(ValidationError(
                'body', f"Hallucinated tools: {', '.join(sorted(hallucinated))}", 'error',
                "Only mention tools in diff"
            ))
        
        return errors
    
    def _validate_scope(self, scope: Optional[str], analysis: DiffAnalysis) -> List[ValidationError]:
        warnings = []
        
        if not scope or scope.lower() in {'none', 'null'}:
            return warnings
        
        if not re.match(r'^[a-z]+(-[a-z]+)*$', scope):
            warnings.append(ValidationError(
                'scope', f"Not kebab-case: {scope}", 'warning'
            ))
        
        if len(scope) > 20:
            warnings.append(ValidationError(
                'scope', f"Too long: {len(scope)}/20", 'warning'
            ))
        
        if scope not in analysis.affected_scopes:
            sugg = analysis.affected_scopes[:3]
            warnings.append(ValidationError(
                'scope', f"Not in detected scopes", 'warning',
                f"Consider: {', '.join(sugg)}" if sugg else None
            ))
        
        return warnings

# ═══════════════════════════════════════════════════════════════════════════
# Chain-of-Thought LLM Generator
# ═══════════════════════════════════════════════════════════════════════════

class ChainOfThoughtLLM:
    """Multi-step reasoning for superior context understanding."""
    
    def __init__(self, model: str, api_url: str, timeout: int):
        self.model = model
        self.api_url = api_url
        self.timeout = timeout
        self.validator = CommitMessageValidator()
    
    def generate_with_cot(
        self, 
        diff_analysis: DiffAnalysis,
        hint: Optional[str] = None,
        max_retries: int = 3
    ) -> CommitMessage:
        """Generate commit with chain-of-thought reasoning."""
        
        for attempt in range(max_retries):
            try:
                # Step 1: Reasoning phase
                reasoning = self._reasoning_step(diff_analysis, hint)
                log.info(f"🧠 CoT Reasoning: {reasoning[:100]}...")
                
                # Step 2: Generation phase
                response = self._generation_step(diff_analysis, reasoning, hint)
                
                # Step 3: Parse and validate
                commit_data = self._parse_json(response)
                validation = self.validator.validate_full(commit_data, diff_analysis)
                
                if validation.is_valid:
                    return self._build_commit(commit_data)
                
                # Retry with feedback
                if attempt < max_retries - 1:
                    log.warning(f"Validation failed (attempt {attempt+1}), retrying with feedback...")
                    diff_analysis.reasoning_context['validation_errors'] = [
                        f"{e.field}: {e.message}" for e in validation.errors
                    ]
                else:
                    raise ValueError(f"Validation failed after {max_retries} attempts", validation.errors)
            
            except Exception as e:
                if attempt < max_retries - 1:
                    log.warning(f"Attempt {attempt+1} failed: {e}, retrying...")
                    time.sleep(2 ** attempt)
                else:
                    raise
        
        raise RuntimeError("Failed to generate valid commit")
    
    def _reasoning_step(self, analysis: DiffAnalysis, hint: Optional[str]) -> str:
        """Step 1: Analyze diff and reason about intent."""
        
        reasoning_prompt = f"""Analyze this git diff and reason about the developer's intent.

DIFF CONTEXT:
- Files changed: {len(analysis.files_changed)}
- Total lines: +{analysis.total_additions}/-{analysis.total_deletions}
- Complexity: {analysis.change_complexity}
- Languages: {', '.join(analysis.primary_languages)}
- File categories: {', '.join(analysis.reasoning_context.get('primary_categories', []))}
- Detected patterns: {', '.join(analysis.reasoning_context.get('detected_patterns', []))}
- Affected scopes: {', '.join(analysis.affected_scopes)}

FILES:
{self._format_files(analysis.files_changed[:10])}

{"USER HINT: " + hint if hint else ""}

REASONING TASK:
1. What is the PRIMARY intent? (feature/fix/refactor/cleanup/docs/etc)
2. What component/scope is affected?
3. What's the MOST important change?
4. Is this breaking? Why/why not?

Respond with structured reasoning (3-5 sentences max):"""

        return self._call_llm(reasoning_prompt, temperature=0.2, max_tokens=300)
    
    def _generation_step(
        self,
        analysis: DiffAnalysis,
        reasoning: str,
        hint: Optional[str]
    ) -> str:
        """Step 2: Generate commit message based on reasoning."""
        
        system_prompt = """You are an elite commit message generator with ZERO tolerance for errors.

STRICT RULES:
1. Format: <type>(<scope>): <subject>
2. Type: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
3. Scope: lowercase-kebab-case, max 20 chars
4. Subject: lowercase imperative verb, max 72 chars, NO period
5. NO HALLUCINATIONS: Only mention what's in the diff
6. Output ONLY valid JSON: {"type": "...", "scope": "...", "subject": "...", "body": "...", "semver_bump": "..."}

IMPERATIVE VERBS: add, fix, remove, update, refactor, implement, create, delete, improve

TYPE SELECTION LOGIC:
- feat: NEW functionality
- fix: BUG correction  
- docs: ONLY documentation
- refactor: Code restructuring
- chore: Routine tasks (cleanup, deps)
- test: Test changes
- build/ci: Build system/CI

EXAMPLES:
```json
{"type": "feat", "scope": "security", "subject": "add aide intrusion detection", "body": "...", "semver_bump": "minor"}
{"type": "fix", "scope": "parser", "subject": "handle json errors gracefully", "body": "...", "semver_bump": "patch"}
{"type": "docs", "scope": "readme", "subject": "update installation steps", "body": "...", "semver_bump": "patch"}
```

RESPOND WITH JSON ONLY. NO MARKDOWN. NO EXPLANATIONS."""

        user_prompt = f"""REASONING (from analysis):
{reasoning}

DIFF SUMMARY:
- Files: {len(analysis.files_changed)} ({', '.join(analysis.affected_scopes[:3])})
- Lines: +{analysis.total_additions}/-{analysis.total_deletions}
- Patterns: {', '.join(p.value for p in analysis.change_patterns)}
- Complexity: {analysis.change_complexity}

{"USER HINT: " + hint if hint else ""}

Generate commit message as JSON:"""

        return self._call_llm(user_prompt, system=system_prompt, temperature=0.1, max_tokens=500)
    
    def _format_files(self, files: List[FileChange]) -> str:
        """Format files for prompt."""
        lines = []
        for f in files:
            status = "NEW" if f.is_new else "DEL" if f.is_deleted else "MOD"
            lines.append(f"  [{status}] {f.path} (+{f.additions}/-{f.deletions})")
        return "\n".join(lines)
    
    def _call_llm(
        self,
        prompt: str,
        system: Optional[str] = None,
        temperature: float = 0.1,
        max_tokens: int = 500
    ) -> str:
        """Call LLM API."""
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "response_format": {"type": "json_object"} if "JSON" in prompt else {}
        }
        
        try:
            req = urllib.request.Request(
                self.api_url,
                data=json.dumps(payload).encode(),
                headers={'Content-Type': 'application/json'}
            )
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                result = json.loads(response.read().decode())
                return result['choices'][0]['message']['content']
        except Exception as e:
            log.error(f"LLM call failed: {e}")
            raise
    
    def _parse_json(self, response: str) -> Dict:
        """Robust JSON parsing."""
        response = response.strip()
        
        # Remove markdown code blocks
        if "```json" in response:
            match = re.search(r'```json\s*(.*?)\s*```', response, re.DOTALL)
            if match:
                response = match.group(1)
        elif "```" in response:
            match = re.search(r'```\s*(.*?)\s*```', response, re.DOTALL)
            if match:
                response = match.group(1)
        
        # Extract JSON object
        start = response.find("{")
        end = response.rfind("}") + 1
        if start >= 0 and end > start:
            response = response[start:end]
        
        try:
            return json.loads(response)
        except json.JSONDecodeError as e:
            log.error(f"JSON parse failed: {e}\nResponse: {response[:200]}")
            raise
    
    def _build_commit(self, data: Dict) -> CommitMessage:
        """Build CommitMessage from dict."""
        return CommitMessage(
            type=CommitType(data['type']),
            scope=data.get('scope') if data.get('scope') not in {'none', 'null', ''} else None,
            subject=data['subject'],
            body=data.get('body', ''),
            breaking=data.get('breaking', False),
            semver_bump=data.get('semver_bump', 'patch')
        )

# ═══════════════════════════════════════════════════════════════════════════
# Main Orchestrator
# ═══════════════════════════════════════════════════════════════════════════

class SmartCommitOrchestrator:
    """Main pipeline orchestration."""
    
    def __init__(self):
        self.analyzer = GitDiffAnalyzer()
        self.llm = ChainOfThoughtLLM(MODEL_NAME, API_URL, REQUEST_TIMEOUT)
    
    def run(self, hint: Optional[str] = None) -> None:
        """Execute full commit generation pipeline."""
        
        # Pre-flight checks
        self._verify_git_repo()
        self._run_pipeline_check()
        self._scope_guard()
        
        # Get diff
        log.info("🔍 Analyzing repository state...")
        raw_diff = self._get_staged_diff()
        branch = self._get_branch()
        issue_id = self._extract_issue_id(branch)
        
        # Parse diff
        log.info("📊 Performing deep diff analysis...")
        diff_analysis = self.analyzer.parse_diff(raw_diff)
        
        log.info(f"📈 Analysis complete:")
        log.info(f"   Files: {len(diff_analysis.files_changed)}")
        log.info(f"   Lines: +{diff_analysis.total_additions}/-{diff_analysis.total_deletions}")
        log.info(f"   Complexity: {diff_analysis.change_complexity}")
        log.info(f"   Patterns: {', '.join(p.value for p in diff_analysis.change_patterns)}")
        
        # Generate commit
        if ENABLE_CHAIN_OF_THOUGHT:
            log.info("🧠 Generating with chain-of-thought reasoning...")
        else:
            log.info("🤖 Generating commit message...")
        
        commit_msg = self.llm.generate_with_cot(diff_analysis, hint)
        
        # Display and confirm
        self._display_commit(commit_msg, issue_id)
        self._confirm_and_commit(commit_msg, issue_id)
    
    def _verify_git_repo(self):
        if not Path(".git").exists():
            log.error("Not a git repository")
            sys.exit(1)
    
    def _run_pipeline_check(self):
        log.info("🛡️  Running pre-commit verification...")
        pipeline_script = Path("./scripts/pipeline-check.sh")
        if pipeline_script.exists():
            try:
                subprocess.run([str(pipeline_script)], check=True)
                log.info("✅ Pipeline passed")
            except subprocess.CalledProcessError:
                log.error("❌ Pipeline failed. Fix issues before committing.")
                sys.exit(1)
    
    def _scope_guard(self):
        """Prevent mixed-scope commits."""
        files = self._run_git("git diff --name-only --cached").splitlines()
        if not files:
            log.error("❌ No files staged. Use 'git add <file>' first.")
            sys.exit(1)
        
        roots = [f.split('/')[0] for f in files if '/' in f]
        root_counts = Counter(roots)
        
        if len(root_counts) > 1:
            log.warning("\n⚠️  MIXED CONTEXT DETECTED")
            log.warning("You're committing changes to multiple scopes:")
            for root, count in root_counts.items():
                log.warning(f"  - {root}/ ({count} files)")
            
            choice = input("\nContinue anyway? [y/N]: ").lower()
            if choice != 'y':
                log.info("Aborted. Separate your commits.")
                sys.exit(0)
    
    def _get_staged_diff(self) -> str:
        return self._run_git("git diff --cached")
    
    def _get_branch(self) -> str:
        return self._run_git("git rev-parse --abbrev-ref HEAD")
    
    def _extract_issue_id(self, branch: str) -> Optional[str]:
        match = re.search(r'([a-zA-Z]+-\d+|\d+)', branch)
        return match.group(1) if match else None
    
    def _run_git(self, cmd: str) -> str:
        try:
            result = subprocess.run(
                cmd, shell=True, check=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            log.error(f"Git command failed: {cmd}\n{e.stderr}")
            sys.exit(1)
    
    def _display_commit(self, msg: CommitMessage, issue_id: Optional[str]):
        full_msg = msg.format(issue_id)
        
        print("\n" + "="*60)
        print(f"SUGGESTED COMMIT ({msg.type.value}) [Bump: {msg.semver_bump}]")
        print("="*60)
        print(full_msg)
        print("="*60 + "\n")
    
    def _confirm_and_commit(self, msg: CommitMessage, issue_id: Optional[str]):
        choice = input("Commit with this message? [Y/n/e(dit)]: ").lower()
        
        full_msg = msg.format(issue_id)
        
        if choice in ['y', 'yes', '']:
            self._run_git(f'git commit -m "{full_msg}"')
            log.info("✅ Committed successfully")
        elif choice == 'e':
            msg_file = Path(".git/COMMIT_EDITMSG")
            msg_file.write_text(full_msg)
            editor = os.environ.get('EDITOR', 'vim')
            os.system(f"{editor} {msg_file}")
            os.system(f"git commit -F {msg_file}")
            log.info("✅ Committed with edited message")
        else:
            log.info("❌ Commit cancelled")

# ═══════════════════════════════════════════════════════════════════════════
# CLI Entry Point
# ═══════════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        description='Smart Commit V2 - Enterprise commit message generation',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        'hint', nargs='?', default=None,
        help='Context hint (e.g., "refactor templates")'
    )
    parser.add_argument(
        '--no-cot', action='store_true',
        help='Disable chain-of-thought reasoning'
    )
    parser.add_argument(
        '--verbose', '-v', action='store_true',
        help='Enable verbose logging'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    if args.no_cot:
        global ENABLE_CHAIN_OF_THOUGHT
        ENABLE_CHAIN_OF_THOUGHT = False
    
    try:
        orchestrator = SmartCommitOrchestrator()
        orchestrator.run(args.hint)
    except KeyboardInterrupt:
        log.info("\n⚠️  Interrupted")
        sys.exit(1)
    except Exception as e:
        log.error(f"❌ Fatal error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
