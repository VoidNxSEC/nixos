# JS Packages Storage

This directory contains locally stored JavaScript/Node.js package tarballs for offline installation and reproducible builds.

## Files

### gemini-cli-v0.15.0-nightly.20251107.cd27cae8.tar.gz
- **Package**: Google Gemini CLI
- **Version**: 0.15.0-nightly.20251107.cd27cae8
- **Source**: https://github.com/google-gemini/gemini-cli/releases/tag/v0.15.0-nightly.20251107.cd27cae8
- **SHA256**: `a760b24312bb30b0f30a8fde932cd30fc8bb09b3f6dcca67f8fe0c4d5f798702`
- **Downloaded**: 2025-01-14
- **Purpose**: CLI tool for Google's Gemini Generative AI API

## Adding New Packages

1. Download the tarball from the official source
2. Calculate SHA256 hash: `sha256sum <file>.tar.gz`
3. Store the file in this directory
4. Update this README with package details
5. Create/update the corresponding package configuration in parent directory

## Verification

To verify integrity of stored files:
```bash
sha256sum -c <<EOF
a760b24312bb30b0f30a8fde932cd30fc8bb09b3f6dcca67f8fe0c4d5f798702  gemini-cli-v0.15.0-nightly.20251107.cd27cae8.tar.gz
EOF