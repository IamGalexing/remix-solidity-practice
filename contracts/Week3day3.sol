// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

/// @notice simple contact to airdrop for multiple accounts at once 

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract Airdrop is ERC20("Token Airdrop", "AIR") {
    address public immutable owner;
    address[] public whitelist;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function AddToWhitelist(address _toWhitelist) external onlyOwner {
        whitelist.push(_toWhitelist);
    }

    function mintTokens(uint _amount) external onlyOwner {
        for (uint i=0; i<whitelist.length; i++) {
             _mint(whitelist[i], _amount*(10**18));
        }
    }
}
