pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

enum TOPIC_STATUS {
    NEW,
    ACTIVE,
    VALIDATED,
    CLOSED
}

interface UserInterface {
    function isUser(address user_address) external view returns (bool);
    function updateReputation(address _user_address, uint256 _updateTask) external returns(bool);
}

interface TopicDetailInterface {
    function getInfo() external view returns (string memory, uint256, uint256, TOPIC_STATUS, uint256, uint256, address);
    function getDetails() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

contract Broker {
    struct TopicData {
        uint256 topic_id;
        address payable TDC_address;
        string name;
        uint256 deposit;
        uint256 deadline;
        TOPIC_STATUS status;
        uint256 periods;
        uint256 frequency;
        uint256 zone;
        uint256 startDate;
        uint256 endDate;
        uint256 similarityMatching;
        uint256 numPublishers;
        uint256 limit;
    }

    struct TopicDetails {
        string name;
        uint256 deposit;
        uint256 deadline;
        TOPIC_STATUS status;
        uint256 periods;
        uint256 frequency;
        address broker_address;
        uint256 zone;
        uint256 startDate;
        uint256 endDate;
        uint256 similarityMatching;
        uint256 numPublishers;
        uint256 limit;
    }

    TopicData[] public topicsList;
    mapping(address => uint256) public TopicToId;

    uint256 public topicCounter;
    address public userManagerAddress;

    constructor (address _userManagerAddress) public {
        userManagerAddress = _userManagerAddress;
        topicCounter = 0;
    }

    function create_topic(address topic_address) public returns (bool) {
        TopicDetails memory details;

        (   
            details.name,
            details.deposit,
            details.deadline,
            details.status,
            details.periods,
            details.frequency,
            details.broker_address
        ) = TopicDetailInterface(topic_address).getInfo();

        if (details.broker_address != address(this)) {
            return false;
        }

        (
            details.zone,
            details.startDate,
            details.endDate,
            details.similarityMatching,
            details.numPublishers,
            details.limit         
        ) = TopicDetailInterface(topic_address).getDetails();

        if (UserInterface(userManagerAddress).isUser(msg.sender) == false) {
            return false;
        }

        for (uint256 i = 0; i < topicsList.length; i++) {
            if (keccak256(abi.encodePacked((topicsList[i].name))) == keccak256(abi.encodePacked((details.name))) && 
                topicsList[i].deposit == details.deposit && 
                topicsList[i].deadline == details.deadline &&
                topicsList[i].status == details.status &&
                topicsList[i].periods == details.periods &&
                topicsList[i].frequency == details.frequency &&
                topicsList[i].zone == details.zone &&
                topicsList[i].startDate == details.startDate &&
                topicsList[i].endDate == details.endDate &&
                topicsList[i].similarityMatching == details.similarityMatching &&
                topicsList[i].numPublishers == details.numPublishers &&
                topicsList[i].limit == details.limit
                ) {
                return false;    
            }
        }

        topicCounter++;
        topicsList.push(TopicData({
                            topic_id: topicCounter, 
                            TDC_address: payable(topic_address), 
                            name: details.name, 
                            deposit: details.deposit, 
                            deadline: details.deadline,
                            status: details.status,
                            periods: details.periods,
                            frequency: details.frequency,
                            zone: details.zone,
                            startDate: details.startDate,
                            endDate: details.endDate,
                            similarityMatching: details.similarityMatching,
                            numPublishers: details.numPublishers,
                            limit: details.limit
                        }));

        TopicToId[topic_address] = topicCounter;
        return true;       
    }
    
    function get_topics(string memory _name, uint256 _deposit, uint256 _deadline, uint256 len) public view returns (TopicData[] memory) {
        TopicData[] memory desired_topics = new TopicData[](len);

        uint256 counter = 0;
        uint256 index = 0;

        while (index < topicsList.length && counter < len) {
            if (keccak256(abi.encodePacked((topicsList[index].name))) == keccak256(abi.encodePacked((_name))) && topicsList[index].deposit == _deposit && topicsList[index].deadline == _deadline) {
                desired_topics[counter] = topicsList[index];
                counter++;   
            }

            index++;           
        }
        
        return desired_topics;
    }

    function getUserContract() public view returns(address) {
        return userManagerAddress;
    }

    function getTopicId(address _topic_address) public view returns(uint256) {
        return TopicToId[_topic_address];
    }

    function updateRepo(address _user_address, uint256 _update) external returns(bool) {
        // require(TopicToId[msg.sender] != 0, "Topic Not Registered");

        UserInterface userManager = UserInterface(userManagerAddress);
        return userManager.updateReputation(_user_address, _update);
    }
}