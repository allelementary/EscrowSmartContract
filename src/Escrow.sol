// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";

/*
 * @title Escrow
 * @author Mikhail Antonov
 *
 * Escrow smart contract for exchange of tokens
 */
contract Escrow {
    ////////////
    // Error  //
    ////////////
    error Escrow__InsufficientAllowance();
    error Escrow__IndexOutOfBounds();
    error Escrow__NotAnOwner();
    error Escrow__TransferFailed();

    ////////////////////////
    // Type Declarations  //
    ////////////////////////
    struct Order {
        address owner;
        uint256 amount;
        uint256 price;
    }

    //////////////////////
    // State Variables  //
    //////////////////////
    mapping(address => mapping(address => Order[])) private orderBook;
    mapping(address => mapping(address => uint256[])) private orderIdsByTokens;

    uint256 private orderIdCounter = 0;

    IERC20 public erc20TokenContract;

    ///////////////
    // Functions //
    ///////////////

    ////////////////////////
    // External Functions //
    ////////////////////////
    /**
     * @dev Create an order
     * @param tokenA address of tokenA
     * @param tokenB address of tokenB
     * @param amount amount of tokenA
     * @param price price of tokenA in tokenB
     * @notice todo: add .approve() call to UI and remind user to call it before creating an order
     */
    function createOrder(address tokenA, address tokenB, uint256 amount, uint256 price)
        external
        returns (uint256 orderId)
    {
        erc20TokenContract = IERC20(tokenA);
        uint256 currentAllowance = erc20TokenContract.allowance(msg.sender, address(this));

        if (currentAllowance < amount) {
            revert Escrow__InsufficientAllowance();
        }

        Order memory order = Order(msg.sender, amount, price);

        orderId = orderIdCounter;
        orderIdCounter++;

        orderBook[tokenA][tokenB].push(order);
        orderIdsByTokens[tokenA][tokenB].push(orderId);
        return orderId;
    }

    function executeOrder(address tokenA, address tokenB, uint256 orderId) external {
        if (orderBook[tokenA][tokenB].length == 0 || orderId > orderBook[tokenA][tokenB].length - 1) {
            revert Escrow__IndexOutOfBounds();
        }

        Order storage order = orderBook[tokenA][tokenB][orderId];

        IERC20 tokenAContract = IERC20(tokenA);
        IERC20 tokenBContract = IERC20(tokenB);

        // Check if the executor has allowed the contract to spend the correct amount of tokenB
        uint256 tokenBAmountRequired = order.amount * order.price; // assuming price is a multiplier
        uint256 currentAllowance = tokenBContract.allowance(msg.sender, address(this));
        if (currentAllowance < tokenBAmountRequired) {
            revert Escrow__InsufficientAllowance();
        }

        // Transfer tokenB from executor to owner
        if (!tokenBContract.transferFrom(msg.sender, order.owner, tokenBAmountRequired)) {
            revert Escrow__TransferFailed();
        }

        // Transfer tokenA from owner to the executor
        if (!tokenAContract.transferFrom(order.owner, msg.sender, order.amount)) {
            revert Escrow__TransferFailed();
        }

        _cancelOrder(tokenA, tokenB, orderId);
    }

    //////////////////////
    // Public Functions //
    //////////////////////
    function getOrderBook(address tokenA, address tokenB) public view returns (Order[] memory) {
        return orderBook[tokenA][tokenB];
    }

    function cancelOrder(address tokenA, address tokenB, uint256 orderId) public {
        if (orderBook[tokenA][tokenB].length == 0 || orderId > orderBook[tokenA][tokenB].length - 1) {
            revert Escrow__IndexOutOfBounds();
        }
        Order storage order = orderBook[tokenA][tokenB][orderId];
        if (msg.sender != order.owner) {
            revert Escrow__NotAnOwner();
        }

        orderBook[tokenA][tokenB][orderId] = orderBook[tokenA][tokenB][orderBook[tokenA][tokenB].length - 1];
        // Remove the last element
        orderBook[tokenA][tokenB].pop();
    }

    function getOrder(address tokenA, address tokenB, uint256 orderId)
        public
        view
        returns (address, uint256, uint256)
    {
        if (orderBook[tokenA][tokenB].length == 0 || orderId > orderBook[tokenA][tokenB].length - 1) {
            revert Escrow__IndexOutOfBounds();
        }
        Order memory order = orderBook[tokenA][tokenB][orderId];
        return (order.owner, order.amount, order.price);
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////
    function _cancelOrder(address tokenA, address tokenB, uint256 orderId) internal {
        if (orderBook[tokenA][tokenB].length == 0 || orderId > orderBook[tokenA][tokenB].length - 1) {
            revert Escrow__IndexOutOfBounds();
        }

        orderBook[tokenA][tokenB][orderId] = orderBook[tokenA][tokenB][orderBook[tokenA][tokenB].length - 1];
        // Remove the last element
        orderBook[tokenA][tokenB].pop();
    }
}
