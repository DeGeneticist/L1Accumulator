// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/proxy/Clones.sol";
import "./Accumulator.sol";

contract AccumulatorFactory {
    //L1BeneficiaryAccumulator public immutable implementation;
    address public immutable implementationAddr;

    /// @notice Event emitted when a ERC-1167 clone of L1BeneficiaryAccumulator is deployed.
    /// @param deployer Address of the account that deployed the clone.
    /// @param beneficiary Address of the beneficiary (on L1).
    /// @param contractAddress Address of the deployed L1BeneficiaryAccumulator instance.
    event L1BeneficiaryAccumulatorDeployed(address indexed deployer, address indexed beneficiary, address indexed contractAddress); 

    constructor(address implAddr) {
        implementationAddr = implAddr;
    }

    function deploy(address L1Beneficiary) public returns (address ) {
        IAccumulator instance;
        address instanceAddress = Clones.clone(implementationAddr);

        // Initialize the clone contract
        instance = IAccumulator(instanceAddress);

        instance.initialize(L1Beneficiary);

        emit L1BeneficiaryAccumulatorDeployed(msg.sender, L1Beneficiary, instanceAddress);
        return address(instance);
    }
}
