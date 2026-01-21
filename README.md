# Tokenomics - ERC20 with Staking Terms and Emission Controls

This repo is a focused Solidity project that demonstrates a complete tokenomics loop:
an ERC20 token, a staking system with lockups, and a term-based emission schedule
gated by on-chain "volume" (staking + unstaking activity). It is built and tested
with Foundry.

## What this project does

- Mints an initial supply to a treasury address on deployment.
- Allows holders to stake tokens into the contract with a fixed lock period.
- Tracks staking volume per term and mints new rewards only if volume meets a threshold.
- Distributes rewards to stakers via a cumulative reward index.

## How the tokenomics works

The system runs in repeating terms of `LOCK_PERIOD` (14 days).

At the end of a term, the contract attempts to mint **10% of current supply** as rewards,
but only if `volumePerTerm >= amountToMint`. The volume is the sum of all staked and
unstaked amounts during the term. If there are no stakers, rewards are accumulated as
`undistributedRewards` (currently tracked but not redistributed).

Rewards are distributed using an index:

- `rewardIndex` increases when rewards are minted.
- Each staker stores `userRewardIndex`.
- On stake/unstake, rewards are credited based on the delta.

## Core contract

- `src/Tokenomics.sol`
  - ERC20 token named `Tokenomics` with symbol `TKN`.
  - Initial supply: `100000 ether` minted to the treasury.
  - Staking locks tokens for 14 days.
  - Term-based reward emissions with volume gating.

## Key features

- **Term gating:** emissions only happen if there is enough activity.
- **Stake locking:** prevents immediate unstaking to discourage short-term farming.
- **Reward index accounting:** efficient pro-rata distribution to stakers.
- **Custom errors and events:** clean reverts and observability for UI/indexers.

## Project structure

- `src/Tokenomics.sol` - Core smart contract.
- `test/Tokenomics.t.sol` - Foundry tests for staking and safety checks.
- `script/DeployTokenomics.s.sol` - Deployment script.
- `foundry.toml` - Foundry configuration.

## Quick start

Install Foundry and run:

```shell
forge build
forge test
```

## Deploy

```shell
forge script script/DeployTokenomics.s.sol:DeployTokenomics --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Notes for reviewers

- This is a compact, auditable example of a tokenomics model, not a production-ready
  protocol. Things like `undistributedRewards` handling, access control, and extended
  emissions logic can be added depending on product goals.
- The tests focus on staking/unstaking behavior and revert conditions.

## Tech stack

- Solidity `^0.8.0`
- OpenZeppelin ERC20
- Foundry (Forge, Script)
