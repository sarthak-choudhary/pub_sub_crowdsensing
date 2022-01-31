from brownie import Broker
from scripts.helpful_scripts import get_account
from scripts.deploy_user_manager import deploy_user_manager, register

def deploy_broker():
    user_manager = deploy_user_manager()
    account = get_account()
    
    broker = Broker.deploy(user_manager.address, {"from": account})
    
    return broker

def create_topic(name, deposit, deadline, periods, freq, zone, startDate, endDate, simMatch, index):
    broker = Broker[-1]
    account = get_account(index=index)
    
    tx = broker.create_topic(name, deposit, deadline, periods, freq, zone, startDate, endDate, simMatch, {"from": account})
    tx.wait(1)
    
    # if (tx.return_value == False):
    #     print("Topic couldn't be created")
    
    print("New Topic created sucessful")
        
def get_topics(name, deposit, deadline, len):
    broker = Broker[-1]
    account = get_account()
    
    tx = broker.get_topics(name, deposit, deadline, len, {"from": account})
    
    print("The Results for matching topics are: ")
    for i in tx:
        print(i)
    
def main():
    deploy_broker()
    register(1)
    register(2)
    register(3)
    register(4)
    
    # create_topic("sensing", 1000, 10, 3, 5, 1, 100, 150, 2, 1)
    # create_topic("dummy", 1000, 10, 3, 4, 2, 120, 160, 3, 1)
    # create_topic("sensing", 1000, 10, 3, 4, 2, 120, 160, 3, 2)
    # create_topic("sensing", 1000, 10, 3, 4, 3, 120, 160, 3, 3)
    # create_topic("sensing", 1000, 10, 3, 4, 4, 120, 160, 3, 4)
    
    # get_topics("sensing", 1000, 10, 4)