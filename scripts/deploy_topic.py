from brownie import TopicDetail, Broker, network, config
from scripts.deploy_broker import deploy_broker, get_topics
from scripts.deploy_user_manager import register
from scripts.helpful_scripts import get_account
import time

def deploy_topic(name, deposit, deadline, periods, frequency, zone, startDate, endDate, similarityMatching, numPublishers, limit, _index=None):
    broker = Broker[-1]
    if _index:
        account = get_account(index=_index)
    else:
        account = get_account()
        
    
    topic_detail = TopicDetail.deploy(broker.address, name, deposit, deadline, periods, frequency, zone, startDate, endDate, similarityMatching, numPublishers, limit, {"from": account}, publish_source=config["networks"][network.show_active()].get("verify", False))
    print(f"The topic is deployed at f{topic_detail.address}")
    return topic_detail
    

def subscribe(_index=None):
    topic_detail = TopicDetail[-1]
    if _index:
        account = get_account(index=_index)
    else:
        account = get_account()
    
    value = topic_detail.getSubscriptionFee({"from": account}) + 1000000000000000
    tx = topic_detail.subscribe({"from": account, "value": value})
    tx.wait(1)
    
    # if tx.return_value:
    #     print(f"Account f{account.address} has successfully subscribed to the given Topic")
    # else:
    #     print(f"Subscription request failed")
        
    print(f"Account f{account.address} has successfully subscribed to the given Topic")


def getNumberOfSubscribers():
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    result = topic_detail.subscriberCount({"from": account})
    return result
    
           
def reserve(_startTime, _endTime, _index=None):
    topic_detail = TopicDetail[-1]
    if _index:
        account = get_account(index=_index)
    else:
        account = get_account()
        
    value = topic_detail.getReservationFee({"from": account}) + 1000000000000000
    tx = topic_detail.addReservation(_startTime, _endTime, {"from": account, "value": value})
    tx.wait(1)
    
    # if tx.return_value:
    #     print(f"Account f{account.address} made a successful reservation in Topic: {topic_detail.address}")
    # else:
    #     print(f"Reservation failed")
        
    print(f"Account f{account.address} made a successful reservation in Topic: {topic_detail.address}")


def getNumberOfReservations():
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    result = topic_detail.reservationCount({"from": account})
    return result


def getStatus():
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    result = topic_detail.status({"from": account})
    return result


def getNumberOfPublishers():
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    result = topic_detail.publisherCount({"from": account})
    return result


def addPublishers():
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    tx = topic_detail.addPublishers({"from": account})
    tx.wait(1)
    
    return tx

def main():
    broker = deploy_broker()
    register()
    register()
    # register()
    # register()
    
    startTime = int(time.time()) + 900
    endTime = int(time.time()) + 1020
    
    topic_detail = deploy_topic("sensing", 1000, 10, 3, 5, 1, startTime, endTime, 2, 5, 1)
    tx = broker.create_topic(topic_detail.address, {"from": get_account()})
    tx.wait(1)
    
    # if tx.return_value:
    #     print("Topic Successfully Created")
    # else:
    #     print("No Topic Created")
    
    print("Topic Successfully Created")
        
    get_topics("sensing", 1000, 10, 4)
    print(f"The Topic Detailed Contract Address is {topic_detail.address}")
    
    subscribe()
    print(f"Number of subscribers in the given topic are {getNumberOfSubscribers()}")
    print(f"Current Status of the topic is: {getStatus()}")
    
    reserve(startTime, endTime)
    print(f"Number of reservations in the given topic are {getNumberOfReservations()}")
    
    while(int(time.time()) < endTime):
        time.sleep(120)
        print(f"Status of the task: {startTime - int(time.time())}")
    
    # addPublishers()
    print(f"Number of publishers {getNumberOfPublishers()}")
        
    
    
    
    