
## pera- contracts

contract

## 
PERA TOKEN SMART CONTRACT
DEPLOYMENT GUIDE

```PERA Token Smart Contract Deployment Steps

1- Deploy the smart contract
2- Verify and publish the smart contract 
3- For the holder rewards to be distributed properly, contract owner should follow these steps after the contract deployment:
(excludeAccount function is used for excluding an address from being a holder so the given address do not receive holder
rewards, 0.75% of each on-chain PERA transaction. The operation is reversible. Contract owner can include the excluded
accounts back to being a holder. Smart contract function: includeAccount)
3-1- Exclude the token smart contract address
3-2- Exclude the contract owner address
3-3- Exclude the AMM-exchange router contract address (please check the latest contract address for the router)
Pancakeswap Router: 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
UniswapV2 Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
3-4- Provide the initial liquidity to an AMM-exchange
3-5- Exclude the pool address where the initial liquidity is provided
3-6- Add the contract address of the LP token that is created when the initial liquidity is provided to an AMMexchange. (Smart contract function: addLPToken)
3-7- If the token gets listed on a CEX, then the exchange wallet addresses should be excluded from being a holder
4- It is recommended to add the following accounts to the non-taxable list meaning that if an address from the list makes an
on-chain transaction, the smart contract does not apply any transaction fee on it. (excludeFromTax function is used for
assigning a wallet address as a non-taxable account)
4-1- Exclude the contract owner from taxation (In order not to mess up with the price calculation of the token when
the initial liquidity is added to an AMM-exchange)
4-2- Exclude the token contract from taxation (Transaction fee and mint rewards are first collected on the token
contract before distributing them to LP token stakers and trading competition winners. To avoid users to pay 2%
transaction fee on reward claims and not to mess up with the holder reward distribution rate, token contract should
be a non-taxable account)
4-3- If the token gets listed on a CEX, exchange wallet addresses should be assigned as non-taxable accounts
5- Contract owner can change the following parameters on the smart contract after the deployment:
5-1- LP token stakers emission reward multiplier (Initial value is set to 20, corresponding to 1.75 PERA/Block
emission reward on the Binance Smart Chain. Initial value of the multiplier value should be set according to the
number of blocks within a day in the blockchain that the smart contract is deployed. Smart contract function:
updateLPMultiplier)
5-2- Trading competition winners emission reward multiplier (Initial value is set to 20, corresponding to 19,600
PERA/Day emission reward. Smart contract function: updateTCMultiplier)
5-3- Minimum PERA transaction required for the trading competition (Initial value is set to 100 PERA tokens.
Smart contract function: updateminTCamount)
5-4- Holders transaction fee reward rate (Initial rate is set to 75 (0.75%). Smart contract function:
updateHolderRate)
5-5- LP token stakers transaction fee reward rate (Initial rate is set to 75 (0.75%). Smart contract function:updateLPRate)
5-6- Trading competition winners transaction fee reward rate (Initial rate is set to 50 (0.5%). Smart contract
function: updateTCRate)
6- Initial parameters to be set: 
6-1- BlockSizeForTC: Contract owner should be careful about setting the block size for the trading competition.
There are approximately 28,800 blocks within a day in the Binance Smart Chain & 6500 blocks in the Ethereum
Network)
6-2- tenYearsasBlock: PERA token emission schedule is set to last for 10 years. In case of a different emission
schedule, contract owner should set the time to desired value in terms of how many blocks the emission will last
for. 
6-3- totalTCwinners: Number of users who are eligible to win and claim the daily trading competition rewards.
Initial value is set to 10 users
```
