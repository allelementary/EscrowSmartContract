# Escrow SmartContract

## About

Example of escrow contract to exchange tokens between users

## How should it work?

1. An order Owner creates an order to exchange one token to another at specified price. Owner gives permission to EscrowContract to be able to transfer tokens on behalf of an owner
2. An order Executor should be able to get order book, and chose an order to execute. Then executor gives permission to a contract to transfer tokens on his behalf. If funding value is less then expected -> transaction would be reverted. Else -> contract would send tokens to users and close an order

## Usage

- Run tests:

```bash
forge test
```

| File                      | % Lines        | % Statements   | % Branches     | % Funcs       |
|---------------------------|----------------|----------------|----------------|---------------|
| script/DeployEscrow.s.sol | 100.00% (4/4)  | 100.00% (5/5)  | 100.00% (0/0)  | 100.00% (1/1) |
| src/Escrow.sol            | 92.50% (37/40) | 94.83% (55/58) | 83.33% (15/18) | 100.00% (6/6) |
| Total                     | 93.18% (41/44) | 95.24% (60/63) | 83.33% (15/18) | 100.00% (7/7) |
