// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

/// @notice get enough points to win ETH provided to conntract during deployment

contract token is ERC20("Win a price by collect points!", "POINT") {
    mapping(address => uint) public points;
    address public immutable owner;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You have no permission.");
        _;
    }

    function mintNewToken(uint _amount) external onlyOwner {
       _mint(msg.sender, _amount*(10**18));
    }

    function BurnAndAdd(uint _amount) external {
        _burn(msg.sender, _amount);
        points[msg.sender] += _amount;
    }

    function burned(address _addy) external view returns(uint) {
       return points[_addy];
    }

    function win() external {
        if (points[msg.sender] >= 5) {
            selfdestruct(payable(msg.sender));
        } else {
            revert("You have not enough points!");
        }
    }
}