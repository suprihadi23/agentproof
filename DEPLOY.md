# Deployment plan — BSC mainnet (chainId 56)

Verified facts (18 Nov 2026, ~21:30 WIB):

- BSC gas price: **0.05 gwei** (public RPC). Estimated deploy gas ≈ 1.25M →
  **≈ 0.00007 BNB (~$0.04)**. Runtime size 5,401 bytes.
- Agent ID gate verified live: registry `balanceOf(0xe0b0…95c2)` = **1** (suprihadi.ai).
- Agentic Wallet `0xe0b00a56904247Ca5Ce23640037488b2dc4955c2`: **0.00196526 BNB**.
- Deployer candidate `0x808a172baE157709E4B90F516808242f33884269` (user's OKX wallet):
  only **0.0000385 BNB** on BSC — needs a small top-up first.
- `baw contract-call` cannot deploy contracts (it requires an existing `--to`
  address), so deployment goes through the user's own wallet in Remix.

## Steps (each state-changing step needs the user's confirmation at that moment)

1. **Top-up deployer** — `baw wallet send` 0.001 BNB on BSC from the Agentic
   Wallet → `0x808a…4269`. Preview shown to user first; user confirms.
   (One-line summary: BSC · from Agentic Wallet 0xe0b0…95c2 · to 0x808a…4269 ·
   0.001 BNB · fee = BSC gas only.)
2. **Deploy in Remix** (user's Chrome, OKX Wallet on BNB Chain):
   - Open https://remix.ethereum.org, create `AgentProof.sol`, paste the source
     from `contracts/AgentProof.sol`.
   - Compile: Solidity **0.8.24**, optimizer **200 runs** (must match, for BscScan verify).
   - Deploy & run: Environment "Injected Provider", constructor argument =
     `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`. Confirm in OKX.
   - Save the deployed contract address + deploy tx hash.
3. **Verify on BscScan** — contract page → Verify & Publish: single file,
   compiler v0.8.24+commit, optimizer 200, MIT license, constructor arg as above.
   (Or standard-JSON from `forge build` output if the flat file route fails.)
4. **Fill addresses** into `frontend/index.html` (CONTRACT_ADDRESS),
   `frontend/agent.md`, `agent.md`, `README.md`, `SUBMISSION.md`.
5. **Publish** — push repo to GitHub (public), enable GitHub Pages on
   `frontend/` (or repo root docs) → project website URL.
6. **First interactions** — from the Agentic Wallet via `baw contract-call`
   (Developer Mode ON, expires 25 Nov 2026 — re-enable in the Binance App if lapsed):
   `register("https://<site>")` then `checkIn()` (selector `0x183ff085`),
   each preview → user confirms → execute. Verify on BscScan + in the dApp.
7. **Submit** the project via the official survey before **9 Dec 2026 15:00 WIB**
   using SUBMISSION.md. Reward address chosen by the user at that moment.
8. **Growth phase** — promote to reach ≥30 unique Agent ID holders interacting
   (Innovation Award eligibility) and recurring daily check-ins.

## Notes

- Owner of the deployed contract = deployer wallet `0x808a…4269` (user's own).
  Owner can only pause/unpause and transfer ownership — disclosed in source.
- Dev Mode and the baw session both expire (session 20 Nov 21:29 WIB; Dev Mode
  25 Nov 18:40 WIB); using Dev Mode extends it. Re-check before step 6.
