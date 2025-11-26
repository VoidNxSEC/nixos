/**
 * Laptop Defense Framework Tools
 *
 * MCP tools for thermal protection, hardware forensics, and rebuild safety
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';

const execAsync = promisify(exec);

export const laptopDefenseTools = [
  {
    name: "thermal_check",
    description: "Quick thermal check before operation (temperature verification)",
    // Core tool - always loaded
    inputSchema: {
      type: "object",
      properties: {
        max_temp: {
          type: "number",
          description: "Maximum acceptable temperature in °C (default: 75)",
          default: 75,
        },
      },
    },
  },
  {
    name: "thermal_forensics",
    description: "Run complete thermal forensics analysis (3-phase: baseline, stress, rebuild)",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        duration: {
          type: "number",
          description: "Test duration in seconds (default: 180)",
          default: 180,
        },
        skip_rebuild: {
          type: "boolean",
          description: "Skip rebuild phase (default: false)",
          default: false,
        },
      },
    },
  },
  {
    name: "thermal_warroom",
    description: "Launch real-time thermal monitoring war room (continuous display)",
    defer_loading: true,
    inputSchema: {
      type: "object",
      properties: {
        duration: {
          type: "number",
          description: "Monitor duration in seconds (default: 60)",
          default: 60,
        },
      },
    },
  },
  {
    name: "rebuild_safety_check",
    description: "Pre-rebuild safety check (thermal + resources + load)",
    // Core tool - always loaded
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "laptop_verdict",
    description: "Generate laptop replacement verdict from forensic evidence",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        evidence_dir: {
          type: "string",
          description: "Path to thermal evidence directory",
        },
      },
      required: ["evidence_dir"],
    },
  },
  {
    name: "full_investigation",
    description: "Run complete laptop investigation suite (forensics + verdict)",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "force_cooldown",
    description: "Force CPU to powersave mode (emergency thermal response)",
    defer_loading: true,
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "reset_performance",
    description: "Reset CPU to performance mode (after cooldown)",
    defer_loading: true,
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
];

interface ThermalCheckResult {
  current_temp: number;
  max_acceptable: number;
  safe: boolean;
  status: 'safe' | 'warning' | 'critical';
  message: string;
}

interface RebuildSafetyResult {
  thermal_temp: number;
  thermal_safe: boolean;
  memory_available_mb: number;
  memory_safe: boolean;
  load_average: number;
  load_safe: boolean;
  verdict: 'SAFE' | 'UNSAFE';
  reasons: string[];
}

interface ForensicsResult {
  success: boolean;
  evidence_dir: string;
  archive: string;
  phases_completed: string[];
  max_temp_observed: number;
  verdict_preview: string;
  message: string;
}

interface VerdictResult {
  score: number;
  critical_flags: number;
  verdict: 'REPLACE' | 'INVESTIGATE' | 'SOFTWARE_ISSUE';
  reasons: string[];
  recommendations: string[];
}

export async function handleThermalCheck(maxTemp: number = 75): Promise<ThermalCheckResult> {
  try {
    // Get current temperature using sensors
    const { stdout } = await execAsync('sensors 2>/dev/null | grep -oP "\\+\\K[0-9]+" | sort -rn | head -1 || echo "0"');
    const currentTemp = parseInt(stdout.trim()) || 0;

    let status: ThermalCheckResult['status'];
    let message: string;

    if (currentTemp <= maxTemp) {
      status = 'safe';
      message = `✅ SAFE: Temperature ${currentTemp}°C (limit: ${maxTemp}°C)`;
    } else if (currentTemp <= maxTemp + 10) {
      status = 'warning';
      message = `⚠️ WARNING: Temperature ${currentTemp}°C (limit: ${maxTemp}°C)`;
    } else {
      status = 'critical';
      message = `❌ CRITICAL: Temperature ${currentTemp}°C (limit: ${maxTemp}°C)`;
    }

    return {
      current_temp: currentTemp,
      max_acceptable: maxTemp,
      safe: currentTemp <= maxTemp,
      status,
      message,
    };
  } catch (error: any) {
    throw new Error(`Thermal check failed: ${error.message}`);
  }
}

export async function handleRebuildSafetyCheck(): Promise<RebuildSafetyResult> {
  try {
    const result: RebuildSafetyResult = {
      thermal_temp: 0,
      thermal_safe: false,
      memory_available_mb: 0,
      memory_safe: false,
      load_average: 0,
      load_safe: false,
      verdict: 'UNSAFE',
      reasons: [],
    };

    // Thermal check
    const { stdout: tempStr } = await execAsync('sensors 2>/dev/null | grep -oP "\\+\\K[0-9]+" | sort -rn | head -1 || echo "0"');
    result.thermal_temp = parseInt(tempStr.trim()) || 0;
    result.thermal_safe = result.thermal_temp <= 75;
    if (!result.thermal_safe) {
      result.reasons.push(`Temperature too high: ${result.thermal_temp}°C (limit: 75°C)`);
    }

    // Memory check
    const { stdout: memStr } = await execAsync("free -m | grep Mem | awk '{print $7}'");
    result.memory_available_mb = parseInt(memStr.trim()) || 0;
    result.memory_safe = result.memory_available_mb >= 2000;
    if (!result.memory_safe) {
      result.reasons.push(`Low memory: ${result.memory_available_mb}MB available (need: 2000MB)`);
    }

    // Load average check
    const { stdout: loadStr } = await execAsync("uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs | cut -d'.' -f1");
    result.load_average = parseInt(loadStr.trim()) || 0;
    result.load_safe = result.load_average <= 10;
    if (!result.load_safe) {
      result.reasons.push(`Load too high: ${result.load_average} (limit: 10)`);
    }

    // Overall verdict
    if (result.thermal_safe && result.memory_safe && result.load_safe) {
      result.verdict = 'SAFE';
    }

    return result;
  } catch (error: any) {
    throw new Error(`Rebuild safety check failed: ${error.message}`);
  }
}

export async function handleThermalForensics(duration: number = 180, skipRebuild: boolean = false): Promise<ForensicsResult> {
  try {
    // Run thermal forensics from flake
    const cmd = skipRebuild
      ? 'nix run /etc/nixos/modules/hardware/laptop-defense#thermal-forensics -- --skip-rebuild'
      : 'nix run /etc/nixos/modules/hardware/laptop-defense#thermal-forensics';

    const { stdout, stderr } = await execAsync(cmd, { timeout: duration * 1000 + 60000 });

    // Extract evidence directory from output
    const evidenceDirMatch = stdout.match(/Evidence:\s+(\/tmp\/thermal-evidence-[0-9-]+)/);
    const evidenceDir = evidenceDirMatch ? evidenceDirMatch[1] : '/tmp/thermal-evidence-latest';

    // Extract archive path
    const archiveMatch = stdout.match(/Archive:\s+(\/tmp\/thermal-evidence-[0-9-]+\.tar\.gz)/);
    const archive = archiveMatch ? archiveMatch[1] : '';

    // Extract max temperature
    const maxTempMatch = stdout.match(/Max Temperature:\s+(\d+)°C/);
    const maxTemp = maxTempMatch ? parseInt(maxTempMatch[1]) : 0;

    // Extract verdict preview
    const verdictMatch = stdout.match(/Verdict:\s+([A-Z_]+)/);
    const verdictPreview = verdictMatch ? verdictMatch[1] : 'UNKNOWN';

    return {
      success: true,
      evidence_dir: evidenceDir,
      archive,
      phases_completed: skipRebuild ? ['baseline', 'stress'] : ['baseline', 'stress', 'rebuild'],
      max_temp_observed: maxTemp,
      verdict_preview: verdictPreview,
      message: `Forensics complete. Evidence: ${evidenceDir}`,
    };
  } catch (error: any) {
    return {
      success: false,
      evidence_dir: '',
      archive: '',
      phases_completed: [],
      max_temp_observed: 0,
      verdict_preview: 'ERROR',
      message: `Forensics failed: ${error.message}`,
    };
  }
}

export async function handleThermalWarroom(duration: number = 60): Promise<{ success: boolean; samples: number; message: string }> {
  try {
    // Run warroom monitor for specified duration
    const { stdout } = await execAsync(`timeout ${duration}s nix run /etc/nixos/modules/hardware/laptop-defense#thermal-warroom || true`);

    // Count temperature samples
    const samples = (stdout.match(/°C/g) || []).length;

    return {
      success: true,
      samples,
      message: `Warroom monitor completed. Collected ${samples} temperature samples over ${duration}s.`,
    };
  } catch (error: any) {
    return {
      success: false,
      samples: 0,
      message: `Warroom monitor failed: ${error.message}`,
    };
  }
}

export async function handleLaptopVerdict(evidenceDir: string): Promise<VerdictResult> {
  try {
    // Run laptop verdict tool
    const { stdout } = await execAsync(`nix run /etc/nixos/modules/hardware/laptop-defense#verdict -- "${evidenceDir}"`);

    // Parse verdict output
    const scoreMatch = stdout.match(/Score:\s+(\d+)\/100/);
    const score = scoreMatch ? parseInt(scoreMatch[1]) : 0;

    const flagsMatch = stdout.match(/Critical Flags:\s+(\d+)/);
    const criticalFlags = flagsMatch ? parseInt(flagsMatch[1]) : 0;

    const verdictMatch = stdout.match(/VERDICT:\s+([A-Z_]+)/);
    let verdict: VerdictResult['verdict'] = 'SOFTWARE_ISSUE';
    if (verdictMatch) {
      const v = verdictMatch[1];
      if (v === 'REPLACE') verdict = 'REPLACE';
      else if (v === 'INVESTIGATE') verdict = 'INVESTIGATE';
    }

    // Extract reasons and recommendations
    const reasons: string[] = [];
    const recommendations: string[] = [];

    const reasonsSection = stdout.match(/Likely causes:(.*?)Recommended actions:/s);
    if (reasonsSection) {
      const reasonLines = reasonsSection[1].split('\n').filter(l => l.trim().startsWith('-'));
      reasons.push(...reasonLines.map(l => l.replace(/^-\s*/, '').trim()));
    }

    const recsSection = stdout.match(/Recommended actions:(.*?)(?:\n\n|$)/s);
    if (recsSection) {
      const recLines = recsSection[1].split('\n').filter(l => l.trim().match(/^\d+\./));
      recommendations.push(...recLines.map(l => l.replace(/^\d+\.\s*/, '').trim()));
    }

    return {
      score,
      critical_flags: criticalFlags,
      verdict,
      reasons,
      recommendations,
    };
  } catch (error: any) {
    throw new Error(`Verdict generation failed: ${error.message}`);
  }
}

export async function handleFullInvestigation(): Promise<{ forensics: ForensicsResult; verdict: VerdictResult }> {
  try {
    // Run full investigation (forensics + verdict)
    const { stdout } = await execAsync('nix run /etc/nixos/modules/hardware/laptop-defense#full-investigation');

    // Extract evidence directory
    const evidenceDirMatch = stdout.match(/Evidence:\s+(\/tmp\/thermal-evidence-[0-9-]+)/);
    const evidenceDir = evidenceDirMatch ? evidenceDirMatch[1] : '';

    // Run forensics
    const forensics = await handleThermalForensics(180, false);

    // Run verdict on evidence
    const verdict = evidenceDir ? await handleLaptopVerdict(evidenceDir) : {
      score: 0,
      critical_flags: 0,
      verdict: 'SOFTWARE_ISSUE' as const,
      reasons: ['Investigation incomplete'],
      recommendations: ['Retry full investigation'],
    };

    return { forensics, verdict };
  } catch (error: any) {
    throw new Error(`Full investigation failed: ${error.message}`);
  }
}

export async function handleForceCooldown(): Promise<{ success: boolean; message: string }> {
  try {
    const script = `
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo powersave | sudo tee $cpu > /dev/null 2>&1;
      done &&
      echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 &&
      echo "✅ Cooldown activated (powersave governor, turbo disabled)"
    `;

    const { stdout } = await execAsync(script);

    return {
      success: true,
      message: stdout.trim() || 'CPU forced to powersave mode',
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Force cooldown failed: ${error.message}`,
    };
  }
}

export async function handleResetPerformance(): Promise<{ success: boolean; message: string }> {
  try {
    const script = `
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance | sudo tee $cpu > /dev/null 2>&1;
      done &&
      echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 &&
      echo "✅ Performance mode restored"
    `;

    const { stdout } = await execAsync(script);

    return {
      success: true,
      message: stdout.trim() || 'CPU reset to performance mode',
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Performance reset failed: ${error.message}`,
    };
  }
}
