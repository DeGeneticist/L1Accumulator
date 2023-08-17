// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAccumulator.sol";

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "lib/IPolygonZkEVMBridge.sol";

import "@openzeppelin/security/ReentrancyGuard.sol";
import "@openzeppelin/utils/structs/EnumerableSet.sol";
import "@openzeppelin/utils/Address.sol";

/// @title L1BeneficiaryAccumulator
/// @author DeGeneticist (DeGeneticist.eth)
/// @notice This contract accumulates deposits of Ether and ERC20 tokens on zkEVM, and bridges them to the Beneficiary's
///         address on Layer 1 via the zkEVM canonical bridge. A new ERC-1167 clone of this contract should be deployed for each
///         L1 beneficiary via the AccumulatorFactory.
/// @dev The contract utilizes OpenZeppelin libraries for security and convenience. It's intended to be deployed as a
///      minimal proxy (clone), so the beneficiary must be set outside of the constructor.
contract L1BeneficiaryAccumulator is IAccumulator, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Utilize the OpenZeppelin EnumerableSet library for O(1) add, remove, and check for existence
    using EnumerableSet for EnumerableSet.AddressSet;

    // Set of all ERC20 tokens currently held by this contract
    EnumerableSet.AddressSet internal _heldTokens;

    // Maximum number of tokens to bridge in one attempt
    uint32 public maxTokensToBridge;

    // Origin network identifier (Layer 2 network ID)
    //uint32 public constant originNetworkId = 0;
    uint32 public immutable originNetworkId;

    // Address of the zkEVM bridge on L2
    address public immutable bridge;

    // Address of the beneficiary on L1
    address public beneficiary;

    // Flag to indicate whether the contract has been initialized
    bool internal _initialized;

    // Flag to indicate whether the contract is locked to prevent initialization
    bool internal _locked;

    /// ------------------------ Modifiers ------------------------ ///

    /// @notice This modifier prevents public functions from executing before the contract has been
    ///         initialized with an L1 beneficiary.
    /// @dev As this contract is intended to be deployed as a minimal proxy (clone), the beneficiary
    ///      must be set outside of the constructor.
    modifier onlyInitialized() {
        if (!_initialized) {
            revert ContractIsNotInitialized();
        } else {
            _;
        }
    }

    /// ------------------------ Constructor ------------------------ ///

    constructor(
        address _bridge, 
        uint32 _originNetworkId, 
        uint32 _maxTokensToBridge
        ) 
    {
        _locked = false;
        _initialized = false;
        bridge = _bridge;
        originNetworkId = _originNetworkId;
        maxTokensToBridge = _maxTokensToBridge;
    }

    /// ------------------------ Receive / Fallback ------------------------ ///

    /// @notice Minimal payable implementation to enable direct transfers of Ether to this contract.
    /// @dev Emits an EtherDeposited event upon receiving Ether.
    receive() external payable nonReentrant {
        emit EtherDeposited(msg.sender, msg.value);
    }

    /// @notice Minimal fallback implementation.
    /// @dev Reverts the transaction with an InvalidTransaction error.
    fallback() external payable nonReentrant {
        revert InvalidTransaction();
    }

    /// ------------------------ External Functions ------------------------ ///

    /// @notice Locks the contract preventing it from being initialized.
    /// @dev Once locked, the contract cannot be unlocked or initialized.
    ///      This function should be called on the implementation instance,
    ///      immediately after it is deployed, preventing the logic implementation
    ///      from being directly executable, unlike the ERC-1167 proxy contracts
    ///      that will call it. Any address can call this function.
    function lock() external {
        if (_locked) {
            revert ContractIsLocked();
        }

        // Lock the contract to prevent further initialization
        _locked = true;
        emit ContractInitializationLocked();
    }

    /// @notice Initializes a new cloned deployment (ERC-1167) with it's own beneficiary address.
    ///    This must be called immediately after the clone contract is deployed.
    /// @dev Most external/public functions of this contract will be uncallable before this function
    ///     has been called. If an instance of this contract has been locked, it cannot be initialized
    ///     (this allows us to prevent the logic implementation instance from being initialized).
    /// @param _beneficiary Address (on the L1 blockchain) of the beneficiary of this contract
    function initialize(address _beneficiary) external {
        // revert if the contract has already been initialized
        if (_initialized) {
            revert ContractAlreadyInitialized();
        }

        // revert if the contract has been locked (e.g. the logic implementation instance)
        if (_locked) {
            revert ContractIsLocked();
        }

        if (_beneficiary == address(0)) {
            revert BeneficiaryCannotBeZeroAddress();
        }

        beneficiary = _beneficiary;
        _initialized = true;
        emit ContractInitialized(beneficiary);
    }

    /// @notice Returns an array of all the ERC20 tokens held by this contract
    /// @dev Provided as a UI convenience, it is not advisable to call this from a smart contract
    ///     due to potentially unbounded gas fees, based on the size of the array. If you must
    ///     call this function in a transaction that costs gas, it's advised that you first
    ///     check the size of the array via numHeldTokens(), and then call getAllHeldTokens()
    /// @return tokens Array of addresses of the ERC20 tokens currently held by this contract.
    function getAllHeldTokens() external view onlyInitialized returns (address[] memory tokens) {
        return _heldTokens.values();
    }

    /// @notice Deposit ETH or ERC20 tokens to be held for the beneficiary on Layer 1
    /// @notice NOTE: Only ERC20 tokens that are bridgeable by the Bridge contract can be deposited
    /// @dev If the token address is 0x0000, the deposit is treated as Ether, otherwise it is treated as an ERC20 token
    /// @param _token address of the token to deposit, or 0x0000 if depositing Ether - ERC20 tokens must be bridgeable
    /// by the Bridge contract
    /// @param _amount uint256 amount of the token to deposit, if depositing an ERC20 token; if depositing Ether, the
    /// amount is taken from the transaction value
    function deposit(address _token, uint256 _amount) external payable onlyInitialized {
        if (_token == address(0)) {
            // Depositing the base token (Ether)
            if (msg.value == 0) {
                revert CannotDepositZeroEther(msg.sender);
            }
            emit EtherDeposited(msg.sender, msg.value);
        } else {
            depositToken(_token, _amount);
        }
    }

    /// @notice Bridge all held Ether and Tokens to the L1 Beneficiary address
    /// @dev Calls bridgeEther and bridgeAllTokens
    function bridgeAssets() external {
        bridgeEther();
        bridgeAllTokens();
    }

    function getTokenBalance(address _token) public view onlyInitialized returns (uint256 balance) {
        if (_token == address(0)) {
            revert TokenAddressCannotBeZero();
        }
        if (!Address.isContract(_token)) {
            revert InvalidERC20Contract(_token);
        }
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    /// ------------------------ Public Functions ------------------------ ///

    /// @notice Deposit some amount of ERC20 token to this contract to be held for the beneficiary
    /// @dev The address of this contract must be approved by the user to transfer at least "_amount" of the ERC20 token
    /// @param _token address of the ERC20 token's contract - cannot be the zero address
    /// @param amount amount of the ERC20 token to be deposited -- cannot be zero
    function depositToken(address _token, uint256 amount) public onlyInitialized nonReentrant {
        IERC20 token = _validateToken(_token);
        uint256 currentBalance;
        uint256 amountTransferred;

        if (amount == 0) {
            revert CannotDepositZeroTokens();
        }
        if (!_allowanceIsSufficient(token, msg.sender, amount)) {
            revert InsufficientTokenAllowance(_token, msg.sender, amount);
        }
        // add token to _heldTokens
        _addToken(_token);

        // Get the current balance of this token owned by this contract
        currentBalance = _tokenBalance(token);
        token.safeTransferFrom(msg.sender, address(this), amount);
        amountTransferred = _tokenBalance(token) - currentBalance;
        emit TokenDeposited(_token, msg.sender, amountTransferred);
    }

    /// @notice Bridge all held Ether to the L1 Beneficiary address
    /// @dev Meant to be called by bridgeAssets(), but may be called independently
    function bridgeEther() public onlyInitialized nonReentrant {
        uint256 etherBalance = address(this).balance;
        if (etherBalance > 0) {
            IPolygonZkEVMBridge _bridge = IPolygonZkEVMBridge(bridge);
            try _bridge.bridgeAsset{ value: etherBalance }(
                originNetworkId, beneficiary, etherBalance, address(0), true, ""
            ) {
                emit EtherBridged(beneficiary, bridge, etherBalance);
            } catch {
                revert BridgeEtherFailed(beneficiary, bridge, etherBalance);
            }
        } else {
            emit NoEtherToBridge();
        }
    }

    /// @notice Bridge a single ERC20 token to the beneficiary on Layer 1 via the bridge contract
    /// @dev This function is called by bridgeAllTokens() - not intended to be called directly, but can be if needed
    /// @param _token address of the token to bridge - must be bridgeable by the Bridge contract
    function bridgeToken(address _token) public onlyInitialized {
        IERC20 token = _validateToken(_token);
        uint256 balance = getTokenBalance(_token);
        IPolygonZkEVMBridge _bridge = IPolygonZkEVMBridge(bridge);

        if (balance > 0) {
            _approveBridgeForToken(token, balance);
            try _bridge.bridgeAsset(originNetworkId, beneficiary, balance, _token, true, "") {
                emit TokenBridged(beneficiary, bridge, _token, balance);
                _removeToken(_token);
            } catch {
                revert BridgeTokenFailed(beneficiary, bridge, _token, balance);
            }
        } else {
            _removeToken(_token);
        }
    }

    /// @dev Function to bridge all held tokens to Layer 1; iterates through the _heldTokens
    ///     array and bridges eachtoken
    ///     meant to be called by bridgeAssets(), but may be called independently
    function bridgeAllTokens() public onlyInitialized {
        uint256 numHeld = numHeldTokens();
        uint256 n;
        if (numHeld < maxTokensToBridge) {
            n = numHeld;
        } else {
            n = maxTokensToBridge;
        }
        for (n; n > 0; n--) {
            // bridge the token
            bridgeToken(_heldTokens.at(n - 1));
        }
    }

    /// @notice Checks if a specific ERC20 token is held by this contract
    /// @dev Uses the OpenZeppelin EnumerableSet.AddressSet for O(1) lookups
    /// @param tokenAddr L2 address of ERC20 token
    function holdsToken(address tokenAddr) public view returns (bool) {
        return _heldTokens.contains(tokenAddr);
    }

    function numHeldTokens() public view returns (uint256 numTokens) {
        return _heldTokens.length();
    }

    /// ------------------------ Internal Functions ------------------------ ///

    ///@notice Adds an ERC20 token address to _heldTokens (if it is not already present)
    ///@dev Uses OpenZeppelin's EnumerableSet library, for O(1) performance.
    ///    Emits an AddedToken(address) event if the token was not present
    ///@param tokenAddr Address of the ERC20 token contract to be added
    ///@return success Returns true if the address was newly added to the set,
    ///    and false if it was already present (pass-through of EnumerableSet's return value)
    function _addToken(address tokenAddr) internal returns (bool success) {
        success = _heldTokens.add(tokenAddr);
        if (success) {
            emit AddedToken(tokenAddr);
        }
        return success;
    }

    ///@notice Removes an ERC20 token address from _heldTokens (if it is present)
    ///@dev Uses OpenZeppelin's EnumerableSet library, for O(1) performance.
    ///    Emits a RemovedToken(address) event if the token was not present
    ///@param tokenAddr Address of the ERC20 token contract to be added
    ///@return success Returns true if the address was removed from the set,
    ///    and false if it was not present (pass-through of EnumerableSet's return value)
    function _removeToken(address tokenAddr) internal returns (bool success) {
        success = _heldTokens.remove(tokenAddr);
        if (success) {
            emit RemovedToken(tokenAddr);
        }
        return success;
    }

    function _tokenBalance(IERC20 token) internal view returns (uint256 balance) {
        return token.balanceOf(address(this));
    }

    /// @notice Approves the bridge contract to transfer tokens on behalf of this contract.
    /// @dev Uses OpenZeppelin's SafeERC20 library's "forceApprove()", which automatically handles ERC20
    ///    tokens that require the spender's allowance to be set to zero prior to calling approve().
    /// @param token Initialized interface to the ERC20 token; it is expected that sanity checks are performed prior to
    ///     this function being called
    function _approveBridgeForToken(IERC20 token, uint256 _amount) internal nonReentrant {
        token.forceApprove(bridge, 2 ^ 256);
        emit BridgeApprovedForToken(address(token), _amount);
    }

    /// @notice Checks if the token allowance for this contract from `_owner` is sufficient.
    ///     This function will check the given ERC20 token contract to see if the allowance
    ///     set by `_owner` for this contract is greater than or equal to `_required`. If the allowance is
    ///     sufficient, it returns true; otherwise, it returns false.
    ///
    /// @dev This contract uses OpenZeppelin SafeERC20 to protect against buggy ERC20 implementations,
    ///     as well as the nonReentrant modifier to protect against reentrant ERC20 contracts.
    ///     This contract could be additionally secured by only allowing a whitelist of ERC20 tokens.
    ///     It is expected that the token parameter should be created by _validateToken to ensure
    ///     that various sanity checks are performed, but not repeated needlessly.
    ///
    /// @param token A SafeERC20 initialized for the ERC20 token conract
    /// @param owner The address of the token owner who is depositing to this contract
    /// @param amount The minimum allowance required to complete the deposit
    ///
    /// @return sufficient A boolean value indicating whether the allowance is high enough
    function _allowanceIsSufficient(
        IERC20 token,
        address owner,
        uint256 amount
    )
        internal
        view
        onlyInitialized
        returns (bool sufficient)
    {
        if (token.allowance(owner, address(this)) >= amount) {
            return true;
        } else {
            return false;
        }
    }

    ///@notice Performs some basic sanity checks on an ERC20 token address
    ///@dev Utilizes OpenZeppelin's Address library to verify the address is a contract and
    ///     the SafeERC20 library to prevent issues with contracts with certain non-standard ERC20
    ///     implementations. All validation of ERC20 addresses is performed in this function,
    ///     and the initialized contract interface is returned for use by other functions in
    ///     this contract.
    ///@param _token Address of the ERC20 contract
    ///@return token IERC20 contract interface using OpenZeppelin's SafeERC20 library
    function _validateToken(address _token) internal view returns (IERC20 token) {
        if (_token == address(0)) {
            revert TokenAddressCannotBeZero();
        }
        if (!Address.isContract(_token)) {
            revert InvalidERC20Contract(_token);
        }
        return IERC20(_token);
    }
}
