// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

contract multiSignatureWallet {

    address public admin;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public approvalsNeeded = 2;
    mapping (uint => mapping(address => bool)) public alreadyVoted;

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
        require(_addOwner != msg.sender, "The wallet needs 2 owners at least");
        admin = msg.sender;
        owners.push(msg.sender);
        owners.push(_addOwner);
        isOwner[msg.sender] = true;
        isOwner[_addOwner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not in the list of owners");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You have no permission");
        _;
    }

    function changeAdmin(address _to) external onlyAdmin {
        require(_to != address(0), "Unpropriate address of new admin");
        require(_to != address(this), "The wallet`s address cannot be the admin");
        require(_to != admin, "You are already admin");
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
        approvalsNeeded = owners.length/2 + 1;
    }

    function proposeTX(address _to, uint _amount) external onlyOwner {
        require(_to != address(0) && _to != address(this), "Invalid recipient");
        require(_amount > 0, "Invalid amount");
        
        proposedTransactions.push(Transaction({
            sendingTo: _to,
            value: _amount,
            approved: 0,
            rejected: 0,
            status: TX_STATUS.PENDING
        }));
    }

    function approveTransaction(uint _index) external onlyOwner {
        require(alreadyVoted[_index][msg.sender] == false, "You already voted!");

        Transaction memory txMemory = proposedTransactions[_index];

        txMemory.approved += 1;
        alreadyVoted[_index][msg.sender] = true;

        if (txMemory.status == TX_STATUS.PENDING && txMemory.approved >= approvalsNeeded) {
            txMemory.status = TX_STATUS.APPROVED;
        }

        proposedTransactions[_index] = txMemory;
    }

    function rejectTransaction(uint _index) external onlyOwner {
        require(alreadyVoted[_index][msg.sender] == false, "You already voted!");

        Transaction memory txMemory = proposedTransactions[_index];

        txMemory.rejected += 1;
        alreadyVoted[_index][msg.sender] = true;

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