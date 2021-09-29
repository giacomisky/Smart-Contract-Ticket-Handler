// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ISmartMob.sol";
import "./Ownable.sol";

contract TransportManaged is Ownable, Transport{
    using SafeMath for uint256;
    using Address for address payable;
    
    enum StateOrder { active, deleted, finished }
    
    struct Customer{
        uint256 id;
        string name;
        string surname;
    }
    
    struct Ticket{
        uint256 price;
        string tipology;
        string start;
        string finish;
        uint256 startTime;
        uint256 endTime;
    }
    
    struct Order{
        Ticket ticket;
        Customer customer;
        StateOrder state;
        uint256 terminateTime;
    }
    
    uint256 private custId;
    uint256 private tickId;
    uint256 private ordId;
    
    mapping(address => Customer) private customers;
    address[] private customersAddress;
    mapping(uint256 => Ticket) private tickets;
    mapping(address => uint256) private balancesLocked;
    mapping(address => mapping(uint256 => Order)) private orders;
    
    constructor()
    Ownable()
    {
        custId = 0;
        tickId = 0;
        ordId = 0;
    }
    
    
    /**
     * @dev see { Ownable-addManager } 
     * add a new manager to the mapping of managers
     * 
     * Requirements:
     *  - 'beneficiary' of grant
     */
    function addNewManager(
        address beneficiary
    ) 
        public 
        onlyOwner 
        returns(bool)
    {
        require(beneficiary != getOwner());
        assert(addManager(beneficiary));
        
        return true;
    }
    
    
    /**
     * @dev add a new Customer
     * 
     * Emits a  {CustomerAdded} event
     * 
     * Requirements:
     *  - 'name' of customer.
     *  - 'surname' of customer.
     */ 
    function addCustomer(
        string memory name, 
        string memory surname
    ) 
        public 
        override 
        noOwner 
        returns(bool)
    {
        custId += 1;
        Customer storage newCustomer = customers[msg.sender];
        newCustomer.id = custId;
        newCustomer.name = name;
        newCustomer.surname = surname;
        
        customersAddress.push(msg.sender);
        
        emit CustomerAdded(name, surname);
        return true;
    }
    
    
    /** @dev add a new ticket
     * 
     * Emits a {TicketAdded} event.
     * 
     * Requirements:
     *  -'price' cannot be zero.
     *  -'tipology' of tickect.
     *  -'start' place of departure.
     *  -'finish' destination.
     *  -'startTime' time of departure.
     *  -'endtime' time of arrival.
     */
    function addTicket(
        uint256 price, 
        string memory tipology, 
        string memory start, 
        string memory finish, 
        uint256 startTime, 
        uint256 endTime
    ) 
        public 
        override 
        onlyOwner 
        //onlyManager
        returns(bool)
    {
        require(startTime >= block.timestamp, "startTime should be bigger or equal than current time");
        require(endTime > startTime, "endtime should be bigger than startTime");
        require(price > 0, "Ticket price must should be bigger than 0");
        
        tickId += 1;
        Ticket storage newTicket = tickets[tickId];
        newTicket.price = price;
        newTicket.tipology = tipology;
        newTicket.start = start;
        newTicket.finish = finish;
        newTicket.startTime = startTime;
        newTicket.endTime = endTime;
        
        emit TicketAdded(price, tipology, start, finish, startTime, endTime);
        return true;
    }
    
    
    /** @dev create a new Order
     * 
     * Emits a {OrderCreated} event.
     * 
     * Requirements:
     *  - 'codTicket' unique code of ticket.
     */
    function createOrder(
        uint256 codTicket
    ) 
        public 
        override 
        payable 
        noOwner 
        returns(bool)
    {
        require(msg.value >= tickets[codTicket].price, "the user balance is not enough to perform the transaction");
        uint256 amount = msg.value;
        
        balancesLocked[msg.sender] = balancesLocked[msg.sender].add(amount);
        ordId += 1;
        Order storage newOrder = orders[msg.sender][ordId];
        newOrder.ticket = tickets[codTicket];
        newOrder.customer = customers[msg.sender];
        newOrder.state = StateOrder.active;
       
        
        emit OrderCreated(codTicket);
        return true;
    }
    
    
    /** @dev get a specific order.
     * 
     * Requirements:
     *  -'customer' address of customer.
     *  -'codTicket' unique code of ticket.
     */
    function getOrder(
        address customer, 
        uint256 codTicket
    ) 
        public 
        view 
        returns(
            Ticket memory, 
            Customer memory, 
            StateOrder
        )
    {
        return (orders[customer][codTicket].ticket, orders[customer][codTicket].customer, orders[customer][codTicket].state);
    } 
    
    
    /** @dev get status of a specific order.
     * 
     * Requirements:
     *  -'customer' address of customer.
     *  -'codTicket' unique code of ticket.
     */
    function getStatusOrder(
        address customer, 
        uint256 codTicket
    ) 
        public 
        view 
        returns(StateOrder)
    {
        return orders[customer][codTicket].state;
    }
    
    
    /** @dev returns all orders by customer.
     * 
     * Requirements:
     *  -'customer' address of customer.
     */
    function getOrderByCustomer(
        address customer
    ) 
        public 
        view
        returns(Order[] memory)
    {
        Order[] memory codsOfTickets;
        for(uint256 i=0; i<ordId; i++){
            codsOfTickets[i] = orders[customer][i];
        }
        return codsOfTickets;
    }
    
    
    /** @dev changes state of order to deleted.
     * 
     * Requirements:
     *  -'customer' address of customer.
     *  -'codTicket' unique code of ticket.
     */
    function deleteOrder(
        address customer, 
        uint256 codTicket
    ) 
        public 
        override 
        returns(bool)
    {
        require(orders[customer][codTicket].state != StateOrder.deleted, "this order has already been deleted");
        
        orders[customer][codTicket].state = StateOrder.deleted;
        return true;
    }
    
    
    /** @dev chages state of order to finished.
     * 
     * Requirements:
     *  -'codTicket' unique code of ticket.
     */
    function teminateOrder(
        uint256 codTicket
    ) 
        override
        public 
        returns(bool) 
    {
        for(uint256 i = 0; i<customersAddress.length; i++){
            orders[customersAddress[i]][codTicket].terminateTime = block.timestamp;
            orders[customersAddress[i]][codTicket].state = StateOrder.finished;
        }
        
        return true;
    }
    
    
    /** @dev get a customer's detail
     * 
     * Requirements:
     *  -'customer' address of customer.
     */
    function getCustomer(
        address _customer
    ) 
        public 
        override 
        view 
        returns(
            uint256, 
            string memory, 
            string memory
        )
    {
        return (customers[_customer].id, customers[_customer].name, customers[_customer].surname);
    }
    
    
    /** @dev get details of a ticket.
     * 
     * Requirements:
     *  -'serial' serial code of ticket.
     */
    function getTicket(
        uint256 serial
    ) 
        public 
        override 
        view 
        returns(
            uint256, 
            string memory, 
            string memory, 
            string memory, 
            uint256, 
            uint256
        )
    {
        return (tickets[serial].price, tickets[serial].tipology, tickets[serial].start, tickets[serial].finish, tickets[serial].startTime, tickets[serial].endTime);
    }
    
    
    /** @dev check delay of an order
     * 
     * Requirements:
     *  -'customer' address of customer.
     *  -'codTicket' unique code of ticket.
     */
    function checkTrainDelay(
        address customer,
        uint256 codTicket
    )
        public
        view
        returns(uint256)
    {
        if(orders[customer][codTicket].terminateTime > orders[customer][codTicket].ticket.endTime){
            uint256 amountDelay = orders[customer][codTicket].terminateTime.sub(orders[customer][codTicket].ticket.endTime);
            return amountDelay;
        }else if(orders[customer][codTicket].terminateTime == orders[customer][codTicket].ticket.endTime){
            return 0;
        }else{
            uint256 advance = orders[customer][codTicket].ticket.endTime.sub(orders[customer][codTicket].terminateTime);
            return advance;
        }
    }
    
    
    /** @dev customer can reclaim his funds.
     * 
     * Requirements:
     *  -'customer' address of customer.
     *  -'codTicket' uniuque code of ticket.
     */
    function reclaimFunds(
        address payable customer,
        uint256 codTicket
    )
        public
        noOwner
    {
        require(orders[customer][codTicket].state == StateOrder.finished, "this order must be finished");
        require(orders[customer][codTicket].terminateTime != 0, "this order must have a terminateTime");
        
        if(orders[customer][codTicket].terminateTime > orders[customer][codTicket].ticket.endTime){
            //allora il treno è arrivato in ritardo
            uint256 delay = block.timestamp - orders[customer][codTicket].ticket.endTime;
            
            uint256 ticketPrice = orders[customer][codTicket].ticket.price;
            
            if(delay > 1 minutes && delay <= 10 minutes){
                uint256 valuePercent = ( ticketPrice / 100 ) * 10;
                rewandForDelay(valuePercent, customer);
            }else if(delay > 10 minutes && delay <= 20 minutes){
                //reward 15%
                uint256 valuePercent = ( ticketPrice / 100 ) * 15;
                rewandForDelay(valuePercent, customer);
            }else if(delay > 20 minutes && delay <= 30 minutes){
                //reward 20%
                uint256 valuePercent = ( ticketPrice / 100 ) * 20;
                rewandForDelay(valuePercent, customer);
            }else if(delay > 30 minutes && delay <= 40 minutes){
                //reward 25%
                uint256 valuePercent = ( ticketPrice / 100 ) * 25;
                rewandForDelay(valuePercent, customer);
            }else if(delay > 40 minutes && delay <= 50 minutes){
                //reward 30%
                uint256 valuePercent = ( ticketPrice / 100 ) * 30;
                rewandForDelay(valuePercent, customer);
            }else if(delay > 50 minutes && delay <= 60 minutes){
                //reward 35%
                uint256 valuePercent = ( ticketPrice / 100 ) * 35;
                rewandForDelay(valuePercent, customer);
            }else{
                //reward 40%
                uint256 valuePercent = ( ticketPrice / 100 ) * 40;
                rewandForDelay(valuePercent, customer);
            }
        }
    }
    
    
    /** @dev send a rewand to customer for delay
     * 
     * Emits a {CustomerRewarded} event.
     * 
     * Requirements:
     *  -'amountOfDelay' amount of delay to reward.
     *  -'customer' address of customer to reward.
     */
    function rewandForDelay(
        uint256 amountOfDelay,
        address payable customer
    )
        internal 
    {
        require(balancesLocked[msg.sender] - amountOfDelay >= 0, "There is not enough wei to reward");
        customer.sendValue(amountOfDelay);
        
        emit CustomerRewarded(customer, amountOfDelay);
        
    }

    
}