// Package Download Tool - Download packages and calculate hashes
import { z } from "zod";
import { spawn } from "child_process";
import { mkdir } from "fs/promises";
import { createHash } from "crypto";
import { createReadStream } from "fs";
// Input schema for package_download tool
export const packageDownloadSchema = z.object({
    package_name: z.string().describe("Name of the package to download"),
    package_type: z.enum(["tar", "deb", "js"]).describe("Type of package system"),
    source: z.object({
        type: z.enum(["github_release", "npm", "url"]).describe("Source type"),
        url: z.string().optional().describe("Direct URL (for type: url)"),
        github: z.object({
            repo: z.string().describe("GitHub repo (owner/repo)"),
            tag: z.string().optional().describe("Release tag (latest if omitted)"),
            asset_pattern: z.string().optional().describe("Asset name pattern (regex)"),
        }).optional(),
        npm: z.object({
            package: z.string().describe("NPM package name"),
            version: z.string().optional().describe("Version (latest if omitted)"),
        }).optional(),
    }).describe("Source configuration"),
});
export class PackageDownloadTool {
    workspaceDir;
    constructor(workspaceDir) {
        this.workspaceDir = workspaceDir;
    }
    /**
     * Main download function
     */
    async download(input) {
        try {
            // Determine storage directory
            const storageDir = this.getStorageDir(input.package_type);
            await mkdir(`${this.workspaceDir}/${storageDir}`, { recursive: true });
            // Download based on source type
            let downloadedFile;
            let downloadUrl;
            switch (input.source.type) {
                case "github_release":
                    if (!input.source.github) {
                        return {
                            status: "error",
                            error: "GitHub configuration required for github_release source",
                        };
                    }
                    const githubResult = await this.downloadFromGitHub(input.source.github, storageDir, input.package_name);
                    if (!githubResult.success || !githubResult.file || !githubResult.url) {
                        return { status: "error", error: githubResult.error || "GitHub download failed" };
                    }
                    downloadedFile = githubResult.file;
                    downloadUrl = githubResult.url;
                    break;
                case "npm":
                    if (!input.source.npm) {
                        return {
                            status: "error",
                            error: "NPM configuration required for npm source",
                        };
                    }
                    const npmResult = await this.downloadFromNpm(input.source.npm, storageDir, input.package_name);
                    if (!npmResult.success || !npmResult.file || !npmResult.url) {
                        return { status: "error", error: npmResult.error || "NPM download failed" };
                    }
                    downloadedFile = npmResult.file;
                    downloadUrl = npmResult.url;
                    break;
                case "url":
                    if (!input.source.url) {
                        return {
                            status: "error",
                            error: "URL required for url source",
                        };
                    }
                    const urlResult = await this.downloadFromUrl(input.source.url, storageDir, input.package_name);
                    if (!urlResult.success || !urlResult.file) {
                        return { status: "error", error: urlResult.error || "URL download failed" };
                    }
                    downloadedFile = urlResult.file;
                    downloadUrl = input.source.url;
                    break;
                default:
                    return {
                        status: "error",
                        error: `Unsupported source type: ${input.source.type}`,
                    };
            }
            // Calculate SHA256
            const sha256 = await this.calculateSha256(downloadedFile);
            // Get file size
            const { size } = await this.getFileInfo(downloadedFile);
            // Generate config template
            const configTemplate = this.generateConfigTemplate(input.package_name, input.package_type, downloadedFile.replace(`${this.workspaceDir}/`, ""), sha256, downloadUrl);
            return {
                status: "success",
                downloaded_file: downloadedFile,
                storage_path: downloadedFile.replace(`${this.workspaceDir}/`, ""),
                sha256,
                size_bytes: size,
                config_template: {
                    package_file: `modules/packages/${input.package_type}-packages/packages/${input.package_name}.nix`,
                    content: configTemplate,
                },
            };
        }
        catch (error) {
            return {
                status: "error",
                error: error instanceof Error ? error.message : String(error),
            };
        }
    }
    /**
     * Download from GitHub release
     */
    async downloadFromGitHub(config, storageDir, packageName) {
        try {
            // Get latest release info
            const releaseInfo = await this.getGitHubReleaseInfo(config.repo, config.tag);
            if (!releaseInfo) {
                return {
                    success: false,
                    error: `Failed to get release info for ${config.repo}`,
                };
            }
            // Find matching asset
            const asset = this.findMatchingAsset(releaseInfo.assets, config.asset_pattern);
            if (!asset) {
                return {
                    success: false,
                    error: `No matching asset found. Pattern: ${config.asset_pattern}. Available: ${releaseInfo.assets.map(a => a.name).join(", ")}`,
                };
            }
            // Download the asset
            const filename = asset.name;
            const outputPath = `${this.workspaceDir}/${storageDir}/${filename}`;
            await this.downloadFile(asset.browser_download_url, outputPath);
            return {
                success: true,
                file: outputPath,
                url: asset.browser_download_url,
            };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : String(error),
            };
        }
    }
    /**
     * Get GitHub release info
     */
    async getGitHubReleaseInfo(repo, tag) {
        return new Promise((resolve) => {
            const url = tag
                ? `https://api.github.com/repos/${repo}/releases/tags/${tag}`
                : `https://api.github.com/repos/${repo}/releases/latest`;
            const curl = spawn("curl", ["-s", "-H", "Accept: application/vnd.github.v3+json", url]);
            let data = "";
            curl.stdout.on("data", (chunk) => {
                data += chunk.toString();
            });
            curl.on("close", () => {
                try {
                    const release = JSON.parse(data);
                    if (release.assets) {
                        resolve(release);
                    }
                    else {
                        resolve(null);
                    }
                }
                catch {
                    resolve(null);
                }
            });
        });
    }
    /**
     * Find matching asset from release
     */
    findMatchingAsset(assets, pattern) {
        if (!pattern) {
            // Return first .tar.gz, .tgz, or .deb file
            return assets.find(a => /\.(tar\.gz|tgz|deb)$/.test(a.name)) || assets[0] || null;
        }
        const regex = new RegExp(pattern);
        return assets.find(a => regex.test(a.name)) || null;
    }
    /**
     * Download from NPM
     */
    async downloadFromNpm(config, storageDir, packageName) {
        try {
            // Get package info
            const packageInfo = await this.getNpmPackageInfo(config.package, config.version);
            if (!packageInfo) {
                return {
                    success: false,
                    error: `Failed to get npm package info for ${config.package}`,
                };
            }
            const filename = `${packageName}-${packageInfo.version}.tar.gz`;
            const outputPath = `${this.workspaceDir}/${storageDir}/${filename}`;
            await this.downloadFile(packageInfo.tarball, outputPath);
            return {
                success: true,
                file: outputPath,
                url: packageInfo.tarball,
            };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : String(error),
            };
        }
    }
    /**
     * Get NPM package info
     */
    async getNpmPackageInfo(packageName, version) {
        return new Promise((resolve) => {
            const url = `https://registry.npmjs.org/${packageName}`;
            const curl = spawn("curl", ["-s", url]);
            let data = "";
            curl.stdout.on("data", (chunk) => {
                data += chunk.toString();
            });
            curl.on("close", () => {
                try {
                    const info = JSON.parse(data);
                    const targetVersion = version || info["dist-tags"]?.latest;
                    if (targetVersion && info.versions[targetVersion]) {
                        resolve({
                            version: targetVersion,
                            tarball: info.versions[targetVersion].dist.tarball,
                        });
                    }
                    else {
                        resolve(null);
                    }
                }
                catch {
                    resolve(null);
                }
            });
        });
    }
    /**
     * Download from direct URL
     */
    async downloadFromUrl(url, storageDir, packageName) {
        try {
            // Extract filename from URL or generate one
            const filename = url.split("/").pop() || `${packageName}-download`;
            const outputPath = `${this.workspaceDir}/${storageDir}/${filename}`;
            await this.downloadFile(url, outputPath);
            return {
                success: true,
                file: outputPath,
                url,
            };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : String(error),
            };
        }
    }
    /**
     * Download file using curl
     */
    async downloadFile(url, outputPath) {
        return new Promise((resolve, reject) => {
            const curl = spawn("curl", ["-L", "-o", outputPath, url]);
            curl.on("close", (code) => {
                if (code === 0) {
                    resolve();
                }
                else {
                    reject(new Error(`Failed to download file. Exit code: ${code}`));
                }
            });
            curl.on("error", (error) => {
                reject(error);
            });
        });
    }
    /**
     * Calculate SHA256 hash of a file
     */
    async calculateSha256(filePath) {
        return new Promise((resolve, reject) => {
            const hash = createHash("sha256");
            const stream = createReadStream(filePath);
            stream.on("data", (data) => hash.update(data));
            stream.on("end", () => resolve(hash.digest("hex")));
            stream.on("error", reject);
        });
    }
    /**
     * Get file information
     */
    async getFileInfo(filePath) {
        return new Promise((resolve, reject) => {
            const stat = spawn("stat", ["-c", "%s", filePath]);
            let size = "";
            stat.stdout.on("data", (data) => {
                size += data.toString();
            });
            stat.on("close", (code) => {
                if (code === 0) {
                    resolve({ size: parseInt(size.trim(), 10) });
                }
                else {
                    reject(new Error("Failed to get file info"));
                }
            });
        });
    }
    /**
     * Get storage directory for package type
     */
    getStorageDir(packageType) {
        switch (packageType) {
            case "tar":
                return "modules/packages/tar-packages/storage";
            case "deb":
                return "modules/packages/deb-packages/storage";
            case "js":
                return "modules/packages/js-packages/storage";
            default:
                return `modules/packages/${packageType}-packages/storage`;
        }
    }
    /**
     * Generate configuration template
     */
    generateConfigTemplate(packageName, packageType, storagePath, sha256, downloadUrl) {
        const filename = storagePath.split("/").pop();
        switch (packageType) {
            case "tar":
                return `# ${packageName} - Package Configuration
# Downloaded from: ${downloadUrl}
{
  ${packageName} = {
    enable = true;

    # Build method
    method = "native"; # or "fhs" for complex binaries

    # Source configuration
    source = {
      path = ../storage/${filename};
      sha256 = "${sha256}";
    };

    # Wrapper configuration
    wrapper = {
      executable = "${packageName}"; # Update with actual executable path
      environmentVariables = {
        # Add environment variables if needed
      };
    };

    # Sandbox configuration
    sandbox = {
      enable = false;
      blockHardware = [];
      allowedPaths = [];
    };

    # Audit configuration
    audit = {
      enable = true;
      logLevel = "info";
    };
  };
}
`;
            case "js":
                return `# ${packageName} - NPM Package Configuration
# Downloaded from: ${downloadUrl}
{ pkgs }:

pkgs.buildNpmPackage {
  pname = "${packageName}";
  version = "1.0.0"; # Update with actual version

  src = pkgs.fetchurl {
    url = "file://${storagePath}";
    sha256 = "${sha256}";
  };

  npmDepsHash = ""; # Run build once to get this hash

  # Add native dependencies if needed
  # nativeBuildInputs = with pkgs; [ pkg-config python3 ];
  # buildInputs = with pkgs; [ libsecret ];

  meta = with pkgs.lib; {
    description = "${packageName} package";
    platforms = platforms.linux;
  };
}
`;
            case "deb":
                return `# ${packageName} - DEB Package Configuration
# Downloaded from: ${downloadUrl}
{
  ${packageName} = {
    enable = true;

    # Source configuration
    source = {
      path = ../storage/${filename};
      sha256 = "${sha256}";
    };

    # Sandbox configuration
    sandbox = {
      enable = true;
      blockHardware = [];
      allowedPaths = [];
    };

    # Audit configuration
    audit = {
      enable = true;
      logLevel = "info";
    };

    # Desktop entry (optional)
    desktopEntry = null;
  };
}
`;
            default:
                return `# ${packageName} - Configuration Template
# Downloaded from: ${downloadUrl}
# SHA256: ${sha256}
# Storage: ${storagePath}
`;
        }
    }
}
//# sourceMappingURL=package-download.js.map