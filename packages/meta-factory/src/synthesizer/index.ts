// Synthesizer — placeholder (Phase 7)
// Path A: Conservative synthesis (plugin configuration)
// Path B: Creative synthesis (Phase 9+)
export type SynthesisResult = {
  preset: string;
  rules: string[];
};

export function synthesize(_stackInfo: unknown): SynthesisResult {
  throw new Error('synthesize: not yet implemented (Phase 7)');
}
