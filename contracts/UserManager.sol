pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol"; 

contract UserManager is Ownable {
    
    struct User {
        uint256 user_id;
        address payable user_address;
        uint256 total_participation;
        uint256 uncomplete_participation;
        uint256 reputation;      
    }

    User[] public users;
    mapping(address => uint256) public UserToId;
    uint256 public userCounter;
    uint256 public default_reputation;

    address public broker_address;
    uint256 public broker_set;

    constructor(uint256 _default_reputation, address _broker_address) public {
        broker_set = 0;
        userCounter = 0;
        default_reputation = _default_reputation;
        broker_address = _broker_address;
    }

    function isBroker() public view returns(bool) {
        return msg.sender == broker_address;
    }

    modifier onlyBroker() {
        require(isBroker());
        _;
    }

    function register() public returns (bool) {
        if (UserToId[msg.sender] > 0) {
            return false;
        }

        userCounter++;
        users.push(User({user_id: userCounter, user_address: msg.sender, total_participation: 0, uncomplete_participation: 0, reputation: default_reputation}));
        UserToId[msg.sender] = userCounter;

        return true;
    }

    function isUser(address _user_address) public view returns(bool) {
        if (UserToId[_user_address] > 0) {
            return true;
        }

        return false;
    }

    function set_broker(address _broker_address) public onlyOwner {
        require(broker_set == 0);
        
        broker_address = _broker_address;
        broker_set = 1;
    }

    function getReputation(address _user_address) public view returns(uint256) {
        return users[UserToId[_user_address] - 1].reputation;
    }

    function getUserDetails(address _user_address) public view returns(uint256, uint256, uint256) {
        uint256 user_index = UserToId[_user_address] - 1;
        return (users[user_index].total_participation, users[user_index].uncomplete_participation, users[user_index].reputation);
    }

    function getUserInfo(uint256 _id) public view returns(address, uint256, uint256, uint256, uint256) {
        require(_id <= userCounter && _id > 0);
        return (users[_id - 1].user_address, users[_id - 1].user_address.balance, users[_id - 1].uncomplete_participation, users[_id - 1].total_participation, users[_id - 1].reputation);
    }

    function updateReputation(address _user_address, uint256 _updateTask) external returns(bool) {
        // require(msg.sender == broker_address);

        users[UserToId[_user_address] - 1].uncomplete_participation += _updateTask;
        users[UserToId[_user_address] - 1].total_participation++;

        uint256 uncomplete = users[UserToId[_user_address] - 1].uncomplete_participation;
        uint256 total = users[UserToId[_user_address] - 1].total_participation;

        if (uncomplete == 0) {
            users[UserToId[_user_address] - 1].reputation = 1;
        } else {
            users[UserToId[_user_address] - 1].reputation = 100 - (uncomplete * 100)/total;
        }

        return true;
    }
}