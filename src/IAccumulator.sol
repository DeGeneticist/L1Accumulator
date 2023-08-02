// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAccumulator {
    /// ------------------------ Events ------------------------ ///

    /// @notice Event emitted when a token is already held by the contract.
    /// @param token The address of the token that is already held.
    event TokenIsAlreadyHeld(address indexed token);

    /// @notice Event emitted when a new token is added to the contract.
    /// @param token The address of the token that is added.
    event AddedToken(address indexed token);

    /// @notice Event emitted when a token is removed from the contract.
    /// @param token The address of the token that is removed.
    event RemovedToken(address indexed token);

    /// @notice Event emitted when a deposit of a token is made.
    /// @param token The address of the token deposited.
    /// @param sender The address of the sender making the deposit.
    /// @param amount The amount of tokens deposited.
    event TokenDeposited(address indexed token, address indexed sender, uint256 amount);

    /// @notice Event emitted when the contract initialization is locked.
    event ContractInitializationLocked();

    /// @notice Event emitted when Ether is deposited to the contract.
    /// @param sender The address of the sender depositing Ether.
    /// @param amount The amount of Ether deposited.
    event EtherDeposited(address indexed sender, uint256 amount);

    /// @dev Event emitted when a token is deposited into the contract
    /// @param sender address of the sender depositing the token
    /// @param token address of the token deposited
    /// @param amount uint256 amount of the token deposited
    //event TokenDeposited(address indexed sender, address indexed token, uint256 amount);

    /// @notice Event emitted when Ether is bridged from Layer 2 to Layer 1.
    /// @param beneficiary The address of the beneficiary on Layer 1.
    /// @param bridge The address of the bridge contract.
    /// @param amount The amount of Ether bridged.
    event EtherBridged(address indexed beneficiary, address indexed bridge, uint256 amount);

    /// @notice Event emitted if bridging Ether is attempted when the accumulator holds no Ether
    event NoEtherToBridge();

    /// @notice Event emitted when a token is bridged from Layer 2 to Layer 1.
    /// @param beneficiary The address of the beneficiary on Layer 1.
    /// @param bridge The address of the bridge contract.
    /// @param token The address of the token bridged.
    /// @param amount The amount of the token bridged.
    event TokenBridged(address indexed beneficiary, address indexed bridge, address indexed token, uint256 amount);

    /// @notice Event emitted when the contract is initialized.
    /// @param beneficiary The address of the beneficiary.
    event ContractInitialized(address indexed beneficiary);

    /// @notice Event emitted when the bridge contract's allowance to spend an ERC20 token on behalf of this contract is
    /// changed.
    /// @param token The address of the ERC20 token.
    /// @param amount The updated amount that the bridge contract can spend.
    event BridgeApprovedForToken(address indexed token, uint256 amount);

    /// ------------------------ Errors ------------------------ ///

    /// @notice Error thrown when an action is performed on a contract that is locked.
    error ContractIsLocked();

    /// @notice Error thrown when an attempt is made to deposit zero Ether.
    /// @param sender The address of the sender trying to deposit zero Ether.
    error CannotDepositZeroEther(address sender);

    /// @notice Error thrown when an attempt is made to deposit zero tokens.
    error CannotDepositZeroTokens();

    /// @notice Error thrown when an attempt is made to bridge zero Ether.
    error CannotBridgeZeroEther();

    /// @notice Error thrown when there's a failure in bridging Ether.
    /// @param beneficiary The address of the beneficiary.
    /// @param bridge The address of the bridge contract.
    /// @param balance The current balance of the contract.
    error BridgeEtherFailed(address beneficiary, address bridge, uint256 balance);

    /// @notice Error thrown when there's a failure in bridging a specific token.
    /// @param beneficiary The address of the beneficiary.
    /// @param bridge The address of the bridge contract.
    /// @param token The address of the token to be bridged.
    /// @param amount The amount of the token to be bridged.
    error BridgeTokenFailed(address beneficiary, address bridge, address token, uint256 amount);

    /// @notice Error thrown when the token allowance is insufficient.
    /// @param token The address of the token.
    /// @param owner The address of the owner.
    /// @param required The required amount of allowance.
    error InsufficientTokenAllowance(address token, address owner, uint256 required);

    /// @notice Error thrown when the token address is zero.
    error TokenAddressCannotBeZero();

    /// @notice Error thrown when the provided address is not a valid ERC20 contract.
    /// @param token The invalid ERC20 token's contract address.
    error InvalidERC20Contract(address token);

    /// @notice Error thrown when approval for the bridge to transfer tokens fails.
    /// @param token The address of the token.
    /// @param amount The number of tokens to approve.
    error ApproveBridgeForTokenFailed(address token, uint256 amount);

    /// @notice Error thrown when an attempt is made to initialize an already initialized contract.
    error ContractAlreadyInitialized();

    /// @notice Error thrown when an action is performed on a contract that has not been initialized.
    error ContractIsNotInitialized();

    /// @notice Error thrown when the beneficiary address is zero during contract initialization.
    error BeneficiaryCannotBeZeroAddress();

    /// @notice Error thrown by the fallback function.
    error InvalidTransaction();

    function lock() external;
    function initialize(address _beneficiary) external;
    function getAllHeldTokens() external view returns (address[] memory tokens);
    function deposit(address _token, uint256 _amount) external payable;
    function bridgeAssets() external;
    function getTokenBalance(address _token) external view returns (uint256 balance);
    function depositToken(address _token, uint256 amount) external;
    function bridgeEther() external;
    function bridgeToken(address _token) external;
    function bridgeAllTokens() external;
    function holdsToken(address tokenAddr) external view returns (bool);
    function numHeldTokens() external view returns (uint256 numTokens);
}
