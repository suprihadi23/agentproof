# Hackathon submission — draft materials

Submit during the Submission Period: **2026-11-18 08:00 UTC → 2026-12-09 08:00 UTC**
(18 Nov 15:00 WIB → 9 Dec 15:00 WIB) via the official campaign survey:
https://app.binance.com/uni-qr/user-survey/ff6832f8d2984af289068c9450a3c98c
(the survey link appears in the official announcement; confirm at submit time
whether the same form collects project submissions and/or X-post links.)

## Fields

- **Project name:** AgentProof
- **Website:** https://suprihadi23.github.io/agentproof/
- **Contract address (BNB Chain, verified on BscScan):** 0x3E49211d5a4e338a093A4593758eBe392Bf02244
- **GitHub (open source):** https://github.com/suprihadi23/agentproof (after push)
- **Reward receiving address:** TBD by user at submit time (suggestion: the Agentic Wallet 0xe0b00a56904247Ca5Ce23640037488b2dc4955c2, or the deployer wallet)

## Agent ID usage description (draft)

AgentProof is an on-chain reputation registry for the AI-agent economy in which
Agent ID is the identity and Sybil-resistance layer of every core flow. The
contract checks the SPACE ID Agent ID registry (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F)
on every state-changing call: only wallets holding a soulbound .ai Agent ID can
(1) register an agent card, (2) check in daily to build a proof-of-presence
streak, and (3) endorse other registered agents for skill tags, building a
peer trust graph in which both sides of every endorsement are verified Agent ID
holders. Endorsement targets must also still hold an Agent ID and be registered.
The resulting reputation score is non-transferable and derives entirely from
Agent-ID-verified activity. AgentProof is agent-native: AI agents operating
Binance Agentic Wallets interact directly via the baw CLI (see agent.md in the
repo). The contract is non-payable and can never custody user funds.

## Award strategy

- **Innovation Award** (judged): needs ≥30 unique Agent ID addresses interacting
  with the contract during the submission period + strong scores on Agent ID
  depth (30%), practicality (25%), completion (25%), innovation (20%).
- **Ecosystem Growth Award** (data): ranked by number of interacting Agent ID
  addresses / transactions — daily check-ins are designed to recur.
- Each project can win only one award. Winners also get a two-digit Agent ID
  eligibility spot.
- **Community Promotion (separate, 20 × 100 USDC):** original X post about the
  project with #BinanceWalletHackathon and #AgenticWallet + submit the X link
  via the campaign survey. Needs the user's own X post — prepare draft, user posts.

## Checklist

- [x] Contract written, 10/10 Foundry tests pass
- [x] Frontend built (single-file dApp)
- [x] agent.md (agent-native instructions) written
- [ ] Deploy contract on BSC mainnet (needs ~0.001 BNB top-up to deployer + user confirmation)
- [ ] Verify source on BscScan
- [ ] Push repo public on GitHub, enable GitHub Pages for frontend
- [ ] First interactions from suprihadi.ai Agentic Wallet (register + checkIn via baw, user confirms preview)
- [ ] Fill CONTRACT_ADDRESS / URLs into frontend, README, agent.md, this file
- [ ] Submit project via official survey before 9 Dec 15:00 WIB
- [ ] Promotion: drive ≥30 unique Agent ID holders to check in (X post, Binance Square, communities)
- [ ] Optional: X post for Community Promotion Award (user posts from their account)
