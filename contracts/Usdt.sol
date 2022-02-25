// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Usdt is ERC20, Ownable {

 constructor() ERC20("USDT", "USDT"){
    _mint(owner(), 1_000_000 * (10**uint256(18))); 
 }

    
}