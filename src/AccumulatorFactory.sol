// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/proxy/Clones.sol";
import "./Accumulator.sol";

contract AccumulatorFactory {
    //L1BeneficiaryAccumulator public immutable implementation;
    address public immutable implementationAddr;

    constructor(address implAddr) {
        implementationAddr = implAddr;
    }

    function deploy(address L1Beneficiary) public returns (address instanceAddress) {
        IAccumulator instance;
        instanceAddress = Clones.clone(implementationAddr);

        // Initialize the clone contract
        instance = IAccumulator(instanceAddress);

        instance.initialize(L1Beneficiary);

        //emit something FIXME
        return instanceAddress;
    }
}
