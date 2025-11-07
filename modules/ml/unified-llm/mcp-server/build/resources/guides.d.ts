export interface GuideMetadata {
    uri: string;
    name: string;
    description: string;
    category: 'guide' | 'skill' | 'prompt';
    tags: string[];
}
export declare class GuideManager {
    private guidesPath;
    private skillsPath;
    private promptsPath;
    constructor(baseDir?: string);
    loadGuide(name: string): Promise<string>;
    loadSkill(name: string): Promise<string>;
    loadPrompt(name: string): Promise<string>;
    listGuides(): Promise<GuideMetadata[]>;
    listSkills(): Promise<GuideMetadata[]>;
    listPrompts(): Promise<GuideMetadata[]>;
    listAll(): Promise<GuideMetadata[]>;
    private listMarkdownFiles;
    private extractTags;
    private extractDescription;
}
//# sourceMappingURL=guides.d.ts.map