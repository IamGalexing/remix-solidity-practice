// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

contract multiSignatureWallet {

    address public admin;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public approvalsNeeded = 2;
    mapping (uint => mapping(address => bool)) public alreadyVoted;

    enum progressTX {inProgress, REJECTED, APPROVED}

    struct Transaction {
        address sendingTo;
        uint value;
        bool alreadyExecuted;
        uint approved;
        uint rejected;
        progressTX status;
    }

    Transaction[] public proposedTransactions;

    constructor(address _addOwner) payable {
        require(_addOwner != msg.sender, "The wallet needs 2 owners at least");
        admin = msg.sender;
        owners.push(msg.sender);
        owners.push(_addOwner);
        isOwner[msg.sender] = true;
        isOwner[_addOwner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not in the list of onwners");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You have no permision");
        _;
    }

    function changeAdmin(address _to) external onlyAdmin {
        admin = _to;
    }

    function addOwner(address _addOwner) external onlyAdmin {
        require(isOwner[_addOwner] == false, "Already owner");

        owners.push(_addOwner);
        isOwner[_addOwner] = true;
        approvalsNeeded = owners.length/2 + 1;
    }

    function removeOwner(uint _index) external onlyAdmin {
        require(_index < owners.length, "Wrong argument");
        isOwner[owners[_index]] = false;
        if (_index != owners.length-1) {
        owners[_index] = owners[owners.length-1];
        }
        owners.pop();
    }

    function proposeTX(address _to, uint _amount) external onlyOwner {
        proposedTransactions.push(Transaction({
            sendingTo: _to,
            value: _amount,
            alreadyExecuted: false,
            approved: 0,
            rejected: 0,
            status: progressTX.inProgress
        }));
    }

    function approveTransaction(uint _index) external onlyOwner {
        require(alreadyVoted[_index][msg.sender] == false, "You already voted!");

        proposedTransactions[_index].approved += 1;
        alreadyVoted[_index][msg.sender] = true;

        if (proposedTransactions[_index].status == progressTX.inProgress && proposedTransactions[_index].approved >= approvalsNeeded) {
            proposedTransactions[_index].status = progressTX.APPROVED;
        }
    }

    function rejectTransaction(uint _index) external onlyOwner {
        require(alreadyVoted[_index][msg.sender] == false, "You already voted!");

        proposedTransactions[_index].rejected += 1;
        alreadyVoted[_index][msg.sender] = true;

        if (proposedTransactions[_index].status == progressTX.inProgress && 
        (proposedTransactions[_index].rejected >= approvalsNeeded || owners.length == 2)) {
            proposedTransactions[_index].status = progressTX.REJECTED;
        }
    }

    function executeTX(uint _index) external onlyOwner {
        require(proposedTransactions[_index].alreadyExecuted == false, "Already executed!");
        require(proposedTransactions[_index].status == progressTX.APPROVED, "Not detected that the TX approved");

        address payable sendingTo = payable(proposedTransactions[_index].sendingTo);
        (bool isSent,) = sendingTo.call{value: proposedTransactions[_index].value}("");
        require(isSent, "You don't have enough ETH to send");

        proposedTransactions[_index].alreadyExecuted = true;
    }

    function getBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    receive() external payable{}
    fallback() external payable{}
}