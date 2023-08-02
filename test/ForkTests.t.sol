// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "test/util/Helpers.sol";
import { AccumulatorTest } from "test/Accumulator.t.sol";
import "src/Accumulator.sol";
import "src/AccumulatorFactory.sol";
import "src/IAccumulator.sol";

abstract contract ForkTest is AccumulatorTest {
    uint256 zkEVMFork;

    function setUp() public virtual override {
        super.setUp();
        // Read RPC URL from foundry.toml and create a fork of the zkEVM at the current block
        zkEVMFork = vm.createSelectFork("zkEVM");
        testToken = new ERC20("Test Token", "TTOK");
        TEST_TOKEN = address(testToken);
    }

    /// @dev Deploys the base logic contract to the forked blockchain
    function deployLogicContract() public returns (address logicContract) { }

    function deployFactoryContract() public { }
}

contract ForkTest_depositToken is ForkTest {
    L1BeneficiaryAccumulator a;

    function setUp() public virtual override {
        super.setUp();
        a = new L1BeneficiaryAccumulator(BRIDGE, 0);
        a.initialize(L1BENEFICIARY);
        dealToken(ALICE, USDC_L2, 10_000);
        dealToken(ALICE, MATIC_L2, 10_000);
        dealToken(ALICE, TEST_TOKEN, 10_000);
        vm.startPrank(ALICE);
        IERC20(USDC_L2).approve(address(a), 10_000);
        IERC20(MATIC_L2).approve(address(a), 10_000);
        testToken.approve(address(a), 10_000);
        vm.stopPrank();
    }

    function test_deposit() public asAccount(ALICE) {
        a.deposit(USDC_L2, 100);
        a.deposit(MATIC_L2, 100);
        a.deposit(TEST_TOKEN, 100);
        a.bridgeAllTokens();
    }
}

contract ForkTest_bridgeToken is ForkTest {
    L1BeneficiaryAccumulator a;

    function setUp() public virtual override {
        super.setUp();
        a = new L1BeneficiaryAccumulator(BRIDGE, 0);
        a.initialize(L1BENEFICIARY);
        dealToken(ALICE, USDC_L2, 10_000);
        dealToken(ALICE, MATIC_L2, 10_000);
        dealToken(ALICE, TEST_TOKEN, 10_000);
        vm.startPrank(ALICE);
        IERC20(USDC_L2).approve(address(a), 10_000);
        IERC20(MATIC_L2).approve(address(a), 10_000);
        testToken.approve(address(a), 10_000);
        vm.stopPrank();
    }

    function test_shouldEmitTokenBridgedEvent() public asAccount(ALICE) {
        a.deposit(USDC_L2, 100);
        a.deposit(MATIC_L2, 100);
        a.deposit(TEST_TOKEN, 100);

        vm.expectEmit(true, true, true, true);
        emit TokenBridged(L1BENEFICIARY, BRIDGE, TEST_TOKEN, 100);
        a.bridgeToken(TEST_TOKEN);
    }

    function test_shouldEmitRemovedTokenEvent() public asAccount(ALICE) {
        a.deposit(USDC_L2, 100);
        assertTokenBalance(address(a), USDC_L2, 100);
        a.deposit(MATIC_L2, 100);
        assertTokenBalance(address(a), MATIC_L2, 100);
        a.deposit(TEST_TOKEN, 100);
        assertTokenBalance(address(a), TEST_TOKEN, 100);

        vm.expectEmit(true, true, true, true);
        emit RemovedToken(TEST_TOKEN);
        a.bridgeToken(TEST_TOKEN);
        assertEq(a.holdsToken(TEST_TOKEN), false);
        assertTokenBalance(address(a), TEST_TOKEN, 0);
        a.bridgeAllTokens();
    }
}
/*
contract TestFork_DeployScript is ForkTest {

    
}
*/

contract ForkTest_Factory is ForkTest {
    AccumulatorFactory public factory;
    address public myCloneAddr;
    IAccumulator public myClone;
    IERC20 _USDC;
    IERC20 _MATIC;
    IERC20 _TEST_TOKEN;

    function setUp() public virtual override {
        super.setUp();
        L1BeneficiaryAccumulator impl = new L1BeneficiaryAccumulator(BRIDGE, 0);
        impl.lock();
        address implAddress = address(impl);

        factory = new AccumulatorFactory(implAddress);
        console.log("Implementation address is: ", factory.implementationAddr());
        myCloneAddr = factory.deploy(L1BENEFICIARY);
        console.log("Clone address is: ", myCloneAddr);
        myClone = IAccumulator(myCloneAddr);
        _USDC = IERC20(USDC_L2);
        _MATIC = IERC20(MATIC_L2);
        _TEST_TOKEN = IERC20(TEST_TOKEN);

        dealEther(ALICE, 10 ether);
        dealToken(ALICE, USDC_L2, 100_000);
        dealToken(ALICE, MATIC_L2, 100_000);
        dealToken(ALICE, TEST_TOKEN, 100_000);
        vm.startPrank(ALICE);
        _USDC.approve(myCloneAddr, 100_000);
        _MATIC.approve(myCloneAddr, 100_000);
        _TEST_TOKEN.approve(myCloneAddr, 100_000);
        vm.stopPrank();

        dealEther(BOB, 10 ether);
        dealToken(BOB, USDC_L2, 100_000);
        dealToken(BOB, MATIC_L2, 100_000);
        dealToken(BOB, TEST_TOKEN, 100_000);
        vm.startPrank(BOB);
        _USDC.approve(myCloneAddr, 100_000);
        _MATIC.approve(myCloneAddr, 100_000);
        _TEST_TOKEN.approve(myCloneAddr, 100_000);
        vm.stopPrank();
    }

    function testE2E_depositAndBridgeEtherOnly() public {
        assertEtherBalance(myCloneAddr, 0);
        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit EtherDeposited(ALICE, 3 ether);
        myClone.deposit{ value: 3 ether }(address(0), 0);
        vm.stopPrank();

        assertEtherBalance(myCloneAddr, 3 ether);

        vm.startPrank(BOB);
        vm.expectEmit(true, true, true, true);
        emit EtherDeposited(BOB, 8 ether);
        myClone.deposit{ value: 8 ether }(address(0), 0);
        vm.stopPrank();

        assertEtherBalance(myCloneAddr, 11 ether);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit EtherBridged(L1BENEFICIARY, BRIDGE, 11 ether);
        myClone.bridgeAssets();
        vm.stopPrank();
        assertEtherBalance(myCloneAddr, 0);
    }

    function testE2E_depositAndBridgeTokensOnly() public {
        assertTokenBalance(myCloneAddr, USDC_L2, 0);
        assertTokenBalance(myCloneAddr, MATIC_L2, 0);
        vm.startPrank(ALICE);
        myClone.deposit(USDC_L2, 150);
        assertTokenBalance(myCloneAddr, USDC_L2, 150);
        vm.stopPrank();

        vm.startPrank(BOB);

        vm.expectEmit(true, true, true, true);
        emit TokenDeposited(MATIC_L2, BOB, 25);

        myClone.deposit(MATIC_L2, 25);
        assertTokenBalance(myCloneAddr, MATIC_L2, 25);

        // other token balance is invariant
        assertTokenBalance(myCloneAddr, USDC_L2, 150);

        vm.expectEmit(true, true, true, true);
        emit TokenDeposited(USDC_L2, BOB, 50);

        myClone.deposit(USDC_L2, 50);
        assertTokenBalance(myCloneAddr, USDC_L2, 200);
        vm.stopPrank();

        vm.startPrank(ALICE);
        assertTokenBalance(myCloneAddr, MATIC_L2, 25);

        vm.expectEmit(true, true, true, true);
        emit TokenDeposited(MATIC_L2, ALICE, 225);

        myClone.deposit(MATIC_L2, 225);
        assertTokenBalance(myCloneAddr, MATIC_L2, 250);

        // other token balance is invariant
        assertTokenBalance(myCloneAddr, USDC_L2, 200);

        vm.expectEmit(true, true, true, true);
        emit TokenDeposited(USDC_L2, ALICE, 100);

        myClone.deposit(USDC_L2, 100);
        assertTokenBalance(myCloneAddr, USDC_L2, 300);

        // other token balance is invariant
        assertTokenBalance(myCloneAddr, MATIC_L2, 250);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit TokenBridged(L1BENEFICIARY, BRIDGE, MATIC_L2, 250);
        myClone.bridgeToken(MATIC_L2);

        assertTokenBalance(myCloneAddr, MATIC_L2, 0);
        assertEq(myClone.holdsToken(MATIC_L2), false, "Expected holdsToken to return false for MATIC");

        assertTokenBalance(myCloneAddr, USDC_L2, 300);
        assertEq(myClone.holdsToken(USDC_L2), true, "Expected holdsToken to return true for USDC");

        vm.expectEmit(true, true, true, true);
        emit TokenBridged(L1BENEFICIARY, BRIDGE, USDC_L2, 300);
        myClone.bridgeToken(USDC_L2);

        assertTokenBalance(myCloneAddr, USDC_L2, 0);
        assertEq(myClone.holdsToken(USDC_L2), false, "Expected holdsToken to return false for USDC");
    }
}
