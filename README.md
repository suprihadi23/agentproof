# 🛡️ AgentProof — Proof-of-Agent Reputation for Agent ID Holders

**Live site:** https://suprihadi23.github.io/agentproof/
**Contract (BNB Chain mainnet):** 0x3E49211d5a4e338a093A4593758eBe392Bf02244
**Agent ID registry (SPACE ID):** `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`

AgentProof is an on-chain reputation layer for the AI-agent economy, built for the
**Binance Wallet × BNB Chain Agent ID Hackathon**.

## The problem

Anyone can spin up an AI agent, but there is no portable, verifiable way to answer
two simple questions about an agent before you trust it with work:

1. Is this agent backed by a real, unique, verified identity?
2. Does it show up consistently, and do other verified agents vouch for it?

## How AgentProof uses Agent ID — at the core, not as decoration

Every state-changing function in `AgentProof.sol` is gated by an on-chain check
against the SPACE ID Agent ID registry: `balanceOf(msg.sender) > 0`. Agent ID is
soulbound and one-per-person, so it acts as the Sybil-resistance and identity
layer for the whole product:

- **Agent cards** — a registered URI describing what an agent does, anchored to
  a verified Agent ID identity.
- **Daily check-ins** — a proof-of-presence streak that proves an agent is alive
  and active over time, not a one-off registration.
- **Peer endorsements** — Agent ID holders endorse other registered agents for
  skill tags (trading, coding, research, …), forming a trust graph where every
  edge is backed by a verified identity on both sides.
- **Reputation points** — a non-transferable on-chain score derived from the
  above. Not a token, no monetary value, cannot be withdrawn or traded.

Because AgentProof is agent-native, an AI agent operating a Binance Agentic
Wallet can check in and endorse directly through the `baw` CLI — see
[agent.md](agent.md).

## Safety & compliance by design

- The contract is **non-payable**: it can never receive, hold, or move user funds.
- No QR-code / pairing-code login, no session storage, no seed/private-key
  collection — users connect their own wallet and confirm every transaction
  themselves.
- No promise of returns; reputation points are explicitly valueless.
- AgentProof is **not** a name→wallet lookup tool: it never resolves other
  people's Agent IDs to addresses. It only verifies the *caller's own* holding.
- Owner permissions are minimal and disclosed in the contract source:
  an emergency `setPaused` and `transferOwnership` — nothing else. The owner
  cannot mint points, alter profiles, or touch funds (there are none).

## Tech

- Solidity 0.8.24, no external dependencies, ~5.4 KB runtime.
- 10/10 Foundry tests pass (`contracts/`, `test/`).
- Static frontend (single HTML file, ethers.js v6) — `frontend/index.html`.
- Reads via public BSC RPC; writes via the user's own wallet on BNB Chain.

## Run the tests

```bash
forge test
```

## License

MIT
