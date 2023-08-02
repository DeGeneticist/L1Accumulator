// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "test/Helpers.sol";
// import "lib/IPolygonZkEVMBridge.sol";

import "src/Accumulator.sol";

contract AccumulatorHarness is L1BeneficiaryAccumulator {
    constructor(address _bridge, uint32 _originNetworkId) L1BeneficiaryAccumulator(_bridge, _originNetworkId) {
        maxTokensToBridge = 2;
    }

    /// @dev Harness to expose internal _initialized variable
    function getInitialized() external view returns (bool initialized) {
        return _initialized;
    }

    /// @dev Harness to set internal _initialized variable for tests
    function setInitialized(bool _value) external {
        _initialized = _value;
    }

    /// @dev Harness to read internal _locked variable
    function getLocked() external view returns (bool) {
        return _locked;
    }

    /// @dev Harness to set internal _initialized variable for tests
    function setLocked(bool _value) external {
        _locked = _value;
    }

    /// @dev Harness to expose internal _addToken function
    function addToken(address _token) public returns (bool success) {
        return _addToken(_token);
    }

    /// @dev Harness to expose internal _removeToken function
    function removeToken(address _token) public returns (bool success) {
        return _removeToken(_token);
    }

    /// @dev Harness to expose internal function _allowanceIsSufficient
    function allowanceIsSufficient(IERC20 token, address owner, uint256 amount) public view returns (bool sufficient) {
        return _allowanceIsSufficient(token, owner, amount);
    }

    /// @dev Harness to expose internal _validateToken function
    function validateToken(address _token) public view returns (IERC20 token) {
        return _validateToken(_token);
    }
    /*

    function getHeldTokensLength() public view returns (uint256) {
        address[] memory heldTokensArr = getHeldTokens();
        return heldTokensArr.length;
    }

    
    */
    /// @dev Harness to expose internal _approveBridgeFroToken function

    function approveBridgeForToken(IERC20 _token, uint256 _amount) external {
        _approveBridgeForToken(_token, _amount);
    }

    /*
    /// @dev Harness to expose internal _isTokenAllowanceSufficent function
    function isTokenAllowanceSufficient(
        address _token,
        address _owner,
        uint256 _required
    )
        external
        returns (bool sufficient)
    {
        return _isTokenAllowanceSufficient(_token, _owner, _required);
    }

    /*
     /// @dev Harness to expose the heldTokens array
    function getHeldTokens() public view returns (address[] memory) {
        return _heldTokens;
    }
    /*   
    /// @dev Harness to manually push a token address to the _heldTokens EnumerableSet
    function addTokenToHeldTokens(address _token) public {
        _heldTokens.contains(_token);
    }
    */

    /*
    /// @dev Harness to manually add an address to the heldTokens array
    function addHeldToken(address _token) public {
        _heldTokens.add(_token);
    }
    */
}

contract AccumulatorTest is BaseTest {
    AccumulatorHarness c;
    ///L1BeneficiaryAccumulator c;

    event TokenIsAlreadyHeld(address indexed token);

    event AddedToken(address indexed token);

    event RemovedToken(address indexed token);

    event TokenDeposited(address indexed token, address indexed sender, uint256 amount);

    event ContractInitializationLocked();

    event EtherDeposited(address indexed sender, uint256 amount);

    //event TokenDeposited(address indexed sender, address indexed token, uint256 amount);

    event EtherBridged(address indexed beneficiary, address indexed bridge, uint256 amount);

    event TokenBridged(address indexed beneficiary, address indexed bridge, address indexed token, uint256 amount);

    event ContractInitialized(address indexed beneficiary);

    event BridgeApprovedForToken(address indexed token, uint256 amount);

    event NoEtherToBridge();

    error ContractIsLocked();

    error CannotDepositZeroEther(address sender);

    error CannotDepositZeroTokens();

    error CannotBridgeZeroEther();

    error BridgeEtherFailed(address beneficiary, address bridge, uint256 balance);

    error BridgeTokenFailed(address beneficiary, address bridge, address token, uint256 amount);

    error InsufficientTokenAllowance(address token, address owner, uint256 required);

    error TokenAddressCannotBeZero();

    error InvalidERC20Contract(address token);

    error ApproveBridgeForTokenFailed(address token, uint256 amount);

    error UnauthorizedUser(address user);
    error ContractAlreadyInitialized();
    error ContractIsNotInitialized();
    error BeneficiaryCannotBeZeroAddress();
    error InvalidTransaction();

    modifier whenLocked() {
        c.lock();
        _;
    }

    modifier whenInitialized() {
        console.log("Initializing accumulator %s with beneficiary %s", address(c), L1BENEFICIARY);
        c.initialize(L1BENEFICIARY);
        _;
    }

    modifier whenNotInitialized() {
        console.log("Forcing contract into uninitialized state");
        c.setInitialized(false);
        _;
    }

    /// @dev Convenience for testing with the contract in an uninitialized state
    modifier revertsWhenNotInitialized() {
        console.log("Forcing contract into unitialized state");
        c.setInitialized(false);
        vm.expectRevert(ContractIsNotInitialized.selector);
        _;
    }

    function setUp() public virtual override {
        super.setUp();
        vm.prank(OWNER);
        c = new AccumulatorHarness(BRIDGE, 0);
        //c = new L1BeneficiaryAccumulator();
    }

    function deployAccumulatorHarness() public returns (L1BeneficiaryAccumulator accumulator) {
        accumulator = new AccumulatorHarness(BRIDGE, 0);
        return accumulator;
    }

    function assertNumHeldTokens(uint256 numTokens) public {
        console.log("Verifying that the accumulator contract holds %s tokens in _heldTokens...", numTokens);
        uint256 actualNumTokens = c.getAllHeldTokens().length;
        console.log("Accumulator contract has %s tokens in _heldTokens", actualNumTokens);
        assertEq(actualNumTokens, numTokens, "Unexpected number of tokens in _heldTokens");
    }

    function depositEther(uint256 amount) public {
        c.deposit{ value: amount }(address(0), 0);
    }
}

contract UnitTest_constructor is AccumulatorTest {
    function test_initialBridgeAddressIsSet() public {
        assertEq(c.bridge(), BRIDGE, "Bridge address should be BRIDGE");
    }

    function test_initializedIsFalse() public {
        assertEq(c.getInitialized(), false, "Expected _initialized var to be false");
    }

    function test_lockedIsFalse() public {
        assertEq(c.getLocked(), false, "Expected _locked var to be false");
    }

    function test_originNetworkIdIsSet() public {
        assertEq(c.originNetworkId(), 0, "Expected originNetworkId to be 0");
    }
}

contract UnitTest_lock is AccumulatorTest {
    function test_setsLockedToTrue() public {
        c.lock();
        assertEq(c.getLocked(), true, "Expected _locked var to be true");
    }

    function test_revertsIfContractIsLocked() public {
        c.setLocked(true);
        vm.expectRevert(ContractIsLocked.selector);
        c.lock();
    }

    function test_emitsEvent() public {
        // FIXME
    }

    function test_revertsIfCalledTwice() public {
        // FIXME
    }
}

contract UnitTest_initialize is AccumulatorTest {
    function test_setsInitializedToTrue() public {
        c.initialize(L1BENEFICIARY);
        assertEq(c.getInitialized(), true);
    }

    function test_revertsIfInitializedAlreadyTrue() public {
        c.setInitialized(true);
        vm.expectRevert(ContractAlreadyInitialized.selector);
        c.initialize(L1BENEFICIARY);
    }

    function test_revertsIfCalledTwice() public {
        /// without the harness; verifying the design criteria
        c.initialize(L1BENEFICIARY);
        vm.expectRevert();
        c.initialize(ALICE);
    }

    function test_revertsIfLockedIsTrue() public {
        c.setLocked(true);
        vm.expectRevert(ContractIsLocked.selector);
        c.initialize(L1BENEFICIARY);
    }

    function test_revertsIfCalledAfterLock() public {
        //vm.startPrank(OWNER);
        c.lock();
        vm.expectRevert(ContractIsLocked.selector);
        c.initialize(L1BENEFICIARY);
    }

    function test_setsBeneficiary() public {
        c.initialize(L1BENEFICIARY);
        assertEq(c.beneficiary(), L1BENEFICIARY);
    }

    function test_revertsIfBeneficiaryIsZero() public {
        vm.expectRevert(BeneficiaryCannotBeZeroAddress.selector);
        c.initialize(ZERO);
    }

    function test_emitsContractInitializedEvent() public {
        vm.expectEmit(true, true, true, true);
        emit ContractInitialized(L1BENEFICIARY);
        vm.prank(OWNER);
        c.initialize(L1BENEFICIARY);
    }
    /*
    function test_emitsLockedContractInitializationEvent() public {
        vm.expectEmit(true, true, true, true);
        emit LockedContractInitialization();
        vm.prank(OWNER);
        c.initialize(L1BENEFICIARY);
    }
    */
}

contract UnitTest_getAllHeldTokens is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        c.initialize(L1BENEFICIARY);
    }

    function test_shouldReturnEmptyArray_atInitialization() public {
        address[] memory tokens = c.getAllHeldTokens();
        assertEq(tokens.length, 0, "Expected an empty array");
    }

    function test_returnsAddedTokens() public {
        c.addToken(USDC_L2);
        assertEq(c.getAllHeldTokens().length, 1, "Expected _heldTokens to contain one address");
        assertEq(c.getAllHeldTokens()[0], USDC_L2, "Expected the USDC contract address on L2");
        c.addToken(MATIC_L2);
        assertEq(c.getAllHeldTokens().length, 2, "Expected _heldTokens to contain two address");
        assertEq(c.getAllHeldTokens()[1], MATIC_L2, "Expected the MATIC contract address on L2");
    }

    function test_revertsWhenNotInitialized() public revertsWhenNotInitialized {
        c.getAllHeldTokens();
    }
}

/*
contract UnitTest_AddHeldToken is AccumulatorTest {
    event TokenIsAlreadyHeld(address indexed);

    // Unit tests for the _addHeldToken function

    /// @dev Uses the addHeldToken() and getHeldTokensLength() test harness functions
    function test_addHeldTokenUpdatesHeldTokensSet() public {
        // Ensure that the _heldTokens set is empty to start
        assertEq(c.getHeldTokensLength(), 0, "Expected _heldTokens.values() to have length 0");
        // Add the Matic L2 token via the test harness
        c.addHeldToken(MATIC_L2);
        // Get the updated _heldTokens set
        address[] memory newHeldTokens = c.getHeldTokens();
        assertEq(newHeldTokens.length, 1, "Expected _heldTokens.values() to have length 1");
        assertEq(newHeldTokens[0], MATIC_L2, "Expected the first address in _heldTokens.values() to be MATIC_L2");
    }

    /// @dev Uses the addHeldToken() and getHeldTokensLength() test harness functions
    function test_addHeldTokenOnlyAddsUnique() public {
        // Ensure that initial _heldTokens.values() is empty
        assertEq(c.getHeldTokensLength(), 0, "Expected initial _heldTokens.values().length to be 0");
        c.addHeldToken(USDC_L2);
        assertEq(c.getHeldTokensLength(), 1, "Held tokens array should have length 1");
        c.addHeldToken(USDC_L2);
        assertEq(c.getHeldTokensLength(), 1, "Held tokens array should still have length 1");
    }

    function test_addHeldTokenEmitsEventIfAlreadyHeld() public {
        c.addHeldToken(USDC_L2);
        vm.expectEmit(true, true, true, true);
        emit TokenIsAlreadyHeld(USDC_L2);
        c.addHeldToken(USDC_L2);
    }
    /*
    /// @dev Uses the addHeldToken() and getHeldTokens() test harness functions
    function test_addHeldTokenUpdatesHeldTokensArray() public {
        address[] memory originalHeldTokensArr;
        address[] memory newHeldTokensArr;
        // Verify that the heldTokens array is empty to start
        originalHeldTokensArr = c.getHeldTokens();
        assertEq(originalHeldTokensArr.length, 0, "Expected initial length of heldTokens to be 0");
        
        // Add the Matic L2 token via the test harness
        c.addHeldToken(MATIC_L2);

        // Get the updated heldTokens array via the test harness
        newHeldTokensArr = c.getHeldTokens();
        assertEq(newHeldTokensArr.length, 1, "Expected the length of heldTokens array to be 1");
        assertEq(newHeldTokensArr[0], MATIC_L2, "Expected heldTokens[0] to be the MATIC_L2 address");
    }
}



    */

contract UnitTest_deposit is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        dealEther(ALICE, 10 ether);
        dealToken(ALICE, TEST_TOKEN, 10 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        vm.stopPrank();
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized asAccount(ALICE) {
        depositEther(2 ether);
    }

    function test_shouldDepositEtherSuccessfully() public whenInitialized asAccount(ALICE) {
        depositEther(2 ether);
        assertEtherBalance(address(c), 2 ether);
    }

    function test_shouldRevert_whenAddressIsZeroAndNoEtherSent() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(abi.encodeWithSelector(CannotDepositZeroEther.selector, ALICE));
        c.deposit{ value: 0 }(address(0), 0);
    }

    function shouldEmitEtherDepositedWhenEtherDeposited() public whenInitialized asAccount(ALICE) {
        vm.expectEmit(true, true, true, true);
        emit EtherDeposited(ALICE, 5 ether);
        c.deposit{ value: 5 ether }(address(0), 0);
    }

    function test_shouldRevert_whenTokenAmountIsZero() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(CannotDepositZeroTokens.selector);
        c.deposit(TEST_TOKEN, 0);
    }

    function test_shouldDepositERC20TokenSuccessfully() public whenInitialized asAccount(ALICE) {
        c.deposit(TEST_TOKEN, 5 ether);
        assertTokenBalance(address(c), TEST_TOKEN, 5 ether);
    }

    function test_shouldEmitTokenDeposited_WhenERC20Deposited() public whenInitialized asAccount(ALICE) {
        vm.expectEmit(true, true, true, true);
        emit TokenDeposited(TEST_TOKEN, ALICE, 5 ether);
        c.deposit(TEST_TOKEN, 5 ether);
    }

    function test_shouldRevert_whenAllowanceIsInsufficient() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(abi.encodeWithSelector(InsufficientTokenAllowance.selector, TEST_TOKEN, ALICE, 8 ether));
        c.deposit(TEST_TOKEN, 8 ether);
    }

    function test_shouldAddTokenToHeldTokens() public whenInitialized asAccount(ALICE) {
        assertNumHeldTokens(0);
        c.deposit(TEST_TOKEN, 2 ether);
        assertNumHeldTokens(1);
        assertEq(c.numHeldTokens(), 1, "Expected numHeldTokens() to return 1");
        assertEq(c.holdsToken(TEST_TOKEN), true, "Expected holdsToken() to return true");
    }

    function test_shouldRevert_whenTokenAddressIsNotAContract() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(abi.encodeWithSelector(InvalidERC20Contract.selector, BOB));
        c.deposit(BOB, 2 ether);
    }
    /*
    function shouldHaveCorrectEtherBalanceAfterMultipleTransactions

    function shouldHaveCorrectTokenBalancesAfterMultipleTransactions

    */
}

/*
contract UnitTest_bridgeAssets is AccumulatorTest {
    shouldRevert_whenNotInitialized
}

*/

contract UnitTest_getTokenBalance is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        dealEther(ALICE, 10 ether);
        dealToken(ALICE, TEST_TOKEN, 10 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        vm.stopPrank();
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized asAccount(ALICE) {
        c.getTokenBalance(TEST_TOKEN);
    }

    function test_shouldReturnCorrectBalanceAfterDeposit() public whenInitialized asAccount(ALICE) {
        c.deposit(TEST_TOKEN, 2 ether);
        assertTokenBalance(address(c), TEST_TOKEN, 2 ether);
        assertEq(c.getTokenBalance(TEST_TOKEN), 2 ether, "Got unexpected balance from getTokenBalance");
    }

    function test_shouldRevert_whenTokenAddressIsZero() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(TokenAddressCannotBeZero.selector);
        c.getTokenBalance(address(0));
    }

    function test_shouldRevert_whenTokenAddressIsNotAContract() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(abi.encodeWithSelector(InvalidERC20Contract.selector, BOB));
        c.getTokenBalance(BOB);
    }

    /*
    test_shouldReturnCorrectBalancesAfterMultipleDeposits
    test_shouldRevert_whenTokenNotHeld
    */
}

contract UnitTest_depositToken is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        dealToken(ALICE, TEST_TOKEN, 10 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        vm.stopPrank();
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized asAccount(ALICE) {
        c.depositToken(TEST_TOKEN, 1 ether);
    }

    function test_shouldRevert_whenTokenAmountIsZero() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(CannotDepositZeroTokens.selector);
        c.depositToken(TEST_TOKEN, 0);
    }

    function test_shouldDepositERC20TokenSuccessfully() public whenInitialized asAccount(ALICE) {
        c.depositToken(TEST_TOKEN, 5 ether);
        assertTokenBalance(address(c), TEST_TOKEN, 5 ether);
    }

    function test_shouldEmitTokenDeposited_WhenERC20Deposited() public whenInitialized asAccount(ALICE) {
        vm.expectEmit(true, true, true, true);
        emit TokenDeposited(TEST_TOKEN, ALICE, 5 ether);
        c.depositToken(TEST_TOKEN, 5 ether);
    }

    function test_shouldRevert_whenAllowanceIsInsufficient() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(abi.encodeWithSelector(InsufficientTokenAllowance.selector, TEST_TOKEN, ALICE, 8 ether));
        c.depositToken(TEST_TOKEN, 8 ether);
    }

    function test_shouldAddTokenToHeldTokens() public whenInitialized asAccount(ALICE) {
        assertNumHeldTokens(0);
        c.depositToken(TEST_TOKEN, 2 ether);
        assertNumHeldTokens(1);
        assertEq(c.numHeldTokens(), 1, "Expected numHeldTokens() to return 1");
        assertEq(c.holdsToken(TEST_TOKEN), true, "Expected holdsToken() to return true");
    }

    function test_shouldRevert_whenTokenAddressIsNotAContract() public whenInitialized asAccount(ALICE) {
        vm.expectRevert(abi.encodeWithSelector(InvalidERC20Contract.selector, BOB));
        c.depositToken(BOB, 2 ether);
    }
    /*
    shouldRevert_whenNotApproved
    shouldEmitTokenDepositedEvent
    shouldRevert_whenTokenAmountIsZero
    shouldRevert_whenTokenAddressIsZero
    shouldRevert_whenInsufficientTokens
    */
}

contract UnitTest_bridgeEther is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        dealEther(ALICE, 10 ether);
        vm.mockCall(BRIDGE, abi.encodeWithSelector(IPolygonZkEVMBridge.bridgeAsset.selector), abi.encode(""));
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized asAccount(ALICE) {
        c.bridgeEther();
    }

    function test_shouldEmitNoEtherToBridge_whenHoldingNoEther() public whenInitialized asAccount(ALICE) {
        // Initial balance should be 0
        assertEtherBalance(address(c), 0);

        vm.expectEmit(true, true, true, true);
        emit NoEtherToBridge();
        c.bridgeEther();
    }

    function test_shouldEmitEtherBridged_whenSuccessful() public whenInitialized asAccount(ALICE) {
        c.deposit{ value: 2 ether }(address(0), 0);
        vm.expectEmit(true, true, true, true);
        emit EtherBridged(L1BENEFICIARY, BRIDGE, 2 ether);
        c.bridgeEther();
    }
}

contract UnitTest_bridgeToken is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        c.initialize(L1BENEFICIARY);
        dealToken(address(c), TEST_TOKEN, 10 ether);

        vm.mockCall(BRIDGE, abi.encodeWithSelector(IPolygonZkEVMBridge.bridgeAsset.selector), abi.encode(""));
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized {
        c.bridgeToken(TEST_TOKEN);
    }

    function test_shouldRevert_whenTokenAddressIsZero() public {
        vm.expectRevert(TokenAddressCannotBeZero.selector);
        c.bridgeToken(address(0));
    }

    function test_shouldCallBridge_whenHoldingToken() public {
        c.bridgeToken(TEST_TOKEN);
    }

    function test_shouldEmitTokenBridged() public {
        vm.expectEmit(true, true, true, true);
        emit TokenBridged(L1BENEFICIARY, BRIDGE, TEST_TOKEN, 10 ether);
        c.bridgeToken(TEST_TOKEN);
    }

    function test_shouldRemoveTokenFromHeldTokens() public {
        dealToken(ALICE, TEST_TOKEN, 5 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        c.depositToken(TEST_TOKEN, 5 ether);
        assertEq(c.holdsToken(TEST_TOKEN), true, "Expected contract to hold TEST_TOKEN");
        c.bridgeToken(TEST_TOKEN);
        assertEq(c.holdsToken(TEST_TOKEN), false, "Expected contract to not hold TEST_TOKEN");
    }
}

contract UnitTest_bridgeAllTokens is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        c.initialize(L1BENEFICIARY);
        dealToken(ALICE, TEST_TOKEN, 10 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        vm.stopPrank();
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized {
        c.bridgeAllTokens();
    }

    function test_shouldRemoveTokenFromHeldTokens() public asAccount(ALICE) {
        c.depositToken(TEST_TOKEN, 1 ether);
        assertEq(c.holdsToken(TEST_TOKEN), true, "Expected contract to hold TEST_TOKEN");
        //c.bridgeToken(TEST_TOKEN);
        //assertEq(c.holdsToken(TEST_TOKEN), false, "Expected contract to not hold TEST_TOKEN");
    }
}

/*
contract UnitTest_holdsToken is AccumulatorTest {
    shouldRevert_whenNotInitialized
}


contract UnitTest_numHeldTokens is AccumulatorTest {
    shouldRevert_whenNotInitialized

}

*/

contract UnitTest__addToken is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        c.initialize(L1BENEFICIARY);
    }

    function test_shouldAddTokenAddressToHeldTokens() public {
        assertEq(c.holdsToken(TEST_TOKEN), false, "Expected that TEST_TOKEN is not in the _heldtokens array");
        c.addToken(TEST_TOKEN);
        assertEq(c.holdsToken(TEST_TOKEN), true, "Expected that TEST_TOKEN is in the _heldtokens array");
    }

    function test_shouldIncreaseNumberOfHeldTokens_whenNotPresent() public {
        assertNumHeldTokens(0);
        c.addToken(TEST_TOKEN);
        assertNumHeldTokens(1);
    }

    function test_shouldNotIncreaseNumberOfHeldTokens_whenAddingDuplicate() public {
        assertNumHeldTokens(0);
        c.addToken(TEST_TOKEN);
        assertNumHeldTokens(1);
        c.addToken(TEST_TOKEN);
        assertNumHeldTokens(1);
    }

    function test_shouldReturnTrue_whenTokenNotInHeldTokens() public {
        bool success = c.addToken(TEST_TOKEN);
        assertEq(success, true, "Expected the success return var to be true");
    }

    function test_shouldReturnFalse_whenTokenAlreadyInHeldTokens() public {
        // Add the token first
        c.addToken(TEST_TOKEN);
        // Add a second time
        bool success = c.addToken(TEST_TOKEN);
        assertEq(success, false, "Expected the success return var to be false when adding duplicate");
    }
}

contract UnitTest__removeToken is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        c.initialize(L1BENEFICIARY);
        // add tokens so that we have something to remove
        c.addToken(USDC_L2);
        c.addToken(TEST_TOKEN);
    }

    function test_shouldRemoveTokenAddressFromHeldTokens() public {
        assertEq(c.holdsToken(TEST_TOKEN), true, "Expected that TEST_TOKEN is in the _heldtokens array");
        c.removeToken(TEST_TOKEN);
        assertEq(c.holdsToken(TEST_TOKEN), false, "Expected that TEST_TOKEN is not in the _heldtokens array");
    }

    function test_shouldDecreaseNumberOfHeldTokens_whenPresent() public {
        assertNumHeldTokens(2);
        c.removeToken(TEST_TOKEN);
        assertNumHeldTokens(1);
    }

    function test_shouldNotDecreaseNumberOfHeldTokens_whenRemovingDuplicate() public {
        assertNumHeldTokens(2);
        c.removeToken(TEST_TOKEN);
        assertNumHeldTokens(1);
        c.removeToken(TEST_TOKEN);
        assertNumHeldTokens(1);
    }

    function test_shouldReturnTrue_whenTokenInHeldTokens() public {
        bool success = c.removeToken(TEST_TOKEN);
        assertEq(success, true, "Expected the success return var to be true");
    }

    function test_shouldReturnFalse_whenTokenNotInHeldTokens() public {
        // Remove the token
        c.removeToken(TEST_TOKEN);

        // Remove a second time
        bool success = c.removeToken(TEST_TOKEN);
        assertEq(success, false, "Expected the success return var to be false when adding duplicate");
    }
}

/*
contract UnitTest__tokenBalance is AccumulatorTest {

}

*/

contract UnitTest__approveBridgeForToken is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        dealToken(ALICE, TEST_TOKEN, 10 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        vm.stopPrank();
    }

    function test_shouldEmit_BridgeApprovedForTokenEvent() public {
        vm.expectEmit(true, true, true, true);
        emit BridgeApprovedForToken(TEST_TOKEN, 5000 ether);
        c.approveBridgeForToken(testToken, 5000 ether);
    }
}

contract UnitTest__allowanceIsSufficient is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        dealToken(ALICE, TEST_TOKEN, 10 ether);
        vm.startPrank(ALICE);
        testToken.approve(address(c), 5 ether);
        vm.stopPrank();
    }

    function test_shouldRevert_whenNotInitialized() public revertsWhenNotInitialized asAccount(ALICE) {
        c.allowanceIsSufficient(testToken, ALICE, 1 ether);
    }

    function test_shouldReturnTrue_whenSufficient() public whenInitialized asAccount(ALICE) {
        assertEq(
            c.allowanceIsSufficient(testToken, ALICE, 4 ether), true, "Expected allowanceIsSufficient to return true"
        );
    }

    function test_shouldReturnFalse_whenNotSufficient() public whenInitialized asAccount(ALICE) {
        assertEq(
            c.allowanceIsSufficient(testToken, ALICE, 10 ether), false, "Expected allowanceIsSufficient to return false"
        );
    }
}

contract UnitTest__validateToken is AccumulatorTest {
    function test_shouldRevert_whenTokenAddressIsNotAContract() public whenInitialized {
        vm.expectRevert(abi.encodeWithSelector(InvalidERC20Contract.selector, ALICE));
        c.validateToken(ALICE);
    }

    function test_shouldRevert_whenTokenAddressIsZero() public whenInitialized {
        vm.expectRevert(TokenAddressCannotBeZero.selector);
        c.validateToken(address(0));
    }
}

contract UnitTest_receive is AccumulatorTest {
    function setUp() public virtual override {
        super.setUp();
        c.initialize(L1BENEFICIARY);
        dealEther(ALICE, 10 ether);
    }

    function test_receivesDirectEthTranferSuccessfully() public asAccount(ALICE) {
        assertEtherBalance(address(c), 0);
        address(c).call{ value: 2 ether }("");
        assertEtherBalance(address(c), 2 ether);
    }

    function test_shouldEmitEtherDepositedEvent() public asAccount(ALICE) {
        vm.expectEmit(true, true, true, true);
        emit EtherDeposited(ALICE, 3 ether);
        address(c).call{ value: 3 ether }("");
    }
}
