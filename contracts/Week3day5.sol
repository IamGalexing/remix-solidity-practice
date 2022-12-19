// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

contract multiSignatureWallet {

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public approvalsNeeded = 2;
    mapping (uint => mapping(address => bool)) public alreadyVotedTX;

    mapping(address => uint) public votesToNewAddress;
    mapping(address => mapping(address => TX_STATUS)) public alreadyVotedNewAddress;


    enum TX_STATUS {PENDING, REJECTED, APPROVED, EXECUTED}

    struct Transaction {
        address sendingTo;
        uint value;
        uint approved;
        uint rejected;
        TX_STATUS status;
    }

    Transaction[] public proposedTransactions;

    constructor(address _addOwner) payable {
        require(_addOwner != msg.sender, "Can't be 2 same owners");
        owners.push(msg.sender);
        owners.push(_addOwner);
        isOwner[msg.sender] = true;
        isOwner[_addOwner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not in the list of owners");
        _;
    }

    function approveNewOwner(address _newOwner) external onlyOwner {
        require(isOwner[_newOwner] == false, "Already owner");
        require(alreadyVotedNewAddress[_newOwner][msg.sender] != TX_STATUS.APPROVED, "You already approved!");

        if (alreadyVotedNewAddress[_newOwner][msg.sender] == TX_STATUS.REJECTED) {
            votesToNewAddress[_newOwner] += 2;
        } else {
            votesToNewAddress[_newOwner] += 1;
        }

        alreadyVotedNewAddress[_newOwner][msg.sender] = TX_STATUS.APPROVED;

        if (votesToNewAddress[_newOwner] >= approvalsNeeded) {
            owners.push(_newOwner);
            isOwner[_newOwner] = true;
            approvalsNeeded = owners.length/2 + 1;
        }
    }

    function rejectNewOwner(address _newOwner) external onlyOwner {
        require(isOwner[_newOwner] == false, "Already owner");
        require(alreadyVotedNewAddress[_newOwner][msg.sender] != TX_STATUS.REJECTED, "You already rejected!");

        if (alreadyVotedNewAddress[_newOwner][msg.sender] == TX_STATUS.APPROVED) {
            votesToNewAddress[_newOwner] -= 2;
        } else {
            votesToNewAddress[_newOwner] -= 1;
        }

        alreadyVotedNewAddress[_newOwner][msg.sender] = TX_STATUS.REJECTED;
    }

    function proposeTX(address _to, uint _amount) external onlyOwner {
        require(_to != address(0) && _to != address(this), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        
        proposedTransactions.push(Transaction({
            sendingTo: _to,
            value: _amount,
            approved: 1,
            rejected: 0,
            status: TX_STATUS.PENDING
        }));

        alreadyVotedTX[proposedTransactions.length-1][msg.sender] = true;
    }

    function approveTransaction(uint _index) external onlyOwner {
        require(alreadyVotedTX[_index][msg.sender] == false, "You already voted!");
        require(proposedTransactions[_index].status == TX_STATUS.PENDING, "Decision already made");

        Transaction memory txMemory = proposedTransactions[_index];

        txMemory.approved += 1;
        alreadyVotedTX[_index][msg.sender] = true;

        if (txMemory.status == TX_STATUS.PENDING && txMemory.approved >= approvalsNeeded) {
            txMemory.status = TX_STATUS.APPROVED;
        }

        proposedTransactions[_index] = txMemory;
    }

    function rejectTransaction(uint _index) external onlyOwner {
        require(alreadyVotedTX[_index][msg.sender] == false, "You already voted!");
        require(proposedTransactions[_index].status == TX_STATUS.PENDING, "Decision already made");

        Transaction memory txMemory = proposedTransactions[_index];

        txMemory.rejected += 1;
        alreadyVotedTX[_index][msg.sender] = true;

        if (txMemory.status == TX_STATUS.PENDING && 
        (txMemory.rejected > (owners.length - approvalsNeeded))) {
            txMemory.status = TX_STATUS.REJECTED;
        }

        proposedTransactions[_index] = txMemory;
    }

    function executeTX(uint _index) external onlyOwner {
        require(proposedTransactions[_index].status == TX_STATUS.EXECUTED, "Already executed!");
        require(proposedTransactions[_index].status == TX_STATUS.APPROVED, "Not detected that the TX approved");

        Transaction memory txMemory = proposedTransactions[_index];

        address payable sendingTo = payable(txMemory.sendingTo);
        (bool isSent,) = sendingTo.call{value: txMemory.value}("");
        require(isSent, "You don't have enough ETH to send");

        proposedTransactions[_index].status = TX_STATUS.EXECUTED;
    }

    function getBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    receive() external payable{}
    fallback() external payable{}
}