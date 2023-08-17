// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import "src/AccumulatorFactory.sol";
import "src/Accumulator.sol";
import "src/IAccumulator.sol";

/// @notice A very simple deployment script
contract Deploy is Script {
    uint32 public originNetworkId;
    uint32 public maxTokensToBridge;
    address public bridge;
    address L1BeneficiaryAccumulatorImpl;
    address AccumulatorFactoryAddress;
    AccumulatorFactory public factory;

    // L1 Addresses
    address public ENS_L1;
    address public TPG_L1;
    address public Tor_L1;
    address public DeGeneticist_L1;




    function init() public {

        ENS_L1 = _label(0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7, "ENS_L1");
        TPG_L1 = _label(0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9, "TPG_L1");
        Tor_L1 = _label(0x7F0eeA9C38f54D977F958543dB3f21D3aeD94B80, "Tor_L1");
        DeGeneticist_L1 = _label(0xC4bA6C10203CB0824325d29A3bdbF9EB0a7407eA, "DeGeneticist_L1"); 

        bridge = _label(vm.envAddress("DEPLOY_BRIDGE_ADDRESS"), "zkEVM Bridge");
        originNetworkId = uint32(vm.envUint("DEPLOY_ORIGIN_NETWORK_ID"));
        maxTokensToBridge = uint32(vm.envUint("DEPLOY_MAX_TOKENS_TO_BRIDGE"));
    }


    function _label(address _address, string memory _name) internal returns (address) {
        vm.label(_address, _name);
        return _address;
    }


    function deployImplementationContract() public {
        console2.log("Deploying L1BeneficiaryAccumulator implementation contract...");
        L1BeneficiaryAccumulator implementation = new L1BeneficiaryAccumulator(bridge, originNetworkId, maxTokensToBridge);

        L1BeneficiaryAccumulatorImpl = _label(address(implementation), "L1BeneficiaryAccumulatorImpl");
        console2.log("Deployed L1BeneficiaryAccumulator implementation contract at address: %s", L1BeneficiaryAccumulatorImpl);

        console2.log("Locking the implementation contract to prevent potential hijacking...");
        implementation.lock();
        console2.log("Locked the implementation contract.");
    }

    function deployFactoryContract() public {
        console2.log("Deploying AccumulatorFactory contract...");
        factory = new AccumulatorFactory(L1BeneficiaryAccumulatorImpl);
        AccumulatorFactoryAddress = _label(address(factory), "AccumulatorFactory");
        console2.log("Deployed AccumulatorFactory contract at address: %s", AccumulatorFactoryAddress);
    }


    function deploySampleAccumulator(address L1BeneficiaryAddress) public {
        console2.log("Deploying sample accumulator for L1 address: %s", L1BeneficiaryAddress);
        address accumulatorAddress = factory.deploy(L1BeneficiaryAddress);
        console2.log("Deployed sample accumulator at address: %s", accumulatorAddress);
    }


    /// @notice The main script entrypoint
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");
        console2.log("Deploying contracts...");
        vm.startBroadcast(deployerPrivateKey);
        init();
        deployImplementationContract();
        deployFactoryContract();

        // deploy some sample accumulators for L1 addresses
        // ENS
        deploySampleAccumulator(ENS_L1);
        // TPG
        deploySampleAccumulator(TPG_L1);
        // Tor
        //deploySampleAccumulator(Tor_L1);
        // DeGeneticist Tip Jar 😇
        deploySampleAccumulator(DeGeneticist_L1); 
        vm.stopBroadcast();
    }
}
