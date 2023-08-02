// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";

contract BaseTest is Test {
    // The 0x000 adress
    address public ZERO;
    // The owner of the contract
    address public OWNER;
    // Alice - a regular user
    address public ALICE;
    // Bob - another regular user
    address public BOB;
    // Bridge - address of the L2 bridge contract
    address public BRIDGE;
    // Initial beneficiary address
    address public L1BENEFICIARY;
    // Origin Network ID to use with bridge
    uint32 public constant ORIGIN_NETWORK_ID = 0;
    // USDC address on L1
    address public USDC_L1;
    // USDC address on L2
    address public USDC_L2;
    // MATIC address on L1
    address public MATIC_L1;
    // MATIC address on L2
    address public MATIC_L2;
    // Test ERC20 token
    ERC20 public testToken;
    // Test ERC20 token address (for labeling)
    address public TEST_TOKEN;

    modifier asAccount(address account) {
        console.log("Transacting as account %s...", account);
        vm.startPrank(account);
        _;
        vm.stopPrank();
        console.log("Done transacting as account %s.", account);
    }

    function dealToken(address account, address token, uint256 amount) public {
        console.log("Dealing %s of token %s to %s.", amount, token, account);
        deal(token, account, amount);
    }

    function dealEther(address account, uint256 amount) public {
        console.log("Dealing %s ETH to %s.", amount, account);
        vm.deal(account, amount);
    }

    function getEtherBalance(address account) public view returns (uint256 balance) {
        balance = account.balance;
        console.log("%s has an ETH balance of %s", account, balance);
        return balance;
    }

    function getTokenBalance(address account, address token) public view returns (uint256 balance) {
        IERC20 _token = IERC20(token);
        balance = _token.balanceOf(account);
        console.log("%s has %s of token %s", account, balance, token);
        return balance;
    }

    function assertBalance(address account, address token, uint256 amount) public {
        if (account == address(0)) {
            assertEtherBalance(account, amount);
        } else {
            assertTokenBalance(account, token, amount);
        }
    }

    function assertEtherBalance(address account, uint256 amount) public {
        console.log("Verifying that %s has an ETH balance of %s...", account, amount);
        assertEq(getEtherBalance(account), amount, "Eth balance is not what was expected");
    }

    function assertTokenBalance(address account, address token, uint256 amount) public {
        console.log("Verifying that %s has %s of token %s...", account, amount, token);
        assertEq(getTokenBalance(account, token), amount, "Token balance is not what was expected");
    }

    function setUp() public virtual {
        setupAddresses();
        testToken = new ERC20("Test Token", "TTOK");
        TEST_TOKEN = _label(address(testToken), "TEST_TOKEN");
    }

    function setupAddresses() public virtual {
        ZERO = _label(address(0), "ZERO");
        OWNER = _label(address(1), "OWNER");
        ALICE = _label(address(2), "ALICE");
        BOB = _label(address(3), "BOB");
        BRIDGE = _label(address(0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe), "BRIDGE");
        L1BENEFICIARY = _label(address(4), "L1BENEFICIARY");
        USDC_L1 = _label(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, "USDC_L1");
        USDC_L2 = _label(0xA8CE8aee21bC2A48a5EF670afCc9274C7bbbC035, "USDC_L2");
        MATIC_L1 = _label(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0, "MATIC_L1");
        MATIC_L2 = _label(0xa2036f0538221a77A3937F1379699f44945018d0, "MATIC_L2");
    }

    function _label(address _address, string memory _name) internal returns (address) {
        vm.label(_address, _name);
        return _address;
    }
}
