---
name: Security Issue
about: Report a security vulnerability or concern (PRIVATE DISCLOSURE)
title: '[SECURITY] '
labels: security
assignees: ''
---

## ⚠️ Security Disclosure Notice

**IMPORTANT**: If this is a critical security vulnerability, please **DO NOT** open a public issue.
Instead, report it privately via:
- Email: [your-security-email@example.com]
- GitHub Security Advisory: https://github.com/user/repo/security/advisories/new

---

## Security Issue Description

A clear description of the security concern or vulnerability.

## Severity Assessment

Please rate the severity:

- [ ] **Critical** - Immediate exploitation possible, significant impact
- [ ] **High** - Exploitation likely, serious impact
- [ ] **Medium** - Exploitation possible with moderate impact
- [ ] **Low** - Limited exploitability or impact
- [ ] **Info** - Security improvement or hardening suggestion

## Affected Components

Which components are affected?

- [ ] Security modules (`modules/security/`, `sec/`)
- [ ] Secrets management (SOPS)
- [ ] Network configuration
- [ ] Firewall rules
- [ ] Container security
- [ ] Kernel hardening
- [ ] Other: _______________

## Attack Vector

How could this be exploited?

**Access Required**:
- [ ] No authentication required (remote)
- [ ] Local access required
- [ ] Physical access required
- [ ] Requires specific configuration

**Attack Complexity**:
- [ ] Low (easy to exploit)
- [ ] Medium (requires some skill)
- [ ] High (difficult to exploit)

## Impact

What is the potential impact?

- [ ] Unauthorized access
- [ ] Data exposure
- [ ] Privilege escalation
- [ ] Denial of service
- [ ] Code execution
- [ ] Other: _______________

## Steps to Reproduce

If safe to disclose publicly:

1. ...
2. ...
3. ...

## Proof of Concept

If applicable and safe to share:

```bash
# PoC code or commands
```

## Affected Versions

- **Commit Hash**: <!-- git rev-parse HEAD -->
- **NixOS Version**: <!-- nixos-version -->
- **Introduced in**: <!-- If known -->

## Proposed Fix

If you have suggestions for mitigation:

```nix
# Example hardening configuration
```

## Workaround

Is there a temporary workaround?

```bash
# Workaround commands
```

## References

Related CVEs, security advisories, or documentation:

- CVE-XXXX-XXXXX
- https://...

## Disclosure Timeline

For coordinated disclosure:

- [ ] I agree to 90-day disclosure timeline
- [ ] I need immediate public disclosure
- [ ] Other timeline: _______________

---

## Maintainer Checklist

For maintainers:

- [ ] Severity confirmed
- [ ] Affected versions identified
- [ ] Fix developed and tested
- [ ] Security advisory published
- [ ] CVE requested (if applicable)
- [ ] Users notified
