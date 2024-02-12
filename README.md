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
