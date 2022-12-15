// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @notice equally distributed airdrop across recipients on the list

contract Airdrop {

    mapping(address => uint) public balance;

    address[] public airdropRecipients;
    mapping(address => bool) public isOnList;

//  constructor() payable {
//      require(msg.value > 0, "Must send some ETH to deploy");

//      balance[msg.sender] = msg.value;
//  }

//     function getBalance() public view returns(uint) {
//       return address(this).balance;
//     }

//     function balanceByAddress(address _address) public view returns(uint) {
//         return balance[_address];
//     }

//     receive() external payable {
//         balance[msg.sender] += msg.value;
//     }

//     function transferETH(address _receiver, uint _amount) public {
//         require(balance[msg.sender] >= _amount, "You have not enough ETH to make the transaction");
//         balance[msg.sender] -= _amount;
//         payable(_receiver).transfer(_amount);
//     }

//     function sendETH(address _receiver, uint _amount) public {
//         require(balance[msg.sender] >= _amount, "You have not enough ETH to make the transaction");
//         balance[msg.sender] -= _amount;
//         bool isSuccess = payable(_receiver).send(_amount);
//         require(isSuccess, "Transaction failed");
//     }

//     function callETH(address _receiver, uint _amount) public returns(bool) {
//         require(balance[msg.sender] >= _amount, "You have not enough ETH to make the transaction");
//         balance[msg.sender] -= _amount;
//         (bool isSuccess,) = payable(_receiver).call{value: _amount}("");
//         require(isSuccess, "Transaction failed");
//         return isSuccess;
//     }

    function joinList() public {
        require(!isOnList[msg.sender], "You already on the List");
        airdropRecipients.push(msg.sender);
        isOnList[msg.sender] = true;
    }

    function airdrop() public payable {
        if (isOnList[msg.sender]) {
            require(msg.value >= airdropRecipients.length-1, "Not enough ETH for airdrop");
            uint weiToAirdrop = msg.value/(airdropRecipients.length-1);
            for (uint i=0; i<airdropRecipients.length; i++) {
                if (airdropRecipients[i] != msg.sender) {
                    payable(airdropRecipients[i]).call{value: weiToAirdrop}("");
                  }
            }
        } else {
             require(msg.value >= airdropRecipients.length, "Not enough ETH for airdrop");
            uint weiToAirdrop = msg.value/airdropRecipients.length;
            for (uint i=0; i<airdropRecipients.length; i++) {
                payable(airdropRecipients[i]).call{value: weiToAirdrop}("");
            }
        }
    }
}