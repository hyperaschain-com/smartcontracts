// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HYRA is ERC20, Ownable {

 constructor() ERC20("HYRA", "HYRA"){
    _mint(owner(), 100_000_000_000 * (10**uint256(18))); 
 }

    
}