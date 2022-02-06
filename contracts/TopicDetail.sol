pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/KeeperCompatible.sol";

interface BrokerInterface {
    function getUserContract() external view returns(address);
    function getTopicId(address _topic_address) external view returns(uint256);
    function updateRepo(address _user_address, uint256 _update) external returns(bool);
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
    mapping(address => address payable) _nextPublisher;
    uint256 public listSize;
    address payable constant GUARD = address(1);

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
        address payable user_address;
        uint256 reliability;
        uint256 quality;
        int[] data;
        string key;
    }

    struct Subscriber {
        uint256 subscriber_id;
        address payable user_address;
    }

    struct Reservation {
        uint256 reservation_id;
        uint256 reliability;
        address payable user_address;
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

        _nextPublisher[GUARD] = GUARD;
    }

    function appendPublisher(address payable _publisher, uint256 score) private {
        require(_nextPublisher[_publisher] == address(0));
        address index = _findIndex(score);

        _nextPublisher[_publisher] = _nextPublisher[index];
        _nextPublisher[index] = _publisher;
        listSize++;
    }

    function _verifyIndex(address prevPublisher, uint256 newValue, address nextPublisher) internal view returns (bool) {
        return (prevPublisher == GUARD || reservations[ReservationToId[prevPublisher] - 1].reliability >= newValue) &&
               (nextPublisher == GUARD || newValue > reservations[ReservationToId[nextPublisher] - 1].reliability);
    }

    function _findIndex(uint256 newValue) internal view returns(address) {
        address candidateAddress = GUARD;

        while (true) {
            if (_verifyIndex(candidateAddress, newValue, _nextPublisher[candidateAddress]))
                return candidateAddress;
            candidateAddress = _nextPublisher[candidateAddress];
        }
    }

    function getTop(uint256 k) public view returns(address payable [] memory) {
        if (k > listSize) {
            k = listSize;
        }

        address payable [] memory publisherList = new address payable [](k);
        address payable currentAddress = payable(_nextPublisher[GUARD]);

        for(uint256 i = 0; i < k; ++i) {
            publisherList[i] = currentAddress;
            currentAddress = payable (_nextPublisher[currentAddress]);
        }

        return publisherList;
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
        uint256 numDays = (_endDate - _startDate) * (60 * 60 * 24)/(60 * 60 * 24);

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

        appendPublisher(msg.sender, numDays + reputation + total_participation - uncomplete_participation);
        ReservationToId[msg.sender] = reservationCount;
        return true;
    }

    function addPublishers() public returns (bool) {
        if (numPublishers > reservationCount) {
            numPublishers = reservationCount;
        }

        address payable [] memory publisherAddress = getTop(numPublishers);

        for (uint256 i = 0; i < publisherAddress.length; i++) {
            publisherCount++;
            publishers.push(Publisher({publisher_id: publisherCount, user_address: publisherAddress[i], reliability: reservations[ReservationToId[publisherAddress[i]] - 1].reliability, data: new int[](0), quality: 0, key: ""}));
            PublisherToId[publisherAddress[i]] = publisherCount;
        }

        uint256 reservationFee = getReservationFee();

        for (uint256 i = 0; i < reservations.length; i++) {
            if(PublisherToId[reservations[i].user_address] == 0) {
                reservations[i].user_address.transfer(reservationFee);
            }
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

    function submitData(int[] memory _data) public returns (bool) {
        if (PublisherToId[msg.sender] == 0 && status != TOPIC_STATUS.ACTIVE) {
            return false;
        }

        uint256 index = PublisherToId[msg.sender] - 1;
        // publishers[index].data = data;

        for (uint256 i = 0; i < _data.length; i++) {
            publishers[index].data.push(_data[i]);
        }

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


    function getReservation(uint256 id) public view returns (address, uint256) {
        return (reservations[id - 1].user_address, reservations[id - 1].reliability);
    }


    function getPublisher(uint256 id) public view returns (address, uint256, uint256, uint256) {
        return (publishers[id - 1].user_address, publishers[id - 1].reliability, publishers[id - 1].user_address.balance, publishers[id - 1].quality);
    }

    function calculateDifference(int[] memory data1, int[] memory data2) private pure returns (uint256) {
        if (data1.length == 0 || data2.length == 0 || data1.length != data2.length) {
            return 0;
        }

        int diff = 0;

        for (uint256 i = 0; i < data1.length; i++) {
            diff += (data1[i] - data2[i]) ** 2;
        }

        return uint256(diff);
    } 

    function validateData() public returns (bool) {
        for (uint256 i = 0; i < publishers.length; i++) {
            for (uint256 j = i + 1; j < publishers.length; j++) {
                uint256 diff = calculateDifference(publishers[i].data, publishers[j].data);
                if (diff <= similarityMatching) {
                    publishers[i].quality++;
                    publishers[j].quality++;
                }
            }
        }

        feedback();
        status = TOPIC_STATUS.VALIDATED;
        return true;
    }

    function feedback() private returns(bool) {
        uint256 numMatching = (publisherCount/2) + 1;
        uint256 reward = address(this).balance/publisherCount;
        uint256 validPublishers = 0;

        for (uint256 i = 0; i < publishers.length; i++) {
            if (publishers[i].quality < numMatching) {
                updateReputation(publishers[i].user_address, 1);
            } else {
                publishers[i].user_address.transfer(reward);
                updateReputation(publishers[i].user_address, 0);
                validPublishers++;
            }
        }
        
        if (address(this).balance/subscriberCount != 0) {
            uint256 refund = address(this).balance/subscriberCount;
            for (uint256 i = 0; i < subscribers.length; i++) {
                subscribers[i].user_address.transfer(refund);
            }
        }

        return true;
    }


    function updateReputation(address _user_address, uint256 _update) private {
        BrokerInterface broker = BrokerInterface(broker_address);
        broker.updateRepo(_user_address, _update);
    }
}