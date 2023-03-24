// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./Ownable.sol";

contract SharedWallet is Ownable {
    mapping(address => SMember) public members;

    struct SMember {
        string name;
        uint limit;
        bool isAdmin;
    }

    modifier ownerOrWithinLimits(uint _amount) {
        require(
            isOwner() ||
                members[msg.sender].isAdmin ||
                members[msg.sender].limit >= _amount,
            "You are not allowed to perform this operation!"
        );
        _;
    }

    modifier isAlreadyAdmin(address _checkToAdmin) {
        require(!members[_checkToAdmin].isAdmin, "User already admin!");
        _;
    }

    function makeAdmin(
        address _toMakeAdmin
    ) external onlyOwner isAlreadyAdmin(_toMakeAdmin) {
        members[_toMakeAdmin].isAdmin = true;
    }

    function revokeAdmin(address _toRevokeAdmin) external onlyOwner {
        require(members[_toRevokeAdmin].isAdmin, "User not admin!");
        members[_toRevokeAdmin].isAdmin = false;
    }

    function addLimit(
        address _member,
        uint _limit
    ) public onlyOwner isAlreadyAdmin(_member) {
        members[_member].limit = _limit;
    }

    function isOwner() internal view returns (bool) {
        return owner() == msg.sender;
    }

    function deduceFromLimit(
        address _member,
        uint _amount
    ) internal onlyOwner isAlreadyAdmin(_member) {
        members[_member].limit -= _amount;
    }
}

contract Wallet is SharedWallet {
    event LimitChanged(address user, uint oldLimit, uint newLimit);

    function sendToContract(address _to) public payable {
        address payable to = payable(_to);
        to.transfer(msg.value);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function removeMember(address _toRemove) external onlyOwner {
        delete members[_toRemove];
    }

    function withdrawMoney(uint _amount) public ownerOrWithinLimits(_amount) {
        require(
            _amount <= address(this).balance,
            "Not enough funds to withdraw!"
        );

        if (!isOwner() && !members[msg.sender].isAdmin) {
            uint _oldLimit = members[msg.sender].limit;
            members[msg.sender].limit -= _amount;
            emit LimitChanged(msg.sender, _oldLimit, (_oldLimit - _amount));
        }
        address payable _to = payable(msg.sender);
        _to.transfer(_amount);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Can't renounce!");
    }

    fallback() external payable {}

    receive() external payable {}
}
