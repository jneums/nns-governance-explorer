/**
 * Tool-Specific Test Suite for NNS Governance Explorer
 * 
 * Tests all 8 tools via JSON-RPC over HTTP.
 * Note: Since this is a proxy to the NNS governance canister, tools that make
 * cross-canister calls will fail in PocketIC (no NNS subnet). We test:
 * 1. Tool discovery (all 8 tools listed)
 * 2. Input validation (missing required args)
 * 3. Tool invocation (verifying the handler runs, even if cross-canister fails)
 */

import { describe, beforeAll, afterAll, it, expect, inject } from 'vitest';
import { PocketIc, createIdentity } from '@dfinity/pic';
import { IDL } from '@icp-sdk/core/candid';
import { AnonymousIdentity } from '@icp-sdk/core/agent';
import { idlFactory as mcpServerIdlFactory } from '../.dfx/local/canisters/nns_governance_explorer/service.did.js';
import type { _SERVICE as McpServerService } from '../.dfx/local/canisters/nns_governance_explorer/service.did.d.ts';
import type { Actor } from '@dfinity/pic';
import path from 'node:path';

const MCP_SERVER_WASM_PATH = path.resolve(
  __dirname,
  '../.dfx/local/canisters/nns_governance_explorer/nns_governance_explorer.wasm',
);

// Helper to make an MCP tool call
async function callTool(
  actor: Actor<McpServerService>,
  toolName: string,
  args: Record<string, any>,
  id: string = 'test',
) {
  const rpcPayload = {
    jsonrpc: '2.0',
    method: 'tools/call',
    params: { name: toolName, arguments: args },
    id,
  };
  const body = new TextEncoder().encode(JSON.stringify(rpcPayload));
  const httpResponse = await actor.http_request_update({
    method: 'POST',
    url: '/mcp',
    headers: [['Content-Type', 'application/json']],
    body,
    certificate_version: [],
  });
  return {
    status: httpResponse.status_code,
    body: JSON.parse(new TextDecoder().decode(httpResponse.body as Uint8Array)),
  };
}

// Helper to list tools
async function listTools(actor: Actor<McpServerService>) {
  const rpcPayload = {
    jsonrpc: '2.0',
    method: 'tools/list',
    params: {},
    id: 'list-tools',
  };
  const body = new TextEncoder().encode(JSON.stringify(rpcPayload));
  const httpResponse = await actor.http_request_update({
    method: 'POST',
    url: '/mcp',
    headers: [['Content-Type', 'application/json']],
    body,
    certificate_version: [],
  });
  return JSON.parse(new TextDecoder().decode(httpResponse.body as Uint8Array));
}

describe('NNS Governance Explorer - Tool Tests', () => {
  let pic: PocketIc;
  let serverActor: Actor<McpServerService>;
  let canisterId: any;
  let testOwner = createIdentity('test-owner');

  beforeAll(async () => {
    const picUrl = inject('PIC_URL');
    pic = await PocketIc.create(picUrl);
    canisterId = await pic.createCanister();

    const initArg = IDL.encode(
      [IDL.Opt(IDL.Record({ owner: IDL.Opt(IDL.Principal) }))],
      [[{ owner: [testOwner.getPrincipal()] }]],
    );

    await pic.installCode({
      canisterId,
      wasm: MCP_SERVER_WASM_PATH,
      arg: initArg.buffer as ArrayBufferLike,
    });

    serverActor = pic.createActor<McpServerService>(
      mcpServerIdlFactory,
      canisterId,
    );
    serverActor.setIdentity(new AnonymousIdentity());
  });

  afterAll(async () => {
    await pic?.tearDown();
  });

  describe('Tool Discovery', () => {
    it('should list all 8 tools', async () => {
      const response = await listTools(serverActor);
      
      expect(response.result.tools).toBeDefined();
      const toolNames = response.result.tools.map((t: any) => t.name);
      
      expect(toolNames).toContain('list_proposals');
      expect(toolNames).toContain('get_proposal');
      expect(toolNames).toContain('get_neuron_info');
      expect(toolNames).toContain('list_known_neurons');
      expect(toolNames).toContain('get_neuron_votes');
      expect(toolNames).toContain('get_pending_proposals');
      expect(toolNames).toContain('get_governance_metrics');
      expect(toolNames).toContain('get_network_economics');
      expect(toolNames.length).toBe(8);
    });

    it('each tool should have name, description, and inputSchema', async () => {
      const response = await listTools(serverActor);
      const tools = response.result.tools;

      for (const tool of tools) {
        expect(tool.name).toBeDefined();
        expect(typeof tool.name).toBe('string');
        expect(tool.name.length).toBeGreaterThan(0);
        expect(tool.description).toBeDefined();
        expect(typeof tool.description).toBe('string');
        expect(tool.inputSchema).toBeDefined();
        expect(typeof tool.inputSchema).toBe('object');
      }
    });
  });

  describe('get_proposal - Input Validation', () => {
    it('should return error for missing proposal_id', async () => {
      const { body } = await callTool(serverActor, 'get_proposal', {});
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('proposal_id');
    });
  });

  describe('get_neuron_info - Input Validation', () => {
    it('should return error for missing neuron_id', async () => {
      const { body } = await callTool(serverActor, 'get_neuron_info', {});
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('neuron_id');
    });
  });

  describe('get_neuron_votes - Input Validation', () => {
    it('should return error for missing neuron_id', async () => {
      const { body } = await callTool(serverActor, 'get_neuron_votes', {});
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('neuron_id');
    });
  });

  // Cross-canister calls will fail in PocketIC since there's no NNS subnet.
  // We test that the tools at least invoke and return a structured error.
  describe('Cross-canister call handling', () => {
    it('list_proposals should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'list_proposals', {});
      // In PocketIC, the cross-canister call will fail
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('get_proposal should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'get_proposal', { proposal_id: 12345 });
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('get_neuron_info should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'get_neuron_info', { neuron_id: 1 });
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('list_known_neurons should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'list_known_neurons', {});
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('get_neuron_votes should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'get_neuron_votes', { neuron_id: 1 });
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('get_pending_proposals should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'get_pending_proposals', {});
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('get_governance_metrics should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'get_governance_metrics', {});
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });

    it('get_network_economics should handle cross-canister failure gracefully', async () => {
      const { body } = await callTool(serverActor, 'get_network_economics', {});
      expect(body.result).toBeDefined();
      expect(body.result.isError).toBe(true);
      expect(body.result.content[0].text).toContain('Failed to reach NNS governance canister');
    });
  });
});
