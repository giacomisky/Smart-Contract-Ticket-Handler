// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable{
    address public owner;
    mapping(address => bool) private managers;
    
    constructor(){
        owner = msg.sender;
    }
    
    
    function getOwner() internal view returns(address){
        return owner;
    }
    
    
    function addManager(address beneficiary) internal returns(bool){
        managers[beneficiary] = true;
        return true;
    }
    
    
    modifier onlyManager(){
        require(managers[msg.sender] == true);
        _;
    }
    
    
    modifier onlyOwner(){
        require(msg.sender == owner, "msg.sender should be owner");
        _;
    }
    
    
    modifier noOwner(){
        require(msg.sender != owner, "msg.sender should not be owner");
        _;
    }
}
