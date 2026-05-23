# NNS Governance Explorer

A read-only MCP server for exploring NNS governance proposals, neurons, voting history, and network economics on the Internet Computer.

## Tools

| Tool | Description |
|------|-------------|
| `list_proposals` | Browse/filter NNS proposals by status, topic, reward status with pagination |
| `get_proposal` | Full details for a single proposal (summary, tally, action type, timestamps) |
| `get_neuron_info` | Look up neuron state, stake, voting power, dissolve delay |
| `list_known_neurons` | All registered known neurons with names, descriptions, links |
| `get_neuron_votes` | Voting history for a known neuron |
| `get_pending_proposals` | All currently open proposals accepting votes |
| `get_governance_metrics` | Total staked, neuron counts, dissolving statistics |
| `get_network_economics` | Current economic parameters (min stake, reject cost, etc.) |

## Architecture

This server is a **stateless proxy** — every tool call makes a real-time cross-canister query to the NNS Governance canister (`rrkah-fqaaa-aaaaa-aaaaq-cai`). No local storage, no caching, no auth required.

All integer codes from the governance canister (status, topic, reward status, neuron state, vote) are mapped to human-readable strings.

## MCP Endpoint

```
https://tlgyi-tqaaa-aaaal-qxcia-cai.icp0.io/mcp
```

## Development

```bash
npm install
mops install --lock ignore --no-toolchain
dfx start --background
dfx deploy
npm test
```

## License

MIT
