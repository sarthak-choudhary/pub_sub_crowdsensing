pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/KeeperCompatible.sol";

interface BrokerInterface {
    function getUserContract() external view returns(address);
    function getTopicId(address _topic_address) external view returns(uint256) ;
}

interface UserInterface {
    function isUser(address user_address) external view returns (bool);
    function getUserDetails(address _user_address) external view returns(uint256, uint256, uint256);
}

contract TopicDetail is KeeperCompatible {
    enum TOPIC_STATUS {
        NEW,
        ACTIVE,
        VALIDATED,
        CLOSED
    }

    address public broker_address;

    string public name;
    TOPIC_STATUS public status;
    uint256 public deposit;
    uint256 public deadline;
    uint256 public periods;
    uint256 public frequency;
    uint256 public zone;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public similarityMatching;
    uint256 public numPublishers;
    uint256 public limit;

    uint256 public publisherCount;
    uint256 public subscriberCount;
    uint256 public reservationCount;

    struct Publisher {
        uint256 publisher_id;
        address user_address;
        uint256 reliability;
        uint256 quality;
        string data;
        string key;
    }

    struct Subscriber {
        uint256 subscriber_id;
        address user_address;
    }

    struct Reservation {
        uint256 reservation_id;
        uint256 reliability;
        address user_address;
    }

    Publisher[] public publishers;
    Subscriber[] public subscribers;
    Reservation[] public reservations;

    mapping(address => uint256) ReservationToId;
    mapping(address => uint256) PublisherToId;

    constructor (address _broker_address, string memory _name, uint256 _deposit, uint256 _deadline, uint256 _periods, uint256 _frequency, uint256 _zone, uint256 _startDate, uint256 _endDate, uint256 _similarityMatching, uint256 _numPublishers, uint256 _limit) public {
        broker_address = _broker_address;
        name = _name;
        status = TOPIC_STATUS.NEW;
        deposit = _deposit;
        deadline = _deadline;
        periods = _periods;
        frequency = _frequency;
        zone = _zone;
        startDate = _startDate;
        endDate = _endDate;
        similarityMatching = _similarityMatching;
        numPublishers = _numPublishers;
        limit = _limit;

        publisherCount = 0;
        subscriberCount = 0;
    }

    function getInfo() public view returns(string memory, uint256, uint256, TOPIC_STATUS, uint256, uint256, address) {
        return (name, deposit, deadline, status, periods, frequency, broker_address);
    }

    function getDetails() public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return (zone, startDate, endDate, similarityMatching, numPublishers, limit);
    }

    function subscribe() public payable returns(bool) {
        BrokerInterface broker = BrokerInterface(broker_address);
        UserInterface userManager = UserInterface(broker.getUserContract());
        uint256 numDays = (endDate - startDate)/(60 * 60 * 24);
        uint256 EstCost = periods * frequency * numPublishers * numDays * deposit;

        require(msg.value >= EstCost, "Not Enough ETH");

        if (userManager.isUser(msg.sender) == false) {
            return false;
        }

        if (broker.getTopicId(address(this)) == 0) {
            return false;
        }

        subscriberCount++;
        subscribers.push(Subscriber({
                                        subscriber_id: subscriberCount,
                                        user_address: msg.sender
                                    }));

        return true;
    }

    function getReservationFee() public view returns (uint256) {
        return periods * frequency * deposit;
    }

    function addReservation(uint256 _startDate, uint256 _endDate) public payable returns(bool) {
        BrokerInterface broker = BrokerInterface(broker_address);
        UserInterface userManager = UserInterface(broker.getUserContract());
        uint256 numDays = (_endDate - _startDate)/(60 * 60 * 24);

        require(msg.value >= (periods * frequency * deposit), "Not Enough ETH");

        if (userManager.isUser(msg.sender) == false || broker.getTopicId(address(this)) == 0 || status != TOPIC_STATUS.NEW || ReservationToId[msg.sender] != 0) {
            return false;
        }


        reservationCount++;
        uint256 total_participation;
        uint256 uncomplete_participation;
        uint256 reputation;

        (total_participation, uncomplete_participation, reputation) = userManager.getUserDetails(msg.sender);
        
        reservations.push(Reservation({
            reservation_id: reservationCount,
            reliability: numDays + reputation + total_participation - uncomplete_participation,
            user_address: msg.sender
        }));

        ReservationToId[msg.sender] = reservationCount;
        return true;
    }

    function addPublishers() public returns (bool) {
        for (uint256 i = 0; i < reservations.length; i++) {
            publisherCount++;
            publishers.push(Publisher({publisher_id: publisherCount, user_address: reservations[i].user_address, reliability: reservations[i].reliability, quality: 0, data: "", key: ""}));
            PublisherToId[reservations[i].user_address] = publisherCount;
        }

        reservationCount = 0;
        status = TOPIC_STATUS.ACTIVE;
        return true;
    }

    function getSubscriptionFee() public view returns(uint256) {
        uint256 numDays = (endDate - startDate)/(60 * 60 * 24);
        uint256 EstCost = periods * frequency * numPublishers * numDays * deposit;
        return EstCost;
    }

    function checkUpkeep(bytes calldata) external override returns (bool upkeepNeeded, bytes memory) {
        if (block.timestamp + 300 >= startDate && status == TOPIC_STATUS.NEW) {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata) external override {
        addPublishers();
    }

    function submitData(string memory data) public returns (bool) {
        if (PublisherToId[msg.sender] == 0 && status != TOPIC_STATUS.ACTIVE) {
            return false;
        }

        uint256 index = PublisherToId[msg.sender] - 1;
        publishers[index].data = data;
        return true;
    }

    function submitKey(string memory key) public returns (bool) {
        if (PublisherToId[msg.sender] == 0 && status != TOPIC_STATUS.VALIDATED) {
            return false;
        }

        uint256 index = PublisherToId[msg.sender] - 1;
        publishers[index].key = key;
        return true;
    }
 
}