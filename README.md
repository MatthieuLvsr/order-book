# Order book 📖🤌💲
___

### Introduction 

The idea of this project is to setup a simple order book where users can register sells and buys. 

#### Installation 🏗️

In order to use this project you should have [Foundry 🔨](https://book.getfoundry.sh/) on your machine.

The next step is to setup your environment as follow :
```
RPC_URL=<YOUR_RPC_URL>
PRIVATE_KEY=<YOUR_PRIVATE_KEY>
```
___
#### Usage

There are a few command lines to use this project :

1. Build
    ```bash
    forge build
    ```
2. Test
    ```bash
    forge test
    ```
3. Coverage
    ```bash
    forge coverage
    ```
4. Improved coverage 😉
    ```bash
    forge coverage --report lcov
    genhtml -o report lcov.info
    ```
5. Deployment
    ```bash
    forge script script/Deploy.s.sol:DeployBook --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv --private-key $PRIVATE_KEY --legacy
    ```
6. Buy
    ```bash
    forge script script/Interact.s.sol:Buy --rpc-url $RPC_URL --broadcast --verify -vvvv --private-key $PRIVATE_KEY --legacy
    ```
7. Sell
    ```bash
    forge script script/Interact.s.sol:Sell --rpc-url $RPC_URL --broadcast --verify -vvvv --private-key $PRIVATE_KEY --legacy
    ```
___
#### Details

***How does it works ?*** 🤔

The idea is simple. The contract store an array of all buys and sells registered.
When a user want to sell a volume of token for a price, the contract check if buyer registered a buy order for this, if we found a match then we process the transaction, in other way we register a new sell order.
The same process work in the opposite way.

***Can I sell less token for the price of my order ?*** 😎

Not yet, but in the next update we would like to implement partial matching.
___
#### Improvement

I have a few ideas to improve this application :
1. **Allow partial matching:** A user would probably accept to get more token for the same price if there is an opportunity. In the same way, a seller may be happy to sell less token for the same price ! 🤑
2. **A Web3 application:** A web3 app would be easier to interact with and is way more user friendly than a simple command line prompt. 🙋
3. **Statistics:** A bunch of stats could be easy to implement and maybe usefull for traders such as the higher and lower asks and bids and the spread of it. 📊
___
