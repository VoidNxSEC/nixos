#!/usr/bin/env python3
"""
LLM Prompt Templates for Architecture Analyzer
===============================================
Structured prompts for Ollama/LLM integration.
"""

PROMPTS = {
    # =========================================================================
    # MODULE ANALYSIS - Semantic understanding of individual modules
    # =========================================================================
    "module_analysis": {
        "system": """You are an expert NixOS configuration analyst specializing in Nix modules.
Analyze code precisely and provide structured, factual analysis.
Focus on: purpose, complexity, dependencies, security implications, and issues.
Be concise and technical. Use only facts from the code provided.
Respond ONLY with valid JSON, no markdown or explanation.""",

        "template": """Analyze this NixOS module and provide structured analysis.

FILE: {filename}
CATEGORY: {category}
LINES: {lines}

```nix
{code}
```

Respond with this exact JSON structure:
{{
  "purpose": "One sentence describing what this module does",
  "complexity": "low|medium|high|critical",
  "dependencies": ["explicit nix module dependencies found"],
  "options_defined": ["list of mkOption/mkEnableOption names"],
  "security_concerns": ["security issues if any, empty if none"],
  "issues": [
    {{"severity": "info|warning|error", "message": "issue description", "line": null}}
  ],
  "recommendations": ["improvement suggestions"]
}}"""
    },

    # =========================================================================
    # ARCHITECTURE SUMMARY - High-level repository analysis
    # =========================================================================
    "architecture_summary": {
        "system": """You are a software architect analyzing NixOS configuration repositories.
Provide high-level insights about architecture patterns, organization quality, and improvements.
Be concise but comprehensive. Focus on actionable insights.
Respond ONLY with valid JSON, no markdown or explanation.""",

        "template": """Analyze this NixOS repository architecture:

REPOSITORY: {repo}
TOTAL MODULES: {total_modules}
TOTAL LINES: {total_lines}
CATEGORIES: {categories}

CATEGORY BREAKDOWN:
{category_breakdown}

TOP COMPLEX MODULES:
{complexity_breakdown}

SECURITY MODULES:
{security_modules}

ORPHAN MODULES (not imported):
{orphan_modules}

Respond with this exact JSON structure:
{{
  "executive_summary": "2-3 sentence summary of repository quality and structure",
  "architecture_patterns": ["detected patterns like 'modular', 'layered', 'monolithic'"],
  "strengths": ["strong points of this configuration"],
  "technical_debt": ["specific areas needing improvement"],
  "security_assessment": "brief security posture assessment",
  "priority_actions": ["top 3-5 recommended actions, specific and actionable"]
}}"""
    },

    # =========================================================================
    # AUTO-FIX GENERATION - Generate code fixes for issues
    # =========================================================================
    "generate_fix": {
        "system": """You are an expert NixOS developer who writes clean, secure Nix code.
Generate precise code fixes for identified issues.
Ensure fixes are minimal, targeted, and maintain existing functionality.
Respond ONLY with valid JSON containing the fix.""",

        "template": """Generate a fix for this issue in a NixOS module.

FILE: {filename}
ISSUE: {issue_message}
SEVERITY: {severity}
LINE: {line}

CURRENT CODE (lines {start_line}-{end_line}):
```nix
{code_context}
```

FULL MODULE FOR CONTEXT:
```nix
{full_code}
```

Generate a minimal fix. Respond with this exact JSON:
{{
  "can_fix": true,
  "confidence": 0.0-1.0,
  "risk": "low|medium|high",
  "description": "what the fix does",
  "fixed_code": "the corrected code for lines {start_line}-{end_line}"
}}

If you cannot safely fix this issue, set can_fix to false and explain why."""
    },

    # =========================================================================
    # DOCUMENTATION GENERATION - Generate missing docs
    # =========================================================================
    "generate_documentation": {
        "system": """You are a technical writer for NixOS configurations.
Generate clear, concise module documentation.
Follow NixOS documentation conventions.
Respond ONLY with the documentation text, no markdown code blocks.""",

        "template": """Generate documentation header for this NixOS module.

FILE: {filename}
PURPOSE: {purpose}
OPTIONS DEFINED: {options}

CURRENT MODULE:
```nix
{code}
```

Generate a Nix comment block (using # comments) that documents:
1. Module purpose (1-2 sentences)
2. Usage example
3. Key options if any

Keep it concise and follow NixOS conventions."""
    },

    # =========================================================================
    # SELF-ANALYSIS - Analyze arch-analyzer quality
    # =========================================================================
    "self_analysis": {
        "system": """You are a code quality analyst reviewing a Python architecture analyzer.
Identify issues, bugs, improvements, and rate overall quality.
Be critical but constructive.
Respond ONLY with valid JSON.""",

        "template": """Analyze this architecture analyzer code for quality and issues.

FILE: {filename}
LINES: {lines}

```python
{code}
```

Check for:
- Bugs or logic errors
- Missing error handling
- Performance issues
- Code style problems
- Missing features
- Security issues

Respond with this exact JSON:
{{
  "quality_score": 0-100,
  "issues": [
    {{"severity": "info|warning|error|critical", "message": "description", "line": null}}
  ],
  "improvements": ["specific suggestions"],
  "missing_features": ["features that should be added"]
}}"""
    },

    # =========================================================================
    # VALIDATION - Validate applied fixes
    # =========================================================================
    "validate_fix": {
        "system": """You are a NixOS code reviewer validating code changes.
Check if the fix is correct and safe.
Be strict about correctness.
Respond ONLY with valid JSON.""",

        "template": """Validate this code fix for a NixOS module.

ORIGINAL CODE:
```nix
{original}
```

FIXED CODE:
```nix
{fixed}
```

FIX DESCRIPTION: {description}
INTENDED FIX FOR: {issue}

Validate:
1. Is the syntax correct?
2. Does it fix the intended issue?
3. Does it introduce new issues?
4. Is it safe to apply?

Respond with:
{{
  "valid": true|false,
  "safe": true|false,
  "issues": ["any problems found"],
  "recommendation": "apply|review|reject"
}}"""
    }
}


def get_prompt(name: str, **kwargs) -> tuple[str, str]:
    """Get a formatted prompt with system message.
    
    Returns:
        Tuple of (system_prompt, user_prompt)
    """
    if name not in PROMPTS:
        raise ValueError(f"Unknown prompt: {name}")
    
    prompt_config = PROMPTS[name]
    system = prompt_config["system"]
    template = prompt_config["template"].format(**kwargs)
    
    return system, template
