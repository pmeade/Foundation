 pragma solidity ^0.4.0;
 
 contract Foundation {

    uint constant ConversionRate = 10000;
    mapping (address => uint256) deposits;
    mapping (address => uint) balances;

     function Deposit() payable public {
         // Store the Ether
         deposits[msg.sender] += msg.value;
         
         // Create new foundation coins backed by ether
         balances[msg.sender] += msg.value * ConversionRate;
     }
     
     function Withdraw(uint256 amount) public returns (bool success) {
         // Make sure they have enough ether 
         if (deposits[msg.sender] < amount){
             return false;
         }
         
         // Make sure they have enough foundation coins
         if (balances[msg.sender] < amount * ConversionRate){
             return false;
         }
         
         // Burn the foundation coins and return the ether
         BurnCoins(amount * ConversionRate);
         msg.sender.transfer(amount);
         
         return true;
     }
     
     function BurnCoins(uint amount) public returns (bool burned) {
         // Make sure they have enough coins
         if (balances[msg.sender] >= amount){
             balances[msg.sender] -= amount;
             return true;
         }
         
         return false;
     }
     
 }