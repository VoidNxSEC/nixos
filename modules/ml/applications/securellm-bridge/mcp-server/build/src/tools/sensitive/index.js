/**
 * Sensitive Data Handling Tools
 * Pseudonymization, encryption, and audit
 */
import * as fs from 'fs/promises';
import * as crypto from 'crypto';
// @ts-ignore
import { faker } from 'faker';
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);
/**
 * Data Scan Sensitive Tool
 */
export class DataScanSensitiveTool {
    patterns = {
        email: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g,
        phone: /\b(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}\b/g,
        ssn: /\b\d{3}-\d{2}-\d{4}\b/g,
        credit_card: /\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b/g,
        ip: /\b(?:\d{1,3}\.){3}\d{1,3}\b/g,
    };
    async execute(args) {
        const { paths, patterns = ['email', 'phone', 'ssn', 'credit_card', 'ip'], custom_regex = [], recursive = true } = args;
        try {
            const matches = [];
            let filesScanned = 0;
            for (const basePath of paths) {
                const files = await this.getFiles(basePath, recursive);
                for (const file of files) {
                    try {
                        const content = await fs.readFile(file, 'utf-8');
                        const lines = content.split('\n');
                        lines.forEach((line, index) => {
                            // Check predefined patterns
                            for (const pattern of patterns) {
                                if (pattern !== 'custom' && this.patterns[pattern]) {
                                    const regex = this.patterns[pattern];
                                    const lineMatches = line.match(regex);
                                    if (lineMatches) {
                                        matches.push({
                                            file,
                                            line: index + 1,
                                            type: pattern,
                                            context: this.maskContext(line, lineMatches),
                                        });
                                    }
                                }
                            }
                            // Check custom regex
                            for (const customPattern of custom_regex) {
                                try {
                                    const regex = new RegExp(customPattern, 'g');
                                    const lineMatches = line.match(regex);
                                    if (lineMatches) {
                                        matches.push({
                                            file,
                                            line: index + 1,
                                            type: 'custom',
                                            context: this.maskContext(line, lineMatches),
                                        });
                                    }
                                }
                                catch (error) {
                                    // Invalid regex, skip
                                }
                            }
                        });
                        filesScanned++;
                    }
                    catch (error) {
                        // Skip files we can't read (binary, permissions, etc.)
                    }
                }
            }
            return {
                success: true,
                data: {
                    files_scanned: filesScanned,
                    matches_found: matches.length,
                    matches: matches.slice(0, 100), // Limit to 100 for performance
                },
                warnings: matches.length > 0 ? [`Found ${matches.length} potential sensitive data occurrences`] : undefined,
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Sensitive data scan failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async getFiles(basePath, recursive) {
        const files = [];
        try {
            const entries = await fs.readdir(basePath, { withFileTypes: true });
            for (const entry of entries) {
                const fullPath = `${basePath}/${entry.name}`;
                if (entry.isDirectory() && recursive) {
                    files.push(...await this.getFiles(fullPath, recursive));
                }
                else if (entry.isFile()) {
                    files.push(fullPath);
                }
            }
        }
        catch (error) {
            // Skip directories we can't access
        }
        return files;
    }
    maskContext(line, matches) {
        let masked = line;
        for (const match of matches) {
            masked = masked.replace(match, '***REDACTED***');
        }
        return masked.substring(0, 100); // Limit context length
    }
}
/**
 * Data Pseudonymize Tool
 */
export class DataPseudonymizeTool {
    async execute(args) {
        const { input_file, output_file, fields, method, preserve_format = true } = args;
        try {
            const content = await fs.readFile(input_file, 'utf-8');
            let pseudonymized = content;
            // Parse as JSON/CSV and pseudonymize fields
            try {
                const data = JSON.parse(content);
                const processed = Array.isArray(data)
                    ? data.map(item => this.pseudonymizeObject(item, fields, method, preserve_format))
                    : this.pseudonymizeObject(data, fields, method, preserve_format);
                pseudonymized = JSON.stringify(processed, null, 2);
            }
            catch {
                // Not JSON, try line-by-line pseudonymization
                const lines = content.split('\n');
                pseudonymized = lines.map(line => this.pseudonymizeLine(line, fields, method)).join('\n');
            }
            await fs.writeFile(output_file, pseudonymized);
            return {
                success: true,
                data: {
                    input_file,
                    output_file,
                    fields_pseudonymized: fields.length,
                    method,
                    preserve_format,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Pseudonymization failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    pseudonymizeObject(obj, fields, method, preserveFormat) {
        const result = { ...obj };
        for (const field of fields) {
            if (result[field] !== undefined) {
                result[field] = this.pseudonymizeValue(result[field], method, preserveFormat);
            }
        }
        return result;
    }
    pseudonymizeLine(line, fields, method) {
        let result = line;
        // Simple replacement for common patterns
        for (const field of fields) {
            const patterns = {
                email: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g,
                phone: /\b\d{3}-\d{3}-\d{4}\b/g,
                name: /\b[A-Z][a-z]+ [A-Z][a-z]+\b/g,
            };
            if (patterns[field]) {
                result = result.replace(patterns[field], () => this.pseudonymizeValue('', method, true));
            }
        }
        return result;
    }
    pseudonymizeValue(value, method, preserveFormat) {
        switch (method) {
            case 'hash':
                return crypto.createHash('sha256').update(value).digest('hex').substring(0, 16);
            case 'encrypt':
                // Simplified - in production would use proper encryption
                return crypto.createHash('md5').update(value).digest('base64');
            case 'tokenize':
                return `TOKEN_${crypto.randomBytes(8).toString('hex')}`;
            case 'mask':
                if (value.includes('@')) {
                    // Email
                    return preserveFormat ? `***@${value.split('@')[1]}` : '***@email.com';
                }
                else if (/^\d+$/.test(value)) {
                    // Number
                    return preserveFormat ? '*'.repeat(value.length) : '****';
                }
                else {
                    // Generic
                    return preserveFormat ? value[0] + '*'.repeat(value.length - 1) : '***';
                }
            default:
                return faker.random.word();
        }
    }
}
/**
 * Data Encrypt Sensitive Tool (SOPS Integration)
 */
export class DataEncryptSensitiveTool {
    async execute(args) {
        const { file_path, operation, output_path, key_id } = args;
        try {
            const outputFile = output_path || `${file_path}.${operation === 'encrypt' ? 'enc' : 'dec'}`;
            if (operation === 'encrypt') {
                // Use SOPS for encryption
                const { stdout, stderr } = await execAsync(`sops --encrypt ${key_id ? `--kms ${key_id}` : ''} ${file_path} > ${outputFile}`);
                return {
                    success: true,
                    data: {
                        operation,
                        input_file: file_path,
                        output_file: outputFile,
                        encrypted: true,
                    },
                    timestamp: new Date().toISOString(),
                };
            }
            else {
                // Decrypt
                const { stdout, stderr } = await execAsync(`sops --decrypt ${file_path} > ${outputFile}`);
                return {
                    success: true,
                    data: {
                        operation,
                        input_file: file_path,
                        output_file: outputFile,
                        decrypted: true,
                    },
                    timestamp: new Date().toISOString(),
                };
            }
        }
        catch (error) {
            return {
                success: false,
                error: `${operation} failed: ${error.message}`,
                warnings: ['Ensure SOPS is installed and properly configured'],
                timestamp: new Date().toISOString(),
            };
        }
    }
}
/**
 * Data Audit Access Tool
 */
export class DataAuditAccessTool {
    async execute(args) {
        const { resource_type, resource_path, time_range } = args;
        try {
            let auditCommand = '';
            switch (resource_type) {
                case 'file':
                    // Use ausearch for file access audit
                    auditCommand = `ausearch -f ${resource_path} -ts recent 2>/dev/null || echo "Audit logs not available"`;
                    break;
                case 'service':
                    // Check systemd journal for service access
                    auditCommand = `journalctl -u ${resource_path} ${time_range ? `--since "${time_range.start}"` : ''} -n 50 --no-pager`;
                    break;
                case 'secret':
                    // Check for SOPS access logs
                    auditCommand = `grep -r "${resource_path}" /var/log/sops* 2>/dev/null || echo "No SOPS logs found"`;
                    break;
            }
            const { stdout } = await execAsync(auditCommand);
            // Parse audit log output
            const entries = stdout.split('\n').filter(l => l.trim()).slice(0, 50);
            return {
                success: true,
                data: {
                    resource_type,
                    resource_path,
                    audit_entries: entries,
                    entries_count: entries.length,
                    time_range: time_range || { start: 'recent', end: 'now' },
                },
                warnings: entries.length === 0 ? ['No audit entries found - audit logging may not be enabled'] : undefined,
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Audit access failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
// Export schemas
export const dataScanSensitiveSchema = {
    name: "data_scan_sensitive",
    description: "Scan files for sensitive data patterns (email, phone, SSN, etc.)",
    inputSchema: {
        type: "object",
        properties: {
            paths: { type: "array", items: { type: "string" }, description: "Paths to scan" },
            patterns: {
                type: "array",
                items: { type: "string", enum: ["email", "phone", "ssn", "credit_card", "ip", "custom"] },
                description: "Pattern types to detect",
            },
            custom_regex: { type: "array", items: { type: "string" }, description: "Custom regex patterns" },
            recursive: { type: "boolean", description: "Scan recursively (default: true)" },
        },
        required: ["paths"],
    },
};
export const dataPseudonymizeSchema = {
    name: "data_pseudonymize",
    description: "Pseudonymize sensitive data using various methods",
    inputSchema: {
        type: "object",
        properties: {
            input_file: { type: "string", description: "Input file path" },
            output_file: { type: "string", description: "Output file path" },
            fields: { type: "array", items: { type: "string" }, description: "Fields to pseudonymize" },
            method: { type: "string", enum: ["hash", "encrypt", "tokenize", "mask"] },
            preserve_format: { type: "boolean", description: "Preserve original format (default: true)" },
        },
        required: ["input_file", "output_file", "fields", "method"],
    },
};
export const dataEncryptSensitiveSchema = {
    name: "data_encrypt_sensitive",
    description: "Encrypt/decrypt sensitive files using SOPS",
    inputSchema: {
        type: "object",
        properties: {
            file_path: { type: "string", description: "File to encrypt/decrypt" },
            operation: { type: "string", enum: ["encrypt", "decrypt"] },
            output_path: { type: "string", description: "Output path (optional)" },
            key_id: { type: "string", description: "KMS key ID (optional)" },
        },
        required: ["file_path", "operation"],
    },
};
export const dataAuditAccessSchema = {
    name: "data_audit_access",
    description: "Audit access to sensitive resources",
    inputSchema: {
        type: "object",
        properties: {
            resource_type: { type: "string", enum: ["file", "service", "secret"] },
            resource_path: { type: "string", description: "Resource path or identifier" },
            time_range: {
                type: "object",
                properties: {
                    start: { type: "string" },
                    end: { type: "string" },
                },
            },
        },
        required: ["resource_type", "resource_path"],
    },
};
//# sourceMappingURL=index.js.map