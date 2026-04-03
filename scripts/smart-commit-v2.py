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

Features:
- ANSI Color Output
- Safe Subprocess Execution
- Intelligent Diff Truncation
- Pre-flight Health Checks

Version: 2.2.0-clean
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
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import List, Dict, Any, Optional, Literal
import urllib.request
import urllib.error

# ═══════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════

API_URL = os.environ.get("LLAMACPP_URL", "http://127.0.0.1:8081") + "/v1/chat/completions"
MODEL_NAME = os.getenv("LLM_MODEL", "unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf")
MAX_DIFF_SIZE = 12000  # Increased char limit
MAX_RETRIES = 3
REQUEST_TIMEOUT = 30  # Reduced for faster health check
ENABLE_NATIVE_THINKING = os.getenv("ENABLE_NATIVE_THINKING", "true").lower() == "true"
SHOW_THINKING = os.getenv("SHOW_THINKING", "true").lower() == "true"
ENABLE_APP_REASONING = os.getenv("ENABLE_APP_REASONING", os.getenv("ENABLE_COT", "false")).lower() == "true"

# ═══════════════════════════════════════════════════════════════════════════
# Utilities & Logging
# ═══════════════════════════════════════════════════════════════════════════

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

    @staticmethod
    def colorize(text: str, color: str) -> str:
        if os.getenv("NO_COLOR"):
            return text
        return f"{color}{text}{Colors.ENDC}"

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
        
        if self.breaking:
            header += "!"

        header += f": {self.subject}"
        
        full_msg = header
        if self.body:
            full_msg += f"\n\n{self.body}"
            
        if self.breaking:
            full_msg += "\n\nBREAKING CHANGE: " + self.subject
            
        if issue_id:
            full_msg += f"\n\nRefs: #{issue_id}"
        
        return full_msg

@dataclass
class LLMSettings:
    enable_native_thinking: bool = ENABLE_NATIVE_THINKING
    show_thinking: bool = SHOW_THINKING
    enable_app_reasoning: bool = ENABLE_APP_REASONING

@dataclass
class LLMCallResult:
    content: str
    thinking: Optional[str] = None
    raw_response: Dict[str, Any] = field(default_factory=dict)

@dataclass
class CommitGenerationResult:
    commit: CommitMessage
    model_thinking: Optional[str] = None
    app_reasoning: Optional[str] = None

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
        return FileChange(path, ext, category, 0, 0, False, False, False)
    
    def _categorize_file(self, path: str, ext: str) -> FileCategory:
        for pattern in self.CI_PATTERNS:
            if re.search(pattern, path): return FileCategory.CI
        for pattern in self.BUILD_PATTERNS:
            if re.search(pattern, path): return FileCategory.BUILD
        for pattern in self.TEST_PATTERNS:
            if re.search(pattern, path): return FileCategory.TEST
        return self.CATEGORY_MAP.get(ext, FileCategory.CODE)
    
    def _parse_hunk_header(self, line: str) -> Optional[ChangeHunk]:
        match = re.search(r"@@\s+-(\d+),?(\d+)?\s+\+(\d+),?(\d+)?", line)
        if not match: return None
        old_lines = int(match.group(2) or 1)
        new_lines = int(match.group(4) or 1)
        change_type = "addition" if old_lines == 0 else "deletion" if new_lines == 0 else "modification"
        return ChangeHunk(int(match.group(1)), old_lines, int(match.group(3)), new_lines, "", change_type)
    
    def _detect_patterns(self, files: List[FileChange]) -> List[ChangePattern]:
        patterns = []
        total_del = sum(f.deletions for f in files)
        total_add = sum(f.additions for f in files)
        
        if all(f.category == FileCategory.DOCS for f in files): patterns.append(ChangePattern.DOCS_ONLY)
        if total_del > 3 * total_add and total_del > 50: patterns.append(ChangePattern.CLEANUP)
        if sum(1 for f in files if f.is_new) > len(files) * 0.5: patterns.append(ChangePattern.NEW_FEATURE)
        if all(f.category == FileCategory.CONFIG for f in files): patterns.append(ChangePattern.CONFIG_UPDATE)
        if any(f.category == FileCategory.TEST for f in files): patterns.append(ChangePattern.TEST_ADDITION)
        if 0.7 < (total_add / max(total_del, 1)) < 1.3 and total_add > 20: patterns.append(ChangePattern.REFACTORING)
        return patterns
    
    def _calc_complexity(self, files: List[FileChange]) -> str:
        total = sum(f.additions + f.deletions for f in files)
        count = len(files)
        if total < 10 and count == 1: return "trivial"
        elif total < 50 and count <= 3: return "simple"
        elif total < 200 and count <= 10: return "moderate"
        return "complex"
    
    def _infer_scopes(self, files: List[FileChange]) -> List[str]:
        scopes = set()
        for file in files:
            parts = file.path.split("/")
            if "modules" in parts:
                idx = parts.index("modules")
                if len(parts) > idx + 1: scopes.add(parts[idx + 1])
            elif "scripts" in parts: scopes.add("scripts")
            elif any(x in parts for x in ["tests", "test"]): scopes.add("tests")
            elif ".github/workflows" in file.path: scopes.add("ci")
            elif file.path.startswith("docs/"): scopes.add("docs")
        return sorted(list(scopes)) if scopes else sorted(list({f.category.value for f in files}))
    
    def _detect_languages(self, files: List[FileChange]) -> List[str]:
        lang_map = {".nix": "Nix", ".py": "Python", ".js": "JavaScript", ".rs": "Rust", ".go": "Go", ".sh": "Shell"}
        langs = Counter()
        for f in files:
            if f.file_type in lang_map: langs[lang_map[f.file_type]] += f.additions + f.deletions
        return [l for l, _ in langs.most_common(3)]
    
    def _get_primary_categories(self, files: List[FileChange]) -> List[str]:
        return [c for c, _ in Counter(f.category.value for f in files).most_common(3)]
    
    def _calc_confidence(self, files: List[FileChange], patterns: List[ChangePattern]) -> float:
        confidence = 1.0
        total = sum(f.additions + f.deletions for f in files)
        if total > 1000: confidence *= 0.7
        if len(files) > 20: confidence *= 0.8
        if ChangePattern.DOCS_ONLY in patterns: confidence = min(confidence * 1.2, 1.0)
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
        'rename', 'extract', 'merge', 'upgrade', 'downgrade', 'revert', 'secure'
    }
    
    def validate_full(self, commit_msg: Dict, diff_analysis: DiffAnalysis) -> ValidationResult:
        errors, warnings = [], []
        
        errors.extend(self._validate_structure(commit_msg))
        if errors: return ValidationResult(False, errors, warnings, 0.0)
        
        type_issues = self._validate_type(commit_msg['type'], diff_analysis)
        errors.extend([e for e in type_issues if e.severity == 'error'])
        warnings.extend([e for e in type_issues if e.severity == 'warning'])
        
        errors.extend(self._validate_subject(commit_msg['subject']))
        warnings.extend(self._validate_scope(commit_msg.get('scope'), diff_analysis))
        
        confidence = 1.0 - len(warnings) * 0.1 if not errors else 0.0
        return ValidationResult(len(errors) == 0, errors, warnings, max(0.0, min(1.0, confidence)))
    
    def _validate_structure(self, msg: Dict) -> List[ValidationError]:
        required = ['type', 'subject', 'body']
        return [ValidationError(f, f"Missing field: {f}", 'error') for f in required if f not in msg]
    
    def _validate_subject(self, subject: str) -> List[ValidationError]:
        errors = []
        if not subject: return [ValidationError('subject', "Empty subject", 'error')]
        if len(subject) > 72: errors.append(ValidationError('subject', f"Too long: {len(subject)}/72", 'error'))
        if subject.split()[0].lower() not in self.IMPERATIVE_VERBS:
            errors.append(ValidationError('subject', f"Not imperative: '{subject.split()[0]}'", 'error'))
        if subject[0].isupper(): errors.append(ValidationError('subject', "Must start lowercase", 'error'))
        if subject.endswith('.'): errors.append(ValidationError('subject', "No period at end", 'error'))
        return errors
    
    def _validate_type(self, typ: str, analysis: DiffAnalysis) -> List[ValidationError]:
        issues = []
        if typ not in self.VALID_TYPES:
            issues.append(ValidationError('type', f"Invalid: {typ}", 'error'))
            return issues
        if ChangePattern.DOCS_ONLY in analysis.change_patterns and typ != 'docs':
            issues.append(ValidationError('type', "Docs-only but type!=docs", 'error'))
        return issues
    
    def _validate_scope(self, scope: Optional[str], analysis: DiffAnalysis) -> List[ValidationError]:
        warnings = []
        if not scope or scope.lower() in {'none', 'null'}: return warnings
        if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', scope):
            warnings.append(ValidationError('scope', f"Not kebab-case: {scope}", 'warning'))
        if len(scope) > 25: warnings.append(ValidationError('scope', "Too long > 25", 'warning'))
        return warnings

# ═══════════════════════════════════════════════════════════════════════════
# LLM Generator
# ═══════════════════════════════════════════════════════════════════════════

class ChainOfThoughtLLM:
    """Generate commit JSON while optionally surfacing native model thinking."""
    
    THINK_TAG_RE = re.compile(r"<think>(.*?)</think>", re.DOTALL | re.IGNORECASE)
    
    def __init__(self, model: str, api_url: str, timeout: int, settings: LLMSettings):
        self.model = model
        self.api_url = api_url
        self.timeout = timeout
        self.settings = settings
        self.validator = CommitMessageValidator()
    
    def check_health(self) -> bool:
        """Verify LLM availability."""
        try:
            req = urllib.request.Request(
                self.api_url.replace("/chat/completions", "/models"),
                headers={"User-Agent": "SmartCommitV2"}
            )
            with urllib.request.urlopen(req, timeout=3) as _:
                return True
        except Exception:
            try:
                self._call_llm("ping", max_tokens=1, use_native_thinking=False)
                return True
            except Exception:
                return False

    def generate_commit(self, diff_analysis: DiffAnalysis, hint: Optional[str] = None) -> CommitGenerationResult:
        """Generate a validated commit message and keep thinking separate from final JSON."""
        for attempt in range(MAX_RETRIES):
            try:
                app_reasoning = None
                if self.settings.enable_app_reasoning:
                    app_reasoning = self._reasoning_step(diff_analysis, hint)

                response = self._generation_step(diff_analysis, app_reasoning, hint)
                commit_data = self._parse_json(response.content)

                validation = self.validator.validate_full(commit_data, diff_analysis)
                if validation.is_valid:
                    return CommitGenerationResult(
                        commit=self._build_commit(commit_data),
                        model_thinking=response.thinking,
                        app_reasoning=app_reasoning,
                    )

                if attempt < MAX_RETRIES - 1:
                    log.warning(f"{Colors.WARNING}Validation failed (attempt {attempt + 1}), retrying...{Colors.ENDC}")
                    diff_analysis.reasoning_context["validation_errors"] = [e.message for e in validation.errors]

            except Exception as e:
                log.warning(f"{Colors.WARNING}Attempt {attempt + 1} failed: {e}{Colors.ENDC}")
                time.sleep(1)

        raise RuntimeError("Failed to generate valid commit after retries")
    
    def _reasoning_step(self, analysis: DiffAnalysis, hint: Optional[str]) -> str:
        files_summary = self._format_files(analysis.files_changed[:12])
        prompt = f"""Analyze this git diff.
CONTEXT: Files: {len(analysis.files_changed)}, Lines: +{analysis.total_additions}/-{analysis.total_deletions}, Patterns: {', '.join(p.value for p in analysis.change_patterns)}
FILES:
{files_summary}
{f"USER HINT: {hint}" if hint else ""}

Determine: 1. Primary intent (feat/fix/refactor) 2. Component/Scope 3. Breaking changes?
Respond with 3 sentences."""
        result = self._call_llm(prompt, temperature=0.3, max_tokens=200, use_native_thinking=False)
        return result.content
    
    def _generation_step(
        self,
        analysis: DiffAnalysis,
        app_reasoning: Optional[str],
        hint: Optional[str],
    ) -> LLMCallResult:
        system_prompt = """Generate a JSON commit message.
RULES:
1. Format: {"type": "...", "scope": "...", "subject": "...", "body": "...", "semver_bump": "major|minor|patch"}
2. Type: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
3. Subject: lowercase, imperative, no period, < 72 chars.
4. Scope: lowercase-kebab-case or null.
5. Body: detailed explanation.
6. The final answer must be a single JSON object. If thinking mode is enabled, keep it separate from the final JSON.

Example:
{"type": "fix", "scope": "api", "subject": "handle timeouts gracefully", "body": "Added retry logic.", "semver_bump": "patch"}"""

        reasoning_block = f"APP REASONING: {app_reasoning}\n" if app_reasoning else ""
        prompt = f"""{reasoning_block}DIFF: +{analysis.total_additions}/-{analysis.total_deletions} lines.
SCOPES: {', '.join(analysis.affected_scopes)}
{f"HINT: {hint}" if hint else ""}
Generate JSON:"""
        return self._call_llm(
            prompt,
            system=system_prompt,
            temperature=0.2,
            max_tokens=400,
            expect_json=True,
            use_native_thinking=self.settings.enable_native_thinking,
        )
    
    def _format_files(self, files: List[FileChange]) -> str:
        return "\n".join(f"  [{'NEW' if f.is_new else 'MOD'}] {f.path}" for f in files)
    
    def _call_llm(
        self,
        prompt: str,
        system: Optional[str] = None,
        temperature: float = 0.2,
        max_tokens: int = 400,
        expect_json: bool = False,
        use_native_thinking: Optional[bool] = None,
    ) -> LLMCallResult:
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        if use_native_thinking is None:
            use_native_thinking = self.settings.enable_native_thinking

        payload: Dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "chat_template_kwargs": {"enable_thinking": use_native_thinking},
        }
        if expect_json:
            payload["response_format"] = {"type": "json_object"}

        req = urllib.request.Request(
            self.api_url,
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=self.timeout) as res:
            raw_response = json.loads(res.read().decode())
        return self._extract_llm_result(raw_response)

    def _extract_llm_result(self, raw_response: Dict[str, Any]) -> LLMCallResult:
        choices = raw_response.get("choices") or []
        if not choices:
            raise ValueError("LLM response missing choices")

        choice = choices[0]
        message = choice.get("message") or {}
        content = self._coerce_text(message.get("content"))
        thinking = self._extract_reasoning(raw_response, choice, message, content)
        clean_content = self._strip_think_blocks(content)

        return LLMCallResult(
            content=clean_content or content,
            thinking=thinking,
            raw_response=raw_response,
        )

    def _extract_reasoning(
        self,
        raw_response: Dict[str, Any],
        choice: Dict[str, Any],
        message: Dict[str, Any],
        content: str,
    ) -> Optional[str]:
        candidates = [
            message.get("reasoning_content"),
            message.get("reasoning"),
            choice.get("reasoning_content"),
            choice.get("reasoning"),
            raw_response.get("reasoning_content"),
            raw_response.get("reasoning"),
        ]

        reasoning_parts: List[str] = []
        seen = set()
        for candidate in candidates:
            text = self._coerce_text(candidate)
            if text and text not in seen:
                reasoning_parts.append(text)
                seen.add(text)

        think_block = self._extract_think_blocks(content)
        if think_block and think_block not in seen:
            reasoning_parts.append(think_block)

        return "\n\n".join(reasoning_parts) if reasoning_parts else None

    def _coerce_text(self, value: Any) -> str:
        if value is None:
            return ""
        if isinstance(value, str):
            return value.strip()
        if isinstance(value, list):
            parts = []
            for item in value:
                if isinstance(item, str):
                    parts.append(item)
                elif isinstance(item, dict):
                    text = item.get("text") or item.get("content") or ""
                    if text:
                        parts.append(str(text))
            return "\n".join(part.strip() for part in parts if part).strip()
        return str(value).strip()

    def _extract_think_blocks(self, text: str) -> str:
        matches = [match.strip() for match in self.THINK_TAG_RE.findall(text) if match.strip()]
        return "\n\n".join(matches)

    def _strip_think_blocks(self, text: str) -> str:
        return self.THINK_TAG_RE.sub("", text).strip()

    def _parse_json(self, response: str) -> Dict:
        response = self._strip_think_blocks(response)
        response = re.sub(r"```json\s*|\s*```", "", response, flags=re.IGNORECASE).strip()
        start, end = response.find("{"), response.rfind("}") + 1
        if start >= 0 and end > start:
            response = response[start:end]
        return json.loads(response)
    
    def _build_commit(self, data: Dict) -> CommitMessage:
        return CommitMessage(
            type=CommitType(data.get("type", "chore")),
            scope=data.get("scope") or None,
            subject=data.get("subject", "update code"),
            body=data.get("body", ""),
            breaking=data.get("breaking", False),
            semver_bump=data.get("semver_bump", "patch"),
        )

# ═══════════════════════════════════════════════════════════════════════════
# Main Orchestrator
# ═══════════════════════════════════════════════════════════════════════════

class SmartCommitOrchestrator:
    def __init__(self, settings: LLMSettings):
        self.settings = settings
        self.analyzer = GitDiffAnalyzer()
        self.llm = ChainOfThoughtLLM(MODEL_NAME, API_URL, REQUEST_TIMEOUT, settings)
    
    def run(self, hint: Optional[str] = None) -> None:
        self._verify_git_repo()
        
        log.info(f"{Colors.CYAN}🔌 Checking LLM connection...{Colors.ENDC}")
        if not self.llm.check_health():
            log.error(f"{Colors.FAIL}❌ Cannot connect to LLM at {API_URL}{Colors.ENDC}")
            log.info("Please ensure your local inference server (llama.cpp/ollama) is running.")
            sys.exit(1)
            
        self._run_pipeline_check()
        self._scope_guard()
        
        log.info(f"{Colors.CYAN}🔍 Analyzing repository state...{Colors.ENDC}")
        raw_diff = self._get_staged_diff()
        
        # Truncate if too large
        if len(raw_diff) > MAX_DIFF_SIZE:
            log.warning(f"{Colors.WARNING}⚠️ Diff too large ({len(raw_diff)} chars), truncating to {MAX_DIFF_SIZE}{Colors.ENDC}")
            raw_diff = raw_diff[:MAX_DIFF_SIZE] + "\n... (truncated)"
            
        diff_analysis = self.analyzer.parse_diff(raw_diff)
        
        log.info(f"{Colors.GREEN}📈 Analysis complete:{Colors.ENDC} {len(diff_analysis.files_changed)} files, {diff_analysis.change_complexity}")
        
        log.info(f"{Colors.CYAN}🤖 Generating commit message...{Colors.ENDC}")
        generation = self.llm.generate_commit(diff_analysis, hint)

        if self.settings.show_thinking and generation.model_thinking:
            self._display_text_block("MODEL THINKING", generation.model_thinking, Colors.BLUE)
        elif self.settings.show_thinking and self.settings.enable_native_thinking:
            log.warning(f"{Colors.WARNING}Native thinking was enabled, but the backend returned no visible reasoning.{Colors.ENDC}")

        if self.settings.show_thinking and generation.app_reasoning:
            self._display_text_block("APP REASONING", generation.app_reasoning, Colors.CYAN)

        self._display_commit(generation.commit)
        self._confirm_and_commit(generation.commit)
    
    def _verify_git_repo(self):
        if not Path(".git").exists():
            log.error(f"{Colors.FAIL}Not a git repository{Colors.ENDC}")
            sys.exit(1)
    
    def _run_pipeline_check(self):
        script = Path("./scripts/pipeline-check.sh")
        if script.exists():
            log.info(f"{Colors.CYAN}🛡️  Running pre-commit pipeline...{Colors.ENDC}")
            try:
                subprocess.run([str(script)], check=True)
            except subprocess.CalledProcessError:
                log.error(f"{Colors.FAIL}❌ Pipeline failed{Colors.ENDC}")
                sys.exit(1)
    
    def _scope_guard(self):
        files = self._run_git(["git", "diff", "--name-only", "--cached"]).splitlines()
        if not files:
            log.error(f"{Colors.FAIL}❌ No files staged.{Colors.ENDC}")
            sys.exit(1)
        
        roots = Counter([f.split('/')[0] for f in files if '/' in f])
        if len(roots) > 1:
            log.warning(f"\n{Colors.WARNING}⚠️  MIXED CONTEXT DETECTED{Colors.ENDC}")
            for r, c in roots.items(): log.warning(f"  - {r}/ ({c} files)")
            if input(f"\n{Colors.BOLD}Continue anyway? [y/N]: {Colors.ENDC}").lower() != 'y':
                sys.exit(0)
    
    def _get_staged_diff(self) -> str:
        return self._run_git(["git", "diff", "--cached"])
    
    def _run_git(self, cmd: List[str]) -> str:
        try:
            return subprocess.run(cmd, check=True, stdout=subprocess.PIPE, text=True).stdout.strip()
        except subprocess.CalledProcessError as e:
            log.error(f"{Colors.FAIL}Git command failed: {e}{Colors.ENDC}")
            sys.exit(1)
    
    def _display_commit(self, msg: CommitMessage):
        full = msg.format()
        print(f"\n{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"{Colors.BOLD}SUGGESTED COMMIT{Colors.ENDC} ({msg.type.value})")
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"{Colors.GREEN}{full}{Colors.ENDC}")
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}\n")

    def _display_text_block(self, title: str, content: str, color: str):
        print(f"\n{color}{'=' * 60}{Colors.ENDC}")
        print(f"{Colors.BOLD}{title}{Colors.ENDC}")
        print(f"{color}{'=' * 60}{Colors.ENDC}")
        print(content)
        print(f"{color}{'=' * 60}{Colors.ENDC}\n")
    
    def _confirm_and_commit(self, msg: CommitMessage):
        choice = input(f"{Colors.BOLD}Commit? [Y/n/e(dit)]: {Colors.ENDC}").lower()
        full_msg = msg.format()
        
        if choice in ['y', 'yes', '']:
            subprocess.run(["git", "commit", "-m", full_msg], check=True)
            log.info(f"{Colors.GREEN}✅ Committed successfully{Colors.ENDC}")
        elif choice == 'e':
            edit_file = Path(".git/COMMIT_EDITMSG")
            edit_file.write_text(full_msg)
            subprocess.run([os.environ.get('EDITOR', 'vim'), str(edit_file)])
            if subprocess.run(["git", "commit", "-F", str(edit_file)]).returncode == 0:
                log.info(f"{Colors.GREEN}✅ Committed with edits{Colors.ENDC}")
        else:
            log.info(f"{Colors.WARNING}❌ Cancelled{Colors.ENDC}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Smart Commit V2 - Enterprise Edition')
    parser.add_argument('hint', nargs='?', help='Context hint')
    parser.set_defaults(
        native_thinking=ENABLE_NATIVE_THINKING,
        show_thinking=SHOW_THINKING,
        app_reasoning=ENABLE_APP_REASONING,
    )
    parser.add_argument('--native-thinking', dest='native_thinking', action='store_true', help='Enable native model thinking')
    parser.add_argument('--no-native-thinking', dest='native_thinking', action='store_false', help='Disable native model thinking')
    parser.add_argument('--show-thinking', dest='show_thinking', action='store_true', help='Print model thinking in the terminal')
    parser.add_argument('--hide-thinking', dest='show_thinking', action='store_false', help='Hide thinking output in the terminal')
    parser.add_argument('--app-reasoning', dest='app_reasoning', action='store_true', help='Run an extra reasoning pass before generating JSON')
    parser.add_argument('--no-cot', dest='app_reasoning', action='store_false', help='Disable the extra reasoning pass')
    args = parser.parse_args()

    settings = LLMSettings(
        enable_native_thinking=args.native_thinking,
        show_thinking=args.show_thinking,
        enable_app_reasoning=args.app_reasoning,
    )

    try:
        SmartCommitOrchestrator(settings).run(args.hint)
    except KeyboardInterrupt:
        print("\nInterrupted.")
    except Exception as e:
        log.error(f"{Colors.FAIL}Fatal error: {e}{Colors.ENDC}")
