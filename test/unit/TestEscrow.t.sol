// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Escrow} from "../../src/Escrow.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployEscrow} from "../../script/DeployEscrow.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestEscrow is Test {
    Escrow public escrow;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    address public USER_A = makeAddr("userA");
    address public USER_B = makeAddr("userB");
    uint256 public INITIAL_STATE = 1000 ether;

    struct Order {
        address owner;
        uint256 amount;
        uint256 price;
    }

    function setUp() public {
        // Define the mock ERC20 tokens
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();

        // Deploy the escrow contract
        DeployEscrow deployer = new DeployEscrow();
        escrow = deployer.run();
    }

    modifier minTokens() {
        tokenA.mint(USER_A, INITIAL_STATE);
        tokenB.mint(USER_B, INITIAL_STATE);
        _;
    }

    function testCreateOrder() public {
        // 1. Arrange
        // - Call apply on the token contract to approve the escrow contract to transfer tokens
        vm.prank(USER_A);
        tokenA.approve(address(escrow), 100 ether);
        // Mint tokenA for userA
        tokenA.mint(USER_A, INITIAL_STATE);
        // 2. Act
        // - Call createOrder on the escrow contract
        vm.prank(USER_A);
        uint256 orderId = escrow.createOrder(address(tokenA), address(tokenB), 100 ether, 1 ether);
        // 3. Assert
        // - Check that the order was created
        (address owner, uint256 amount, uint256 price) = escrow.getOrder(address(tokenA), address(tokenB), orderId);
        assertEq(owner, USER_A);
        assertEq(amount, 100 ether);
        assertEq(price, 1 ether);
        vm.stopPrank();
    }

    function testCreateOrderWithInsufficientAllowance() public {
        // 1. Arrange
        vm.prank(USER_A);
        tokenA.approve(address(escrow), 99 ether);
        tokenA.mint(USER_A, INITIAL_STATE);
        // 2. Act
        vm.prank(USER_A);
        // 3. Assert
        vm.expectRevert(Escrow.Escrow__InsufficientAllowance.selector);
        escrow.createOrder(address(tokenA), address(tokenB), 100 ether, 1 ether);
        vm.stopPrank();
    }

    modifier existedOrder() {
        vm.prank(USER_A);
        tokenA.approve(address(escrow), 1 wei);
        vm.prank(USER_A);
        uint256 orderId = escrow.createOrder(address(tokenA), address(tokenB), 1 wei, 100 ether);
        _;
    }

    function testExecuteOrder() public existedOrder minTokens {
        vm.prank(USER_B);
        tokenB.approve(address(escrow), 100 ether);
        vm.prank(USER_B);
        escrow.executeOrder(address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testExecuteOrderWithIndexOutOfBounds() public existedOrder minTokens {
        vm.prank(USER_B);
        tokenB.approve(address(escrow), 100 ether);
        vm.expectRevert(Escrow.Escrow__IndexOutOfBounds.selector);
        vm.prank(USER_B);
        escrow.executeOrder(address(tokenA), address(tokenB), 1);
        vm.stopPrank();
    }

    function testExecuteOrderWithInsufficientAllowance() public existedOrder minTokens {
        vm.prank(USER_B);
        tokenB.approve(address(escrow), 99 ether);
        vm.expectRevert(Escrow.Escrow__InsufficientAllowance.selector);
        vm.prank(USER_B);
        escrow.executeOrder(address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testExecuteOrderWithTransferToOwnerFailed() public existedOrder {
        vm.prank(USER_B);
        tokenB.approve(address(escrow), 100 ether);
        tokenA.mint(USER_A, INITIAL_STATE);
        tokenB.mint(USER_B, 99 ether);
        vm.expectRevert();
        vm.prank(USER_B);
        escrow.executeOrder(address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testExecuteOrderWithTransferToExecutorFailed() public existedOrder {
        vm.prank(USER_B);
        tokenB.approve(address(escrow), 100 ether);
        tokenB.mint(USER_B, INITIAL_STATE);
        vm.expectRevert();
        vm.prank(USER_B);
        escrow.executeOrder(address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testGetOrderBook() public existedOrder {
        vm.prank(USER_A);
        (, bytes memory data) = address(escrow).call(
            abi.encodeWithSignature("getOrderBook(address,address)", address(tokenA), address(tokenB))
        );
        Order[] memory orders = abi.decode(data, (Order[]));
        assertEq(orders.length, 1);
        assertEq(orders[0].owner, USER_A);
        assertEq(orders[0].amount, 1 wei);
        assertEq(orders[0].price, 100 ether);
    }

    function testCancelOrder() public existedOrder {
        vm.prank(USER_A);
        escrow.cancelOrder(address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testCancelOrderWithIndexOutOfBounds() public {
        vm.expectRevert(Escrow.Escrow__IndexOutOfBounds.selector);
        vm.prank(USER_A);
        escrow.cancelOrder(address(tokenA), address(tokenB), 1);
        vm.stopPrank();
    }

    function testCancelOrderWithNotAnOwner() public existedOrder {
        vm.expectRevert(Escrow.Escrow__NotAnOwner.selector);
        vm.prank(USER_B);
        escrow.cancelOrder(address(tokenA), address(tokenB), 0);
        vm.stopPrank();
    }

    function testGetOrder() public existedOrder {
        (address owner, uint256 amount, uint256 price) = escrow.getOrder(address(tokenA), address(tokenB), 0);
        assertEq(owner, USER_A);
        assertEq(amount, 1 wei);
        assertEq(price, 100 ether);
    }

    function testGetOrderWithIndexOutOfBounds() public {
        vm.expectRevert(Escrow.Escrow__IndexOutOfBounds.selector);
        escrow.getOrder(address(tokenA), address(tokenB), 1);
    }
}
