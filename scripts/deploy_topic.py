from brownie import TopicDetail, Broker, network, config
from scripts.deploy_broker import deploy_broker, get_topics
from scripts.deploy_user_manager import register, getUserInfo
from scripts.helpful_scripts import get_account
import timeit
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
    
    # testing on localchain
    # if tx.return_value:
    #     print(f"Account f{account.address} has successfully subscribed to the given Topic")
    # else:
    #     print(f"Subscription request failed")
    
    # testing on kovan
    # print(f"Account f{account.address} has successfully subscribed to the given Topic")


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
    
    # testing on local chain
    # if tx.return_value:
    #     print(f"Account f{account.address} made a successful reservation in Topic: {topic_detail.address}")
    # else:
    #     print(f"Reservation failed")
    
    # testing on Kovan
    # print(f"Account f{account.address} made a successful reservation in Topic: {topic_detail.address}")


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


def getReservation(id):
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    result = topic_detail.getReservation(id, {"from": account})
    return result


def getPublisher(id):
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    result = topic_detail.getPublisher(id, {"from": account})
    return result


def addPublishers():
    topic_detail = TopicDetail[-1]
    account = get_account()
    
    tx = topic_detail.addPublishers({"from": account})
    tx.wait(1)
    
    return tx

def submitData(data, _index):
    topic_detail = TopicDetail[-1]
    account = get_account(_index)
    
    tx = topic_detail.submitData(data, {"from": account})
    tx.wait(1)
    
    if tx.return_value:
        print("The data was submitted successfully")
    else:
        print("Data Submission failed")
        

def validate():
    topic_detail = TopicDetail[-1]
    account = get_account(1)
    
    tx = topic_detail.validateData({"from": account})
    tx.wait(1)
    
    if tx.return_value:
        print("Data is Validated Now !!!")
    else:
        print("Validation")


# def main():
#     broker = deploy_broker()
#     register()
#     register()
#     # register()
#     # register()
    
#     startTime = int(time.time()) + 900
#     endTime = int(time.time()) + 1020
    
#     topic_detail = deploy_topic("sensing", 1000, 10, 3, 5, 1, startTime, endTime, 2, 5, 1)
#     tx = broker.create_topic(topic_detail.address, {"from": get_account()})
#     tx.wait(1)
    
#     # if tx.return_value:
#     #     print("Topic Successfully Created")
#     # else:
#     #     print("No Topic Created")
    
#     print("Topic Successfully Created")
        
#     get_topics("sensing", 1000, 10, 4)
#     print(f"The Topic Detailed Contract Address is {topic_detail.address}")
    
#     subscribe()
#     print(f"Number of subscribers in the given topic are {getNumberOfSubscribers()}")
#     print(f"Current Status of the topic is: {getStatus()}")
    
#     reserve(startTime, endTime)
#     print(f"Number of reservations in the given topic are {getNumberOfReservations()}")
    
#     while(int(time.time()) < endTime):
#         time.sleep(120)
#         print(f"Status of the task: {startTime - int(time.time())}")
    
#     # addPublishers()
#     print(f"Number of publishers {getNumberOfPublishers()}")
        
    
def main():
    broker = deploy_broker()
    
    # for i in range(1,31):
    #     register(i)
    register(1)
    register(2)
    register(3)
    register(4)
    register(5)
    register(6)
    register(7)
    register(8)
    register(9)
    
    
    startTime = int(time.time()) + 900
    endTime = int(time.time()) + 1020
    
    num_pub = 7
    start_time = timeit.default_timer()
    topic_detail = deploy_topic("sensing", 1000, 10, 3, 5, 1, startTime, endTime, 16, num_pub, 1, 1)
    tx = broker.create_topic(topic_detail.address, {"from": get_account(1)})
    tx.wait(1)
    print(timeit.default_timer() - start_time)
    
    if tx.return_value:
        print("Topic Successfully Created")
    else:
        print("No Topic Created") 
    
    print(f"The Topic Detailed Contract Address is {topic_detail.address}")
    get_topics("sensing", 1000, 10, 4)

    start_time = timeit.default_timer()
    subscribe(1)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    subscribe(2)
    print(timeit.default_timer() - start_time)

    start_time = timeit.default_timer()
    subscribe(3)
    print(timeit.default_timer() - start_time)

    start_time = timeit.default_timer()
    subscribe(4)
    print(timeit.default_timer() - start_time)
   
    # subscribe(2)
    # subscribe(3)
    # subscribe(4)
    

    print(f"Number of subscribers in the given topic are {getNumberOfSubscribers()}")
    print(f"Current Status of the topic is: {getStatus()}")
    
    # start_time = timeit.default_timer()
    # for i in range (1,31):
    #     reserve(startTime + i, endTime - i, i)
    # print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 50, endTime - 50, 1)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 45, endTime - 45, 2)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 40, endTime - 40, 3)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 35, endTime - 35, 4)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 30, endTime - 30, 5)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 25, endTime - 25, 6)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 20, endTime - 20, 7)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 15, endTime - 15, 8)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    reserve(startTime + 10, endTime - 10, 9)
    print(timeit.default_timer() - start_time)
    
    
    print(f"Number of reservations in the given topic are {getNumberOfReservations()}")
    
    for i in range(1, 10):
        print(getReservation(i))
        
    start_time = timeit.default_timer()
    addPublishers()
    print(timeit.default_timer() - start_time)
    
    print(f"Number of publishers are {getNumberOfPublishers()}")
    
    for i in range(1, 8):
        print(getPublisher(i))
    
        
    data1 = [25, 50, 75, 100]
    data2 = [26, 51, 76, 101]
    data3 = [27, 52, 77, 102]
    data4 = [28, 53, 78, 103]
    data5 = [29, 54, 79, 104]
    data6 = [30, 55, 80, 105]
    data7 = [31, 56, 81, 106]    

    start_time = timeit.default_timer()
    submitData(data1, 3)
    print(timeit.default_timer() - start_time)        
    
    start_time = timeit.default_timer()
    submitData(data2, 4)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    submitData(data3, 5)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    submitData(data4, 6)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    submitData(data5, 7)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    submitData(data6, 8)
    print(timeit.default_timer() - start_time)
    
    start_time = timeit.default_timer()
    submitData(data7, 9)
    print(timeit.default_timer() - start_time)

    start_time = timeit.default_timer()
    validate() #No data pushed into the chain, all computational performance leads to large exec. time but less gas consumption.
    print(timeit.default_timer() - start_time)    
    
    for i in range(1, 8):
        print(getPublisher(i))
        
        
    print("")
    
    
    for i in range(1, 10):
        getUserInfo(i)
    
    