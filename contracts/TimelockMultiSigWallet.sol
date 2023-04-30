// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimelockMultiSigWallet {
    uint constant MINIMUM_DELAY = 10;
    uint constant MAXIMUM_DELAY = 1 day;
    uint constant GRACE_PERIOD = 1 day;
    address public owner;
    string public message;
    uint public amount;

    mapping (bytes32 => bool) public queue;


    struct Transaction {
        address to;
        uint value;
        bytes data;

    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function add(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint _value,
        uint _timestamp
    ) external onlyOwner return (bytes32) {
        
        require(_timestamp > block.timestamp MINIMUM_DELAY && _timestamp < block.timestamp MAXIMUM_DELAY, "incorreact timestamp!");

        bytes32 txId = calculateBytes( _to, _func, _data, _value, _timestamp);
        require(!queue[txId], "already at queue!");
        queue[txId] = true;
        return txId;
    }

    function discard(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "txId not at queued!");
        delete queue[_txId];
    }

    function execute(
         address _to,
        string calldata _func,
        bytes calldata _data,
        uint _value,
        uint _timestamp
    ) external onlyOwner return (bytes memory) {
        require(block.timestamp > _timestamp, "too early!");
        require(_timestamp + GRACE_PERIOD > block.timestamp, "too late!");

        bytes32 txId = calculateBytes( _to,_func, _data,_value,  _timestamp);
        require(queue[_txId], "not queued!");
        delete queue[txId];

        bytes memory data;
        if(bytes(_func).length > 0) {
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))),
                _data
            );
        } else {
            data = _data;
        }

        (bool success, bytes memory resp) = _to.call{value: _value}()
        require(success, "tx failed!");
        return resp;
    }

    function calculateBytes = (
         address _to,
        string calldata _func,
        bytes calldata _data,
        uint _value,
        uint _timestamp
    ) internal returns (bytes32) {
        return keccak256(abi.encode(
            _to,
            _func,
            _data,
            _value,
            _timestamp
        ));
    }
}