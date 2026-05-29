/**
 * AifHandoffBackend — adapter for the lee-to/aif-handoff MCP runtime.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 * NC-1 MCP SCHEMA DISCOVERY (kickoff §12 round-6 NC-1 requirement)
 * ═══════════════════════════════════════════════════════════════════════════
 * Discovered via:
 *   gh api repos/lee-to/aif-handoff/contents/packages/mcp/src/tools/createTask.ts
 *   gh api repos/lee-to/aif-handoff/contents/packages/mcp/src/tools/pushPlan.ts
 *   gh api repos/lee-to/aif-handoff/contents/packages/mcp/src/tools/syncStatus.ts
 *   gh api repos/lee-to/aif-handoff/contents/packages/mcp/src/tools/updateTask.ts
 *
 * Tool: handoff_create_task
 *   Source: packages/mcp/src/tools/createTask.ts (registerMcpTool call, line ~75)
 *   Args schema:
 *     projectId: string (UUID, required)
 *     title: string (required)
 *     description?: string
 *     plannerMode?: "fast" | "full"  -- default "full"
 *     planPath?: string              -- disk path; auto-generated if omitted
 *     autoMode?: boolean
 *     skipReview?: boolean
 *     paused?: boolean               -- create task in paused state
 *     ... (priority, tags, isFix, planDocs, planTests, useSubagents,
 *          maxReviewIterations, runtimeProfileId, modelOverride, runtimeOptions)
 *
 * CRITICAL FINDING — accept_existing_plan does NOT exist:
 *   The kickoff's original assumption that `accept_existing_plan` is a flag
 *   on `handoff_create_task` is INCORRECT. No such parameter is defined.
 *   (T1 adversarial checked: searched all tool files + index.ts — not found.)
 *
 * Planner-skip pattern (equivalent to accept_existing_plan):
 *   Step 1: handoff_create_task(paused:true, plannerMode:"fast")
 *     -> creates task in paused=true state (coordinator will not advance it)
 *   Step 2: handoff_push_plan(taskId, planContent)
 *     -> Source: packages/mcp/src/tools/pushPlan.ts (line ~55: setTaskFields)
 *     -> Writes our kickoff markdown as the task's plan field (DB + disk via syncPlanTextToCanonicalFile)
 *   Step 3: handoff_sync_status(taskId, "plan_ready", paused:false)
 *     -> Source: packages/mcp/src/tools/syncStatus.ts (z.enum(TASK_STATUSES))
 *     -> Sets status to "plan_ready" + clears paused flag in one atomic op
 *     -> Coordinator's PIPELINE picks up: plan_ready -> implementer (skips planner entirely)
 *
 * This 3-step sequence IS feasible and IS the correct planner-skip path.
 * PLAN.md disk coupling: handlePushPlan calls syncPlanTextToCanonicalFile
 * (packages/shared/src/planFile.ts) which writes plan to the project's
 * configured plan path (default PLAN.md). This means aif-handoff must be
 * running with access to the consumer project's filesystem (Docker volume mount
 * or local install). This is expected operating mode per aif-handoff docs.
 *
 * Tool: handoff_push_plan
 *   Source: packages/mcp/src/tools/pushPlan.ts
 *   Args: taskId: string (UUID), planContent: string (max 100KB)
 *   Side-effect: writes plan to DB + disk (project's PLAN.md)
 *
 * Tool: handoff_sync_status
 *   Source: packages/mcp/src/tools/syncStatus.ts
 *   Args: taskId, newStatus (TASK_STATUSES enum), sourceTimestamp, direction, paused?
 *
 * MCP server endpoint: default stdio transport (HTTP mode: port 3100 via MCP_PORT).
 * API server + WebSocket: default port 3009 (PORT env var, API_BASE_URL).
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * available(): HTTP GET reachability probe with 1s timeout.
 * dispatch(): 3-step planner-skip (create-paused -> push-plan -> sync-to-plan_ready).
 * getStatus(): REST GET /tasks/:id (non-blocking snapshot via aifWsStatus.getTaskStatus).
 * awaitDone(): WebSocket status event stream (via aifWsStatus.awaitTaskDone).
 *
 * @dual-pair: runtime-bridge-aif-handoff
 */
import type { RuntimeBackend } from './backend.js';
import { BackendError } from './backend.js';
import type { KickoffSpec, TaskHandle, TaskStatus, TaskResult } from './types.js';
import {
  awaitTaskDone,
  getTaskStatus,
  mapAifStatusToTaskStatus,
  type WebSocketConstructor,
} from './aifWsStatus.js';

/** Configuration for AifHandoffBackend. */
export interface AifHandoffConfig {
  /**
   * Base URL of the aif-handoff API server (REST + WebSocket).
   * Source: packages/shared/src/env.ts -- PORT default 3009, API_BASE_URL="http://localhost:3009"
   * Default: http://localhost:3009
   */
  readonly baseUrl?: string;
  /**
   * aif-handoff project ID (UUID). Required for task creation.
   * Consumers must configure this to match their aif-handoff project.
   */
  readonly projectId?: string;
  /**
   * WebSocket URL for the aif-handoff status event stream.
   * Source: packages/api/src/ws.ts -- app.get("/ws", upgradeWebSocket(...))
   * Same server as baseUrl (port 3009 by default).
   * Default: derived from baseUrl (http->ws, append /ws)
   */
  readonly wsUrl?: string;
  /**
   * Optional file path to append task status updates to (append-only, no schema rewrite).
   * When set, each status event is appended as a line: [ISO] taskId=<id> status=<status>
   * When unset, status processing is a clean no-op.
   */
  readonly stateFilePath?: string;
  /**
   * Dependency injection: custom WebSocket constructor (for testing).
   * Default: WebSocket from node:http (undici-based, available since Node 22.5+).
   */
  readonly WebSocketImpl?: WebSocketConstructor;
}

export class AifHandoffBackend implements RuntimeBackend {
  readonly name = 'aif-handoff' as const;

  private readonly baseUrl: string;
  private readonly projectId: string | undefined;
  private readonly wsUrl: string;
  private readonly stateFilePath: string | undefined;
  private readonly WebSocketImpl: WebSocketConstructor | undefined;

  constructor(config: AifHandoffConfig = {}) {
    this.baseUrl = config.baseUrl ?? 'http://localhost:3009';
    this.projectId = config.projectId;
    this.wsUrl = config.wsUrl ?? AifHandoffBackend._deriveWsUrl(this.baseUrl);
    this.stateFilePath = config.stateFilePath;
    this.WebSocketImpl = config.WebSocketImpl;
  }

  /** Derive ws:// URL from http:// baseUrl (same host:port, append /ws). */
  private static _deriveWsUrl(httpUrl: string): string {
    return httpUrl.replace(/^http(s?):\/\//, (_match: string, s: string) => `ws${s}://`) + '/ws';
  }

  async available(): Promise<boolean> {
    // Cheap reachability probe: GET /health (or root) with 1s timeout.
    // Returns true on any 2xx or 4xx (server is up but auth needed is still
    // "available"). Returns false on connection refused, ECONNREFUSED, timeout.
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 1000);
      try {
        const res = await fetch(`${this.baseUrl}/health`, {
          method: 'GET',
          signal: controller.signal,
        });
        return res.status < 500;
      } finally {
        clearTimeout(timeoutId);
      }
    } catch {
      return false;
    }
  }

  async dispatch(kickoff: KickoffSpec): Promise<TaskHandle> {
    if (!this.projectId) {
      throw new BackendError(
        'AifHandoffBackend requires projectId -- set RUNTIME_BRIDGE_AIF_PROJECT_ID env var',
        'dispatch_failed',
        'aif-handoff',
      );
    }

    // -- Step 1: Create task in paused state (planner-skip pattern, NC-1) --
    const createResult = await this._mcpCall('handoff_create_task', {
      projectId: this.projectId,
      title: kickoff.umbrellaName,
      description: `Runtime-bridge dispatch: ${kickoff.filePath}`,
      plannerMode: 'fast',    // fast mode uses planPath if provided
      paused: true,           // coordinator will not advance until we unblock
      autoMode: true,
      skipReview: false,      // reviewer runs per reviewer-discipline.md §2
    });

    if (!createResult || typeof createResult !== 'object' || !('id' in createResult)) {
      throw new BackendError(
        'handoff_create_task returned unexpected shape',
        'dispatch_failed',
        'aif-handoff',
      );
    }
    const taskId = (createResult as { id: string }).id;

    // -- Step 2: Push our kickoff content as the task plan ------------------
    // handoff_push_plan writes kickoff to DB field + disk (PLAN.md).
    // Source: packages/mcp/src/tools/pushPlan.ts (setTaskFields call ~line 55).
    await this._mcpCall('handoff_push_plan', {
      taskId,
      planContent: kickoff.content,
    });

    // -- Step 3: Transition to plan_ready to skip planner -------------------
    // Source: packages/mcp/src/tools/syncStatus.ts
    // This is the atomic planner-skip: paused:false + status:"plan_ready"
    // -> coordinator PIPELINE picks up at implementer stage.
    await this._mcpCall('handoff_sync_status', {
      taskId,
      newStatus: 'plan_ready',
      sourceTimestamp: new Date().toISOString(),
      direction: 'handoff_to_aif',
      paused: false,
    });

    return {
      backend: 'aif-handoff',
      taskId,
      dispatchedAt: new Date().toISOString(),
    };
  }

  async getStatus(handle: TaskHandle): Promise<TaskStatus> {
    // Non-blocking point-in-time snapshot via REST GET /tasks/:id.
    // Source: aifWsStatus.getTaskStatus -> packages/api/src/routes/tasks.ts GET /:id
    // REST is used (not WS) because getStatus must NOT block.
    // WS is subscribe-and-wait; REST returns immediately.
    const { rawStatus, checkedAt } = await getTaskStatus(handle.taskId, this.baseUrl);
    return {
      status: mapAifStatusToTaskStatus(rawStatus),
      rawStatus,
      checkedAt,
    };
  }

  async awaitDone(handle: TaskHandle, timeoutMs?: number): Promise<TaskResult> {
    // Real WebSocket status readback via aif-handoff broadcast stream.
    // Source: aifWsStatus.awaitTaskDone -> ws://localhost:3009/ws
    // WS event: { type: "task:updated", payload: { id, title, status } }
    // taskId filter: payload.id === handle.taskId (client-side, per kickoff §3 SW-C item 2)
    // Terminal states: done/verified -> success; blocked_external -> !success (resolves, not throws)
    // Transport failures (disconnect after retries) -> throws BackendError('unavailable')
    try {
      const result = await awaitTaskDone({
        taskId: handle.taskId,
        wsUrl: this.wsUrl,
        stateFilePath: this.stateFilePath,
        timeoutMs,
        WebSocketImpl: this.WebSocketImpl,
      });
      return {
        success: result.success,
        content: '',
        finalStatus: result.finalStatus,
        completedAt: result.completedAt,
      };
    } catch (err) {
      // Re-throw BackendErrors (unavailable, timeout) as-is.
      // Other errors are wrapped as dispatch_failed.
      if (err instanceof BackendError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new BackendError(
        `aif-handoff awaitDone unexpected error for task ${handle.taskId}: ${msg}`,
        'dispatch_failed',
        'aif-handoff',
      );
    }
  }

  // -- Private helpers -------------------------------------------------------

  /**
   * Call an aif-handoff MCP tool via HTTP JSON-RPC.
   * aif-handoff's MCP server exposes tools at POST /mcp (JSON-RPC 2.0).
   * Note: MCP HTTP mode uses port 3100 (MCP_PORT env); default is stdio.
   * The baseUrl here points at the API server (port 3009) which hosts /mcp
   * when MCP_TRANSPORT=http is set. In stdio mode, this path is unused for
   * status -- only dispatch() uses _mcpCall for write operations.
   */
  private async _mcpCall(tool: string, args: Record<string, unknown>): Promise<unknown> {
    let res: Response;
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10_000);
      try {
        res = await fetch(`${this.baseUrl}/mcp`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            jsonrpc: '2.0',
            id: crypto.randomUUID(),
            method: 'tools/call',
            params: { name: tool, arguments: args },
          }),
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timeoutId);
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      if (msg.includes('abort') || msg.includes('timeout')) {
        throw new BackendError(
          `aif-handoff MCP call timed out (${tool})`,
          'unavailable',
          'aif-handoff',
        );
      }
      throw new BackendError(
        `aif-handoff MCP unreachable during ${tool}: ${msg}`,
        'unavailable',
        'aif-handoff',
      );
    }

    if (!res.ok) {
      const body = await res.text().catch(() => '');
      if (res.status === 429) {
        throw new BackendError(
          `aif-handoff rate limit (${tool}): ${body}`,
          'quota_exceeded',
          'aif-handoff',
        );
      }
      throw new BackendError(
        `aif-handoff MCP ${tool} HTTP ${res.status}: ${body}`,
        'dispatch_failed',
        'aif-handoff',
      );
    }

    const json = (await res.json()) as {
      result?: { content?: Array<{ text?: string }> };
      error?: { message?: string };
    };

    if (json.error) {
      throw new BackendError(
        `aif-handoff MCP ${tool} error: ${json.error.message ?? JSON.stringify(json.error)}`,
        'dispatch_failed',
        'aif-handoff',
      );
    }

    // MCP tools return content[0].text as JSON string -- parse it.
    const textContent = json.result?.content?.[0]?.text;
    if (typeof textContent === 'string') {
      try {
        return JSON.parse(textContent) as unknown;
      } catch {
        return textContent;
      }
    }
    return json.result;
  }
}
