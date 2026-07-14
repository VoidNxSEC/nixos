#!/usr/bin/env python3
"""
config-audit-master.py — Mestre de auditoria kernelcore.*

Varre modules/ buscando referências a config.kernelcore.* e cruza com
o que está declarado em hosts/kernelcore/configuration.nix.

Uso:
  ./scripts/config-audit-master.py                  # tabela completa
  ./scripts/config-audit-master.py --validate        # contra-fact-check: 3-way
  ./scripts/config-audit-master.py --json           # saída JSON
  ./scripts/config-audit-master.py --unconfigured    # só opções não configuradas
  ./scripts/config-audit-master.py --unused          # só opções configuradas sem referência
  ./scripts/config-audit-master.py --module memory   # filtra por módulo
"""

import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = "/etc/nixos"
MODULES_DIR = os.path.join(REPO_ROOT, "modules")
HOST_CONFIG = os.path.join(REPO_ROOT, "hosts/kernelcore/configuration.nix")

# ─── phase 1: parse configuration.nix into a flat dict ─────────────────────


def parse_host_config(path: str) -> dict[str, str]:
    """Parse host configuration.nix → dict of kernelcore.* → value."""
    with open(path) as f:
        lines = f.readlines()

    results: dict[str, str] = {}
    stack: list[tuple[int, str]] = []

    assign_re = re.compile(r"^(\s*)([a-zA-Z_][\w.-]*)\s*=\s*(.+?)\s*;\s*,?\s*$")
    block_open_re = re.compile(r"^(\s*)([a-zA-Z_][\w.-]*)\s*=\s*\{\s*(#.*)?$")
    block_close_re = re.compile(r"^(\s*)\}\s*,?\s*;?\s*$")

    def _pop_to(indent):
        while stack and stack[-1][0] >= indent:
            stack.pop()

    def _prefix():
        return ".".join(s for _, s in stack)

    for raw in lines:
        line = raw.rstrip()
        if not line or line.strip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())

        bm = block_close_re.match(line)
        if bm:
            _pop_to(len(bm.group(1)))
            continue

        bm = block_open_re.match(line)
        if bm:
            key = bm.group(2)
            _pop_to(indent)
            prefix = _prefix()
            full_path = f"{prefix}.{key}" if prefix else key
            stack.append((indent, key))
            if full_path.startswith("kernelcore."):
                results[full_path] = "{...}"
            continue

        m = assign_re.match(line)
        if not m:
            continue
        key, value = m.group(2), m.group(3)
        key_indent = len(m.group(1))
        _pop_to(key_indent)
        prefix = _prefix()
        full_path = f"{prefix}.{key}" if prefix else key
        value = value.rstrip(",").strip()
        if full_path.startswith("kernelcore."):
            results[full_path] = value
        stack.append((key_indent, key))

    return results


# ─── phase 2: scan modules for config.kernelcore.* references ──────────────


def scan_module_references(modules_dir: str) -> dict[str, set[str]]:
    """Find all config.kernelcore.* usages in modules."""
    ref_re = re.compile(r"config\.(kernelcore\.[a-zA-Z_][\w.-]*)")
    option_to_modules: dict[str, set[str]] = defaultdict(set)

    for nix_file in sorted(Path(modules_dir).rglob("*.nix")):
        rel = str(nix_file.relative_to(modules_dir))
        try:
            with open(nix_file) as f:
                content = f.read()
        except Exception:
            continue
        for match in ref_re.finditer(content):
            option_to_modules[match.group(1)].add(rel)
    return dict(option_to_modules)


# ─── phase 2b: scan modules for option DECLARATIONS ────────────────────────


def scan_module_declarations(modules_dir: str) -> dict[str, set[str]]:
    """
    Find all kernelcore.* option declarations in modules.
    Looks for: kernelcore.xxx.yyy = mkEnableOption "..."
               kernelcore.xxx.yyy = mkOption { ... }
    Returns dict: option_path → set of module files that declare it.
    """
    # Pattern: kernelcore.something = mkEnableOption  OR  = mkOption  OR  = lib.mkEnableOption
    decl_re = re.compile(
        r"(?:^|\n)\s*(kernelcore\.[a-zA-Z_][\w.-]*)\s*=\s*(?:lib\.)?(?:mkEnableOption|mkOption)\b"
    )
    option_to_modules: dict[str, set[str]] = defaultdict(set)

    # Also find the set of all paths that appear ANYWHERE in files that
    # have mkEnableOption/mkOption (for nested-declaration prefix matching)
    kernelcore_path_re = re.compile(r"(?:^|\n)\s*(kernelcore\.[a-zA-Z_][\w.-]*)")

    # Also build a set of files that contain ANY mkEnableOption/mkOption
    # (used to detect nested declarations)
    decl_files: set[str] = set()
    mk_any_re = re.compile(r"\bmk(?:Enable)?Option\b")

    for nix_file in sorted(Path(modules_dir).rglob("*.nix")):
        rel = str(nix_file.relative_to(modules_dir))
        try:
            with open(nix_file) as f:
                content = f.read()
        except Exception:
            continue

        has_mk = bool(mk_any_re.search(content))
        if has_mk:
            decl_files.add(rel)

        for match in decl_re.finditer(content):
            option_to_modules[match.group(1)].add(rel)

    return dict(option_to_modules), decl_files


# ─── phase 3: cross-reference ───────────────────────────────────────────────


def normalize_value(val: str) -> str:
    val = val.strip().rstrip(";").strip()
    if val in ("true", "false"):
        return val
    if (val.startswith('"') and val.endswith('"')) or (
        val.startswith("'") and val.endswith("'")
    ):
        return val
    if len(val) > 60:
        return val[:57] + "..."
    return val


def build_correlation(host_config, module_refs):
    all_paths = set(host_config.keys()) | set(module_refs.keys())
    rows = []
    for path in sorted(all_paths):
        val = host_config.get(path)
        mods = module_refs.get(path, set())
        if val is not None and mods:
            status = "MATCH"
        elif val is not None and not mods:
            status = "NO_MODULE"
        elif val is None and mods:
            status = "NO_CONFIG"
        else:
            continue
        is_enabled = None
        if val is not None:
            norm = val.strip()
            if norm == "true":
                is_enabled = True
            elif norm == "false":
                is_enabled = False
            elif norm.startswith("mkForce true"):
                is_enabled = True
            elif norm.startswith("mkForce false"):
                is_enabled = False
        rows.append(
            {
                "path": path,
                "configured_value": normalize_value(val) if val else None,
                "is_enabled": is_enabled,
                "modules": sorted(mods),
                "status": status,
            }
        )
    return rows


# ─── phase 4: validation (contra-fact-check) ────────────────────────────────


def validate(host_config, module_refs, module_decls, decl_files):
    """
    Triple correlation: declarations ↔ references ↔ host_config.
    Reports orphans and inconsistencies.
    """
    all_refs = set(module_refs.keys())
    all_decls = set(module_decls.keys())
    all_host = set(host_config.keys())

    # Helper: check if a path is "covered" by a declared option
    # (either exact match, or child of a declared parent, or declared nested inside)
    def _covered_by_decl(path: str) -> bool:
        if path in all_decls:
            return True
        # Child of a declared flat option? e.g. kernelcore.nvidia.prime.intelBusId
        # is a child of kernelcore.nvidia.prime (which might be nested)
        for d in all_decls:
            if path.startswith(d + "."):
                return True
        # Parent of a declared option? e.g. kernelcore.nvidia is parent of
        # kernelcore.nvidia.enable (nested declaration)
        for d in all_decls:
            if d.startswith(path + "."):
                return True
        return False

    issues = []

    # 1. Referenced but never declared (🚨 potential bug)
    ref_no_decl = all_refs - all_decls
    for path in sorted(ref_no_decl):
        if _covered_by_decl(path):
            continue
        if path in all_host:
            continue
        # Heuristic: if the referencing module itself contains mkOption/mkEnableOption,
        # the declaration is likely there in nested form — skip false positive
        ref_modules = module_refs.get(path, set())
        if ref_modules and all(m in decl_files for m in ref_modules):
            continue
        issues.append(
            {
                "type": "REF_WITHOUT_DECL",
                "severity": "🚨 HIGH",
                "path": path,
                "detail": "Referenced by config.kernelcore.* but no mkOption/mkEnableOption found",
                "modules": sorted(module_refs.get(path, [])),
            }
        )

    # 2. Declared but never referenced by any config.kernelcore.* (💤 dead code)
    decl_no_ref = all_decls - all_refs
    for path in sorted(decl_no_ref):
        if path in all_host:
            continue
        issues.append(
            {
                "type": "DECL_WITHOUT_REF",
                "severity": "💤 LOW",
                "path": path,
                "detail": "Declared but never referenced via config.kernelcore.*",
                "modules": sorted(module_decls.get(path, [])),
            }
        )

    # 3. In host config but no declaration exists (👻 zombie config)
    host_no_decl = all_host - all_decls
    for path in sorted(host_no_decl):
        if _covered_by_decl(path):
            continue
        if path in all_refs:
            continue
        if host_config.get(path) == "{...}":
            continue
        # Heuristic: if the host config entry is a parent of known refs,
        # it's likely a grouping block (not a real option)
        if any(r.startswith(path + ".") for r in all_refs):
            continue
        issues.append(
            {
                "type": "HOST_WITHOUT_DECL",
                "severity": "👻 MED",
                "path": path,
                "detail": "In configuration.nix but no mkOption/mkEnableOption declares it",
                "value": host_config[path],
                "modules": [],
            }
        )

    # 4. Declared + referenced but not in host config
    decl_ref_no_host = (all_decls & all_refs) - all_host
    for path in sorted(decl_ref_no_host):
        if path.endswith(".enable"):
            issues.append(
                {
                    "type": "MISSING_HOST_CONFIG",
                    "severity": "⚠️  MED",
                    "path": path,
                    "detail": "Declared + referenced but not in configuration.nix (uses default)",
                    "modules": sorted(module_decls.get(path, [])),
                }
            )

    return issues


def print_validation_report(issues):
    """Pretty-print the validation report."""
    if not issues:
        print("\n✅ Nenhum problema encontrado. Tudo consistente!")
        return

    high = [i for i in issues if "HIGH" in i["severity"]]
    med = [i for i in issues if "MED" in i["severity"]]
    low = [i for i in issues if "LOW" in i["severity"]]

    print(f"\n{'═' * 120}")
    print(
        f"  🔬 CONTRA-FACT-CHECK — Validação tripla (declarações ↔ referências ↔ host config)"
    )
    print(f"  🚨 HIGH: {len(high)}  |  ⚠️ MED: {len(med)}  |  💤 LOW: {len(low)}")
    print(f"{'═' * 120}\n")

    for sev_label, sev_issues in [
        ("🚨 CRÍTICO — Referenciado mas NUNCA declarado", high),
        ("⚠️  ATENÇÃO — Declarado mas ausente do host config", med),
        ("💤 BAIXO — Declarado mas nunca referenciado", low),
    ]:
        if not sev_issues:
            continue
        print(f"  {sev_label}")
        print(f"  {'─' * 110}")
        for i in sev_issues:
            mod_list = i.get("modules", [])
            mods = ", ".join(mod_list[:2])
            if len(mod_list) > 2:
                mods += f" +{len(mod_list) - 2}"
            extra = ""
            if i.get("value"):
                extra = f"  value={i['value']}"
            print(f"  {i['severity'][:2]:<3} {i['path']:<65} {mods}{extra}")
        print()

    if high:
        print(
            "  💡 Ação: paths 🚨 podem indicar bug — o módulo usa config.kernelcore.X"
        )
        print("           mas nenhum mkOption/mkEnableOption define X. Verifique se o")
        print("           option foi declarado em outro arquivo ou se é um typo.\n")


# ─── output ─────────────────────────────────────────────────────────────────


def print_table(rows, filter_status=None, filter_module=None):
    if filter_status:
        rows = [r for r in rows if r["status"] == filter_status]
    if filter_module:
        rows = [r for r in rows if any(filter_module in m for m in r["modules"])]
    if not rows:
        print("Nenhum resultado encontrado.")
        return

    enabled = sum(1 for r in rows if r["is_enabled"] is True)
    disabled = sum(1 for r in rows if r["is_enabled"] is False)
    configured = sum(
        1 for r in rows if r["is_enabled"] is None and r["configured_value"]
    )
    no_config = sum(1 for r in rows if r["status"] == "NO_CONFIG")
    no_module = sum(1 for r in rows if r["status"] == "NO_MODULE")

    print(f"\n{'═' * 110}")
    print(f"  AUDITORIA kernelcore.* — {len(rows)} paths encontrados")
    print(f"  ✅ ON: {enabled}  |  ❌ OFF: {disabled}  |  ⚙️  CONF: {configured}")
    print(f"  ⚠️  Sem config no host: {no_config}  |  👻 Sem ref em módulo: {no_module}")
    print(f"{'═' * 110}\n")
    print(f"{'STATUS':<6} {'ENABLE':<7} {'PATH':<60} {'VALUE':<14} {'MODULE(S)'}")
    print(f"{'─' * 6} {'─' * 7} {'─' * 60} {'─' * 14} {'─' * 40}")

    for r in rows:
        icon = {"MATCH": "✅", "NO_CONFIG": "⚠️", "NO_MODULE": "👻"}.get(
            r["status"], "?"
        )
        ena = (
            "ON"
            if r["is_enabled"] is True
            else ("OFF" if r["is_enabled"] is False else "·")
        )
        val = r["configured_value"] or "—"
        mods = ", ".join(r["modules"][:2])
        if len(r["modules"]) > 2:
            mods += f" +{len(r['modules']) - 2}"
        print(f"{icon:<6} {ena:<7} {r['path']:<60} {val:<14} {mods}")
    print()


def print_json(data):
    print(json.dumps(data, indent=2))


# ─── main ───────────────────────────────────────────────────────────────────


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Auditoria kernelcore.* cross-reference"
    )
    parser.add_argument("--json", action="store_true", help="Saída JSON")
    parser.add_argument(
        "--unconfigured", action="store_true", help="Só opções sem config no host (⚠️)"
    )
    parser.add_argument(
        "--unused",
        action="store_true",
        help="Só opções configuradas sem ref em módulo (👻)",
    )
    parser.add_argument(
        "--module", type=str, help="Filtrar por nome de módulo (ex: memory, nvidia)"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Contra-fact-check: validação tripla (declarações ↔ refs ↔ host)",
    )
    args = parser.parse_args()

    print("🔍 Parseando configuration.nix...")
    host_config = parse_host_config(HOST_CONFIG)
    print(f"   → {len(host_config)} paths kernelcore.* no host config")

    print("📂 Varrendo referências nos módulos...")
    module_refs = scan_module_references(MODULES_DIR)
    n_files = len(set.union(*module_refs.values())) if module_refs else 0
    print(f"   → {len(module_refs)} paths referenciados em {n_files} arquivos")

    if args.validate:
        print("📋 Varrendo declarações (mkOption/mkEnableOption)...")
        module_decls, decl_files = scan_module_declarations(MODULES_DIR)
        print(
            f"   → {len(module_decls)} opções declaradas (flat) em {len(decl_files)} arquivos com mkOption"
        )
        print("🔬 Executando contra-fact-check...")
        issues = validate(host_config, module_refs, module_decls, decl_files)
        print_validation_report(issues)
        return

    print("🔗 Cruzando referências...")
    rows = build_correlation(host_config, module_refs)

    if args.json:
        print_json(rows)
    elif args.unconfigured:
        print_table(rows, filter_status="NO_CONFIG", filter_module=args.module)
    elif args.unused:
        print_table(rows, filter_status="NO_MODULE", filter_module=args.module)
    else:
        print_table(rows, filter_module=args.module)


if __name__ == "__main__":
    main()
