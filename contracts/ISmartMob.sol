// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Transport{
    event OrderCreated(
        uint256 indexed codTicket
    );
    
    event TicketAdded(
        uint256 price, 
        string indexed tipology, 
        string start, 
        string finish, 
        uint256 startTime, 
        uint256 endTime
    );
    
    event CustomerAdded(
        string indexed name, 
        string indexed surname
    );

    
    event CustomerRewarded(
        address payable customer, 
        uint256 amountOfDelay
    );
    
    function addCustomer(
        string memory name, 
        string memory surname
    ) 
        external 
        returns(bool);
       
        
    function addTicket(
        uint256 price, 
        string memory tipology, 
        string memory start, 
        string memory finish, 
        uint256 startTime, 
        uint256 endTime
    ) 
        external 
        returns(bool);
     
        
    function createOrder(
        uint256 codTicket
    ) 
        external 
        payable 
        returns(bool);
    
    
    function deleteOrder(
        address customer, 
        uint256 codTicket
    ) 
        external 
        returns(bool);
    
    
    function teminateOrder(
        uint256 codTicket
    ) 
        external 
        returns(bool);
    
    
    function getCustomer(
        address owner
    ) 
        external 
        view 
        returns(
            uint256, 
            string memory, 
            string memory
        );
    
    
    function getTicket(
        uint256 serial
    ) 
        external 
        view 
        returns(
            uint256, 
            string memory, 
            string memory, 
            string memory, 
            uint256, 
            uint256
        );
}