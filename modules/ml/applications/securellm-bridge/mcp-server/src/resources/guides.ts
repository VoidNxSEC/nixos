import * as fs from 'fs/promises';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export interface GuideMetadata {
  uri: string;
  name: string;
  description: string;
  category: 'guide' | 'skill' | 'prompt';
  tags: string[];
}

export class GuideManager {
  private guidesPath: string;
  private skillsPath: string;
  private promptsPath: string;

  constructor(baseDir?: string) {
    const docsPath = baseDir || path.join(__dirname, '../../docs');
    this.guidesPath = path.join(docsPath, 'guides');
    this.skillsPath = path.join(docsPath, 'skills');
    this.promptsPath = path.join(docsPath, 'prompts');
  }

  async loadGuide(name: string): Promise<string> {
    try {
      const content = await fs.readFile(
        path.join(this.guidesPath, `${name}.md`),
        'utf-8'
      );
      return content;
    } catch (error: any) {
      throw new Error(`Guide not found: ${name}`);
    }
  }

  async loadSkill(name: string): Promise<string> {
    try {
      const content = await fs.readFile(
        path.join(this.skillsPath, `${name}.md`),
        'utf-8'
      );
      return content;
    } catch (error: any) {
      throw new Error(`Skill not found: ${name}`);
    }
  }

  async loadPrompt(name: string): Promise<string> {
    try {
      const content = await fs.readFile(
        path.join(this.promptsPath, `${name}.md`),
        'utf-8'
      );
      return content;
    } catch (error: any) {
      throw new Error(`Prompt not found: ${name}`);
    }
  }

  async listGuides(): Promise<GuideMetadata[]> {
    return this.listMarkdownFiles(this.guidesPath, 'guide');
  }

  async listSkills(): Promise<GuideMetadata[]> {
    return this.listMarkdownFiles(this.skillsPath, 'skill');
  }

  async listPrompts(): Promise<GuideMetadata[]> {
    return this.listMarkdownFiles(this.promptsPath, 'prompt');
  }

  async listAll(): Promise<GuideMetadata[]> {
    const [guides, skills, prompts] = await Promise.all([
      this.listGuides(),
      this.listSkills(),
      this.listPrompts(),
    ]);
    return [...guides, ...skills, ...prompts];
  }

  private async listMarkdownFiles(
    dirPath: string,
    category: 'guide' | 'skill' | 'prompt'
  ): Promise<GuideMetadata[]> {
    try {
      await fs.access(dirPath);
      const files = await fs.readdir(dirPath);
      const mdFiles = files.filter(f => f.endsWith('.md'));

      const metadata = await Promise.all(
        mdFiles.map(async (file) => {
          const name = file.replace('.md', '');
          const content = await fs.readFile(path.join(dirPath, file), 'utf-8');
          const firstLine = content.split('\n')[0];
          const title = firstLine.startsWith('#')
            ? firstLine.replace(/^#+\s*/, '')
            : name;

          // Extract tags from front matter or content
          const tags = this.extractTags(content);

          return {
            uri: `${category}://${name}`,
            name: title,
            description: this.extractDescription(content),
            category,
            tags,
          };
        })
      );

      return metadata;
    } catch (error) {
      // Directory doesn't exist yet
      return [];
    }
  }

  private extractTags(content: string): string[] {
    const tagMatch = content.match(/tags:\s*\[(.*?)\]/i);
    if (tagMatch) {
      return tagMatch[1].split(',').map(t => t.trim().replace(/['"]/g, ''));
    }
    return [];
  }

  private extractDescription(content: string): string {
    const lines = content.split('\n');
    // Skip title line and find first non-empty paragraph
    for (let i = 1; i < Math.min(lines.length, 10); i++) {
      const line = lines[i].trim();
      if (line && !line.startsWith('#') && !line.startsWith('---')) {
        return line.substring(0, 150) + (line.length > 150 ? '...' : '');
      }
    }
    return 'No description available';
  }
}