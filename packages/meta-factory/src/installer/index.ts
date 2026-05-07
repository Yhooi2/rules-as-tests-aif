// Installer — placeholder (Phase 8)
// Will extend install.sh logic with workspace-aware installation
export type InstallOptions = {
  projectRoot: string;
  preset: string;
  force?: boolean;
  dryRun?: boolean;
};

export function install(_options: InstallOptions): void {
  throw new Error('install: not yet implemented (Phase 8)');
}
