// Stack Detector — placeholder (Phase 4)
// Will extract logic from setup.sh:82-97 + scripts/detect-applicable-rules.ts
export type StackInfo = {
  name: string;
  version: string | null;
};

export function detectStack(_projectRoot: string): StackInfo {
  throw new Error('detectStack: not yet implemented (Phase 4)');
}
