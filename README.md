# CooperativeChain

A decentralized cooperative member governance system for transparent cooperative decision making on Stacks blockchain.

## Features

- Cooperative initiative proposal and management
- Member voting with equity-weighted decisions
- Trustee assignment for cooperative representation
- Fiscal year governance cycles and timeline management
- Comprehensive cooperative governance statistics

## Smart Contract Functions

### Public Functions
- `propose-initiative` - Propose cooperative initiative for member voting (manager only)
- `cast-coop-vote` - Cast vote on initiative with equity weight
- `assign-trustee` - Assign trustee for cooperative representation
- `close-initiative` - Close initiative voting (manager only)
- `advance-fiscal-year` - Advance fiscal year cycle (manager only)

### Read-Only Functions
- `get-initiative-equity-total` - Get total equity voted on initiative
- `get-member-equity-level` - Get member's equity allocation
- `get-initiative-status` - Check if initiative voting is active
- `get-current-fiscal-year` - Get current fiscal year
- `get-coop-stats` - Get comprehensive cooperative statistics

## Governance Features
- Equity-weighted voting system
- Trustee representation mechanism
- Fiscal year decision cycles
- Manager authorization controls

## Usage

Deploy the contract to create a cooperative governance system where members can vote on initiatives, assign trustees, and participate in democratic cooperative decision making.

## License

MIT