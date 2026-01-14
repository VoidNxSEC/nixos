#!/usr/bin/env python3
"""
find-nix-syntax-error.py - Find missing braces, parentheses, and semicolons in Nix files

Usage:
    python3 find-nix-syntax-error.py /path/to/file.nix
    python3 find-nix-syntax-error.py /path/to/directory

Features:
- Detects mismatched braces {}, brackets [], parentheses ()
- Detects missing semicolons in attribute sets
- Handles Nix string literals (both "..." and ''...'')
- Handles comments (# and /* */)
- Reports line numbers and positions
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Regular expressions for Nix syntax
STRING_DOUBLE_QUOTE = r'"(?:\\.|[^"\\])*"'  # Double quoted strings
STRING_SINGLE_QUOTE = (
    r"''(?:\\.|[^'\\]|'[^'])*''"  # Single quoted strings (two single quotes)
)
COMMENT_LINE = r"#.*$"  # Line comment
COMMENT_START = r"/\*"  # Block comment start
COMMENT_END = r"\*/"  # Block comment end


class NixSyntaxChecker:
    """Check Nix file syntax for common errors."""

    def __init__(self):
        self.errors: List[Tuple[int, str]] = []
        self.warnings: List[Tuple[int, str]] = []

    def check_file(self, filepath: str) -> bool:
        """Check a single Nix file for syntax errors."""
        print(f"🔍 Checking {filepath}")

        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        lines = content.split("\n")

        # Track states
        in_double_string = False
        in_single_string = False
        in_block_comment = False
        in_line_comment = False

        # Stack for tracking delimiters
        delimiter_stack = []  # Each element is (char, line_number, column)

        # Track semicolon context
        last_attr_line = -1
        last_attr_column = -1
        expecting_semicolon = False

        for line_num, line in enumerate(lines, 1):
            col = 0
            while col < len(line):
                char = line[col]
                next_char = line[col + 1] if col + 1 < len(line) else ""

                # Handle block comments
                if (
                    not in_double_string
                    and not in_single_string
                    and not in_line_comment
                ):
                    if char == "/" and next_char == "*":
                        in_block_comment = True
                        col += 2
                        continue
                    elif char == "*" and next_char == "/":
                        if in_block_comment:
                            in_block_comment = False
                            col += 2
                            continue

                # Skip everything if we're in a comment
                if in_block_comment or in_line_comment:
                    col += 1
                    continue

                # Handle line comments
                if char == "#":
                    in_line_comment = True
                    col += 1
                    continue

                # Handle strings
                if char == '"' and not in_single_string:
                    # Check if escaped
                    if col > 0 and line[col - 1] == "\\":
                        col += 1
                        continue

                    if not in_double_string:
                        in_double_string = True
                    else:
                        in_double_string = False
                    col += 1
                    continue

                # Handle single quoted strings (two single quotes)
                if char == "'" and not in_double_string:
                    if col + 1 < len(line) and line[col + 1] == "'":
                        if not in_single_string:
                            in_single_string = True
                        else:
                            in_single_string = False
                        col += 2
                        continue

                # Skip characters inside strings
                if in_double_string or in_single_string:
                    col += 1
                    continue

                # Reset line comment flag at end of line
                if char == "\n":
                    in_line_comment = False
                    col += 1
                    continue

                # Track delimiters
                if char in "({[":
                    delimiter_stack.append((char, line_num, col))
                    expecting_semicolon = False
                elif char in ")}]":
                    if not delimiter_stack:
                        self.errors.append(
                            (
                                line_num,
                                f"Unmatched closing '{char}' at column {col + 1}",
                            )
                        )
                    else:
                        last_open, open_line, open_col = delimiter_stack.pop()
                        expected_close = {"(": ")", "{": "}", "[": "]"}[last_open]
                        if char != expected_close:
                            self.errors.append(
                                (
                                    line_num,
                                    f"Mismatched delimiter: '{last_open}' at line {open_line}:{open_col + 1} "
                                    f"closed with '{char}' at column {col + 1}",
                                )
                            )

                # Check for semicolons in attribute sets
                if expecting_semicolon:
                    # Skip whitespace
                    if not char.isspace():
                        if char == ";":
                            expecting_semicolon = False
                        elif char == "}" and expecting_semicolon:
                            # Last attribute in set doesn't need semicolon
                            expecting_semicolon = False
                        elif char not in "#/'\"":
                            self.warnings.append(
                                (
                                    last_attr_line,
                                    f"Missing semicolon after attribute at line {last_attr_line}:{last_attr_column + 1}",
                                )
                            )
                            expecting_semicolon = False

                # Check for attribute assignments
                if char.isalnum() or char in "_-":
                    # Look ahead for '=' to detect attribute assignments
                    substr = line[col:]
                    match = re.match(r"([a-zA-Z_][a-zA-Z0-9_-]*)\s*=.*[^;]$", substr)
                    if match and not expecting_semicolon:
                        attr_name = match.group(1)
                        # Check if this is inside an attribute set (we have an open brace)
                        if delimiter_stack and delimiter_stack[-1][0] == "{":
                            # Check if there's already a semicolon in this line after the assignment
                            line_rest = line[col + len(attr_name) :]
                            if ";" not in line_rest and not line_rest.strip().endswith(
                                "}"
                            ):
                                expecting_semicolon = True
                                last_attr_line = line_num
                                last_attr_column = col + len(attr_name)

                col += 1

            # Reset line comment at end of line
            in_line_comment = False

        # Check for unclosed delimiters
        for char, line_num, col in delimiter_stack:
            self.errors.append(
                (line_num, f"Unclosed '{char}' at line {line_num}:{col + 1}")
            )

        # Check for unclosed strings
        if in_double_string:
            self.errors.append((len(lines), "Unclosed double-quoted string"))
        if in_single_string:
            self.errors.append((len(lines), "Unclosed single-quoted string"))
        if in_block_comment:
            self.errors.append((len(lines), "Unclosed block comment"))

        return len(self.errors) == 0

    def report(self) -> bool:
        """Print errors and warnings, return True if no errors."""
        if not self.errors and not self.warnings:
            print("✅ No syntax errors found")
            return True

        if self.errors:
            print("\n❌ SYNTAX ERRORS:")
            for line_num, msg in sorted(self.errors, key=lambda x: x[0]):
                print(f"  Line {line_num}: {msg}")

        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for line_num, msg in sorted(self.warnings, key=lambda x: x[0]):
                print(f"  Line {line_num}: {msg}")

        return len(self.errors) == 0

    def simple_check_braces(self, filepath: str) -> Optional[Tuple[int, str]]:
        """
        Simple check that only counts braces - useful for quick validation.
        Returns (line_number, error_message) if error found, None otherwise.
        """
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        brace_count = 0
        in_string = False
        string_char = None
        in_comment = False

        for i, line in enumerate(lines, 1):
            col = 0
            while col < len(line):
                char = line[col]
                next_char = line[col + 1] if col + 1 < len(line) else ""

                # Handle comments
                if not in_string:
                    if char == "#" and not in_comment:
                        break  # Rest of line is comment
                    if char == "/" and next_char == "*":
                        in_comment = True
                        col += 2
                        continue
                    if char == "*" and next_char == "/" and in_comment:
                        in_comment = False
                        col += 2
                        continue

                if in_comment:
                    col += 1
                    continue

                # Handle strings
                if char in "'\"":
                    if not in_string:
                        in_string = True
                        string_char = char
                    elif string_char == char:
                        # Check if escaped
                        if col > 0 and line[col - 1] != "\\":
                            in_string = False
                            string_char = None

                # Count braces only when not in string
                if not in_string:
                    if char == "{":
                        brace_count += 1
                    elif char == "}":
                        brace_count -= 1
                        if brace_count < 0:
                            return (
                                i,
                                f"Extra closing brace '}}' at line {i}, column {col + 1}",
                            )

                col += 1

        if brace_count > 0:
            return (len(lines), f"Missing {brace_count} closing brace(s)")
        elif brace_count < 0:
            return (len(lines), f"Extra {-brace_count} closing brace(s)")

        return None


def find_nix_files(path: str) -> List[str]:
    """Find all .nix files recursively."""
    nix_files = []

    if os.path.isfile(path) and path.endswith(".nix"):
        return [path]

    for root, dirs, files in os.walk(path):
        # Skip .git directories
        if ".git" in root:
            continue

        for file in files:
            if file.endswith(".nix"):
                nix_files.append(os.path.join(root, file))

    return sorted(nix_files)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 find-nix-syntax-error.py <file.nix|directory>")
        print(
            "Example: python3 find-nix-syntax-error.py /etc/nixos/hosts/kernelcore/configuration.nix"
        )
        sys.exit(1)

    path = sys.argv[1]
    if not os.path.exists(path):
        print(f"Error: Path '{path}' does not exist")
        sys.exit(1)

    # Find all Nix files
    nix_files = find_nix_files(path)

    if not nix_files:
        print(f"No .nix files found in '{path}'")
        sys.exit(1)

    print(f"Found {len(nix_files)} Nix file(s) to check")

    all_good = True
    checker = NixSyntaxChecker()

    for nix_file in nix_files:
        print("\n" + "=" * 60)

        # First, do a quick brace count check
        simple_error = checker.simple_check_braces(nix_file)
        if simple_error:
            line_num, msg = simple_error
            print(f"❌ BRACE ERROR in {os.path.basename(nix_file)}:")
            print(f"   Line {line_num}: {msg}")
            print(f"   File: {nix_file}")
            all_good = False

            # Show context around the error
            with open(nix_file, "r", encoding="utf-8") as f:
                lines = f.readlines()

            start_line = max(0, line_num - 3)
            end_line = min(len(lines), line_num + 2)

            print("\n   Context:")
            for i in range(start_line, end_line):
                indicator = ">>>" if i + 1 == line_num else "   "
                print(f"   {indicator} {i + 1:4d}: {lines[i].rstrip()}")

            continue

        # Then do full syntax check
        checker.errors = []
        checker.warnings = []

        if checker.check_file(nix_file):
            checker.report()
        else:
            all_good = False
            checker.report()

            # Show last few lines for context
            with open(nix_file, "r", encoding="utf-8") as f:
                lines = f.readlines()

            if lines:
                print("\nLast 10 lines of file:")
                for i in range(max(0, len(lines) - 10), len(lines)):
                    print(f"{i + 1:4d}: {lines[i].rstrip()}")

    print("\n" + "=" * 60)
    if all_good:
        print("✅ All files passed syntax check!")
        sys.exit(0)
    else:
        print("❌ Some files have syntax errors")
        sys.exit(1)


if __name__ == "__main__":
    main()
