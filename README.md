# Hats Challenge #2

## Capture the Flag

The contract [`Vault.sol`](./contracts/Vault.sol) is an ERC4626-like vault customized to be used with ETH.
It allows anyone to deposit ETH in the vault and get shares corresponding to the amount deposited.
The shares are an ERC20 which can be freely used by users, functioning effectively just like [Wrapped ETH](https://weth.io).
The shares can also be redeemed at any time for the corresponding underlying amount of ETH.

## The Hats Challenge

The [`Vault.sol`](./contracts/Vault.sol) is deployed with the contract owning 1 ETH of the shares. 

Your mission is to capture the flag by emptying the vault, then calling `captureTheFlag` with an address you control to prove that you have succeeded in completing the challenge, so that `vault.flagHolder` returns your address.

## How to submit

- Solutions must be submitted through the hats application at https://app.hats.finance/vulnerability
- You must submit a working demonstration of the solution. This could be, for example, a hardhat project in which you fork the project and provide a script that will obtain the flag.
- The contract is deployed on goerli: https://goerli.etherscan.io/address/0x8043e6836416d13095567ac645be7C629715885c#code . However, if you do not want to give away the solution to your competitors, do not execute anything on-chain :)


## Solution 

**Problem:** Incorrect use of address.balance property plus reentrancy attack is open

**Explanation:** 
There we have two problems:
Routine at `ERC4626ETH `contract:

```
    function totalAssets() public view virtual returns (uint256) {
        return address(this).balance;
    }
```
This routine is returning the balance of the contract but it is not the same as `totalSupply()`:

```
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

```
TotalSupply is returning the private field at ERC20 contract. This value is set when mint or burn is executed.

For the previous it is possible that we have different amounts between them.

So when comparing them in `withdraw` function we get some ETH's excess. Those excess are sent to owner and lost from the Vault contract.

Additionally, Vault contract is not managing reentrancy correctly. I looked fine that first review because `_burn() `method is executed before any external call. But the problem here is the` totalAssets()` function again which returns contract balance and not ERC20 private field.

```
function _withdraw(
        address caller,
        address payable receiver,
        address _owner,
        uint256 amount
    ) internal virtual {
        if (caller != _owner) {
            _spendAllowance(_owner, caller, amount);
        }

        uint256 excessETH = totalAssets() - totalSupply();
        
        _burn(_owner, amount);
        
        Address.sendValue(receiver, amount);
        if (excessETH > 0) {
            Address.sendValue(payable(owner()), excessETH);
        }

        emit Withdraw(caller, receiver, _owner, amount, amount);
    }
```

So when calling this rountine in a recursive way, then it is always getting ETH excess and we use this to steal all its balance.

  
**POC Execution:**
I used Foundry because it is better tool for me. So you need to follow the following steps to execute:

Install forge dependencies:
```
forge install
```
Execute the test which executes the hack:
```
forge test
```