// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

/// @notice the function take array of numbers and return String with letters that represent the numbers in array

contract fun{
    function haveFun(uint[] calldata numbers) public pure returns(string memory){
        string memory name = "";
        for(uint i=0;i<numbers.length;i++){
            name=string.concat(name,string(abi.encodePacked(uint(64+numbers[i]))));
        }
        return name;
    }
}