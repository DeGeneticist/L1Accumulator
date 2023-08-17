<img align="center" top="100" src="./public/llama.png">

# L1BeneficiaryAccumulator

## Accumulates and Bridges funds on zkEVM on behalf of an L1 address

## Overview
This project enables users of the Polygon zkEVM Layer-2 blockchain to send funds to users or organizations
that are only able to receive funds at a Layer-1 address (i.e. Ethereum mainnet) via the canonical zkEVM bridge.

The L1BeneficiaryAccumulator contract allows anyone to deposit Ether or ERC-20 tokens for the benefit of 
a specific Layer-1 address via the deposit() function. These funds are held by the contract and accumulate
until the bridgeAssets() function is called. When bridgeAssets() is called, all funds held by the contract
will be bridged to the Layer-1 address via the canonical bridge contract. The deposit() and bridgeAssets()
functions may be called by any user.

The L1BeneficiaryAccumulator contract is meant to be deployed on the Polygon zkEVM L2 blockchain.
Once deployed, users of zkEVM can deposit Ether or ERC-20 tokens to this contract which will
be held for the benefit of a beneficiary account on the L1 blockchain (mainnet).
The funds will accumulate in this contract until someone calls the "bridgeAssets()" function,
which will bridge all of the Ether and ERC-20 tokens to the beneficiary via the canonical
zkEVM bridge (LxLy).

A new instance of the L1BeneficiaryAccumulator must be deployed for each beneficiary address. In order
to reduce gas fees, this project is written to utilize ERC-1167 Minimal Proxy contracts. All of the necessary
logic is deployed as a single implmentation instance, and an ERC-1167 minimal proxy contract is deployed for
each L1 beneficiary. As a convenience, a separate AccumulatorFactory contract has been provided which enables
anyone to easily deploy a proxy contract for an L1 address.


## Deployed Instances
Anyone can deploy an instance of L1BeneficiaryAccumulator for any L1 address by accessing the
the deploy function on the AccumulatorFactory contract. The deployed contracts may be accessed directly, or via the [zkevm.polygonscan.com](https://zkevm.polygonscan.com) interface.

If anyone wants to build a dApp interface for these contracts, please feel free 😁.

### Canonical Implementations
An instance of AccumulatorFactory has been deployed to: 
- [0x0439759875f603b7cAf1241b10e24A62A6d0afF5](https://zkevm.polygonscan.com/address/0x0439759875f603b7cAf1241b10e24A62A6d0afF5)
- To deploy a new L1BeneficiaryAccumulator Instance, call the deploy() function on the AccumulatorFactory contract.

This factory creates ERC-1167 Minimal Proxy contracts (clones) of the L1BeneficiaryAccumulator Implementation deployed here: 
- [0xF472c730FE8503e3D0da483f9f1DAe39D33dAc6B](https://zkevm.polygonscan.com/address/0xF472c730FE8503e3D0da483f9f1DAe39D33dAc6B)

### L1BeneficiaryAccumulator Instance Usage
- Ether may be send directly to the contract address, or deposited using the deposit() function
- If Ether is sent via the deposit() function, the _token address must be the zero address, and Ether should be sent with the transaction
-To deposit an ERC20 token, the deposit() function must be used, and the L1BeneficiaryAccumulator contract must be approved to spend the ERC20 token on belhalf of the user calling deposit()
    - this would typically be handled in the front-end dApp

- All assets held by the contract can be bridged to L1 by calling bridgeAssets()

- Individual tokens can be bridged by calling bridgeToken(), likewise Ether can be independently bridged by calling bridgeEther()


### Example L1BeneficiaryAccumulator Instances
A few example Accumulators have been deployed for the following L1 addresses:

|Beneficiary | L1 Address                                   | Accumulator Contract Address |
|------------|-------------------------------------|------------------------------|
| ENS | [0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7](https://etherscan.io/address/0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7) | [0xc9b4254F6cc25c98Ca0563De6cCb9C7Fa1ecF10B](https://zkevm.polygonscan.com/address/0xc9b4254F6cc25c98Ca0563De6cCb9C7Fa1ecF10B#writeContract)|
| TPG | [0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9](https://etherscan.io/address/0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9) | [0x953D9b27405e2C38e06B2B091c6a77ED773f3a00](https://zkevm.polygonscan.com/address/0x953D9b27405e2C38e06B2B091c6a77ED773f3a00#writeContract)|
| Tor | [0x7f0eea9c38f54d977f958543db3f21d3aed94b80](0x7F0eeA9C38f54D977F958543dB3f21D3aeD94B80) | [0xB3e9308790A018e0EBfA1fFdD5e27F49BED07D7F](https://zkevm.polygonscan.com/address/0xB3e9308790A018e0EBfA1fFdD5e27F49BED07D7F#writeContract)|
| Tip Jar 😇 | [0xC4bA6C10203CB0824325d29A3bdbF9EB0a7407eA](https://etherscan.io/address/0xC4bA6C10203CB0824325d29A3bdbF9EB0a7407eA) | [0x34d379e46ca1a7853015bFa4aF118378BB102D67](https://zkevm.polygonscan.com/address/0x34d379e46ca1a7853015bFa4aF118378BB102D67#writeContract)



## Development
### Overview
This project is developed using the Foundry / forge testing framework (insert link to foundry book)


### Configuration
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




### Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._

See [LICENSE](./LICENSE) for more details.
