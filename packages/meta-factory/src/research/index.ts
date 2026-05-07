// Research Layer — placeholder (Phase 6)
// Will use MCP context7 for framework documentation retrieval
export type ResearchResult = {
  framework: string;
  docs: string[];
};

export function researchStack(_framework: string): Promise<ResearchResult> {
  throw new Error('researchStack: not yet implemented (Phase 6)');
}
