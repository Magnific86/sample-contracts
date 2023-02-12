// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract ENS_DOMAIN {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct DomainDetails {
        address sender;
        uint timeCreate;
        uint gasprice;
        uint subTime;
    }

    mapping(string => DomainDetails) public domains;
    uint public constant YEAR_IN_SECONDS = 31536000;
    uint public subForYear = 1000;
    uint public subCoefficient = 2;

    modifier onlyOwner() {
        require(msg.sender == owner, "This is not yours");
        _;
    }

    modifier checkDomainPossessionForProlong(string memory _domainName) {
        address _spareAddr = domains[_domainName].sender;
        require(_spareAddr == msg.sender, "This is not yours");
        _;
    }

    modifier checkIsAvalableToProlong(string memory _domainName) {
        require(notExpired(_domainName), "Domain possession is expired"); //тоесть если истекло нужно заново купить, продлить не получится
        _;
    }

    modifier checkProlongPrice(uint _amount, uint _years) {
        require(
            _amount == (subForYear * subCoefficient) * _years,
            "You need pay more... or less..."
        );
        _;
    }

    modifier checkBuyPrice(uint _amount, uint _years) {
        require(
            _amount == subForYear * _years,
            "You need pay more... or less..."
        );
        _;
    }

    modifier checkTime(uint _years) {
        require(_years >= 1 && _years <= 10, "Invalid sub time...");
        _;
    }

    function notExpired(
        string memory _domainName
    ) internal view returns (bool) {
        return
            (domains[_domainName].timeCreate + domains[_domainName].subTime) >
            uint(block.timestamp);
    }

    function calculateBuyPrice(uint _years) public view returns (uint) {
        return _years * subForYear;
    }

    function calculateProlongPrice(uint _years) public view returns (uint) {
        return (subForYear * subCoefficient) * _years;
    }

    function setSubPrice(uint _newSubPrice) public onlyOwner {
        subForYear = _newSubPrice;
    }

    function setSubCoefficient(uint _newSubCoefficient) public onlyOwner {
        subCoefficient = _newSubCoefficient;
    }

    function createDomain(
        uint _years,
        address _sender,
        uint _gasprice
    ) internal view returns (DomainDetails memory) {
        DomainDetails memory newInfo = DomainDetails({
            sender: _sender,
            timeCreate: block.timestamp,
            gasprice: uint(tx.gasprice) + uint(_gasprice),
            subTime: _years * YEAR_IN_SECONDS //перевожу год в секунды
        });
        return newInfo;
    }

    function buyDomain(
        string calldata _domainName,
        uint _years
    ) public payable checkTime(_years) checkBuyPrice(msg.value, _years) {
        address _spareAddr = domains[_domainName].sender;

        if (_spareAddr != address(0)) {
            require(notExpired(_domainName), "Domain is busy..."); // иначе срок владения предыдущего истек и можно перезаписать
        }

        domains[_domainName] = createDomain(
            _years,
            msg.sender,
            uint(tx.gasprice)
        );
    }

    function subProlong(
        string memory _domainName,
        uint _prolongYears
    )
        public
        payable
        checkDomainPossessionForProlong(_domainName)
        checkProlongPrice(msg.value, _prolongYears)
        checkIsAvalableToProlong(_domainName)
    {
        domains[_domainName].subTime += _prolongYears * YEAR_IN_SECONDS; //здесь тоже перевожу в сек
    }

    function scanDomain(
        string memory _domainName
    ) public view returns (address) {
        return domains[_domainName].sender;
    }

    function withdraw(uint _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
