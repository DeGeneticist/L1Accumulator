<img align="right" width="150" height="150" top="100" src="./public/readme.jpg">
# L1BeneficiaryAccumulator
## Accumulates Ether and ERC20 tokens on Polygon zkEVM on behalf of an address on Ethereum mainnet (or any Layer 1 EVM)


## Overview
The L1BeneficiaryAccumulator contract is meant to be deployed on the Polygon zkEVM L2 blockchain.
Once deployed, users of zkEVM can deposit Ether or ERC-20 tokens to this contract which will
be held for the benefit of a beneficiary account on the L1 blockchain (mainnet).
The funds will accumulate in this contract until someone calls the "bridgeAssets()" function,
which will bridge all of the Ether and ERC-20 tokens to the beneficiary via the canonical
zkEVM bridge (LxLy).

A new instance of the L1BeneficiaryAccumulator must be deployed for each beneficiary address,
this is accomplished with the AccumulatorFactory contract.


## Configuration
Configuration is via environment variables. Copy the .env.example file and fill in the missing values.
```shell
cp .env.example .env
```

### Usage

**Building & Testing**

This project is developed using the [Foundry](https://book.getfoundry.sh/) framework. 
If you do not wish to install Foundry, you can optionally run everything via the foundry Dockerfile.

To run the tests (with foundry / forge installed):

```shell
forge test
```

To run the tests with Docker:
```shell
docker run -t --rm -v ${PWD}:/app -w /app ghcr.io/foundry-rs/foundry "forge test"
```


To check test coverage:

```shell
forge coverage
```

or via Docker:

```shell
docker run -t --rm -v ${PWD}:/app -w /app ghcr.io/foundry-rs/foundry "forge coverage"
```






Build the foundry project with `forge build`. Then you can run tests with `forge test`.

**Deployment & Verification**

Inside the [`utils/`](./utils/) directory are a few preconfigured scripts that can be used to deploy and verify contracts.

Scripts take inputs from the cli, using silent mode to hide any sensitive information.

_NOTE: These scripts are required to be _executable_ meaning they must be made executable by running `chmod +x ./utils/*`._

_NOTE: these scripts will prompt you for the contract name and deployed addresses (when verifying). Also, they use the `-i` flag on `forge` to ask for your private key for deployment. This uses silent mode which keeps your private key from being printed to the console (and visible in logs)._

### Blueprint

```txt
lib
├─ forge-std — https://github.com/foundry-rs/forge-std
├─ openzeppelin-contracts — https://github.com/OpenZeppelin/openzeppelin-contracts
├─ IPolygonZkEVMBridge - contracts/interfaces/IPolygonZkEVMBridge.sol
scripts
├─ Deploy.s.sol — Deployment Script that deploys an implementation (logic) contract, and a Clone Factory contract
src
├─ Accumulator.sol
├─ AccumulatorFacory.sol
├─ IL1BeneficiaryAccumulator.sol
test
├─ AccumulatorUnitTests.t.sol - Unit tests for the Accumulator contract
├─ ForkTests.t.sol - Fork tests for Accumulator and AccumulatorFactory contracts
├─ Util.t.sol - Test utilities and helpers
├─ 
└─ Greeter.t — Example Contract Tests
```


### Notable Mentions

- [femplate](https://github.com/refcell/femplate)
- [foundry](https://github.com/foundry-rs/foundry)
- [solmate](https://github.com/Rari-Capital/solmate)
- [forge-std](https://github.com/brockelmore/forge-std)
- [forge-template](https://github.com/foundry-rs/forge-template)
- [foundry-toolchain](https://github.com/foundry-rs/foundry-toolchain)


### Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._

See [LICENSE](./LICENSE) for more details.
