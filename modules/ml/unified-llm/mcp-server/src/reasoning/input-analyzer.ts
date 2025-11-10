/**
 * Input Analyzer
 * 
 * Analyzes user input to extract intent, entities, and topics.
 * Uses keyword matching and pattern recognition.
 */

import type { InputAnalysis, Intent, Entity, Topic, Confidence } from '../types/context-inference.js';

/**
 * Keywords for intent classification
 */
const INTENT_KEYWORDS: Record<Intent, string[]> = {
  query: ['what', 'how', 'why', 'when', 'where', 'explain', 'show', 'list', 'find'],
  command: ['run', 'execute', 'start', 'stop', 'restart', 'kill'],
  edit: ['change', 'modify', 'update', 'fix', 'correct', 'replace'],
  create: ['create', 'add', 'new', 'generate', 'init', 'make'],
  debug: ['debug', 'error', 'bug', 'issue', 'problem', 'fail', 'crash'],
  refactor: ['refactor', 'improve', 'optimize', 'clean', 'reorganize'],
  test: ['test', 'verify', 'check', 'validate', 'assert'],
  build: ['build', 'compile', 'bundle', 'package'],
  deploy: ['deploy', 'publish', 'release', 'ship'],
  unknown: [],
};

/**
 * Entity patterns (simple regex-based extraction)
 */
const ENTITY_PATTERNS: Array<{ type: Entity['type']; pattern: RegExp }> = [
  { type: 'file', pattern: /([a-zA-Z0-9_-]+\.[a-z]{1,4})\b/g },
  { type: 'file', pattern: /([a-zA-Z0-9_-]+\/[a-zA-Z0-9_/-]+\.[a-z]{1,4})\b/g },
  { type: 'function', pattern: /\b([a-z][a-zA-Z0-9]*)\s*\(/g },
  { type: 'module', pattern: /\bmodules?\/([a-zA-Z0-9_/-]+)/g },
  { type: 'error', pattern: /\berror[:\s]+([A-Z][a-zA-Z0-9]*)/gi },
  { type: 'package', pattern: /\b(npm|cargo|cabal|zig)\s+([a-z][a-z0-9-]+)/gi },
  { type: 'command', pattern: /`([^`]+)`/g },
];

/**
 * Input Analyzer
 */
export class InputAnalyzer {
  /**
   * Analyze user input
   */
  public analyze(text: string): InputAnalysis {
    const normalizedText = text.toLowerCase();
    
    return {
      intent: this.classifyIntent(normalizedText),
      intentConfidence: this.calculateIntentConfidence(normalizedText),
      entities: this.extractEntities(text),
      topics: this.extractTopics(normalizedText),
      text,
      timestamp: Date.now(),
    };
  }

  /**
   * Classify intent from text
   */
  private classifyIntent(text: string): Intent {
    const scores: Record<Intent, number> = {
      query: 0,
      command: 0,
      edit: 0,
      create: 0,
      debug: 0,
      refactor: 0,
      test: 0,
      build: 0,
      deploy: 0,
      unknown: 0,
    };

    // Score each intent based on keyword matches
    for (const [intent, keywords] of Object.entries(INTENT_KEYWORDS)) {
      if (intent === 'unknown') continue;
      
      for (const keyword of keywords) {
        if (text.includes(keyword)) {
          scores[intent as Intent] += 1;
        }
      }
    }

    // Find highest scoring intent
    let maxScore = 0;
    let bestIntent: Intent = 'unknown';
    
    for (const [intent, score] of Object.entries(scores)) {
      if (score > maxScore) {
        maxScore = score;
        bestIntent = intent as Intent;
      }
    }

    return bestIntent;
  }

  /**
   * Calculate intent confidence
   */
  private calculateIntentConfidence(text: string): Confidence {
    const intent = this.classifyIntent(text);
    const keywords = INTENT_KEYWORDS[intent];
    
    const matchCount = keywords.filter(kw => text.includes(kw)).length;
    
    if (matchCount >= 3) return 'high';
    if (matchCount >= 1) return 'medium';
    return 'low';
  }

  /**
   * Extract entities from text
   */
  private extractEntities(text: string): Entity[] {
    const entities: Entity[] = [];
    const seen = new Set<string>();

    for (const { type, pattern } of ENTITY_PATTERNS) {
      const matches = text.matchAll(pattern);
      
      for (const match of matches) {
        const value = match[1] || match[0];
        const key = `${type}:${value}`;
        
        if (seen.has(key)) continue;
        seen.add(key);
        
        entities.push({
          type,
          value,
          position: { start: match.index || 0, end: (match.index || 0) + match[0].length },
          confidence: 'medium',
        });
      }
    }

    return entities;
  }

  /**
   * Extract topics from text
   */
  private extractTopics(text: string): Topic[] {
    const topics: Topic[] = [];
    
    // Technical domains
    const domains: Record<string, string[]> = {
      'nix': ['nix', 'nixos', 'flake', 'derivation', 'package'],
      'git': ['git', 'commit', 'branch', 'merge', 'rebase'],
      'build': ['build', 'compile', 'cmake', 'make', 'cargo'],
      'security': ['security', 'auth', 'oauth', 'token', 'encrypt'],
      'testing': ['test', 'spec', 'assert', 'mock', 'coverage'],
      'performance': ['performance', 'optimize', 'profile', 'benchmark'],
      'database': ['database', 'sql', 'query', 'index', 'migration'],
    };

    for (const [topic, keywords] of Object.entries(domains)) {
      const matches = keywords.filter(kw => text.includes(kw));
      
      if (matches.length > 0) {
        topics.push({
          name: topic,
          relevance: matches.length / keywords.length,
          keywords: matches,
        });
      }
    }

    // Sort by relevance
    return topics.sort((a, b) => b.relevance - a.relevance);
  }
}