from brownie import UserManager
from scripts.helpful_scripts import get_account
import timeit
import time

def deploy_user_manager():
    account = get_account()
    user_manager = UserManager.deploy(
        1,
        account.address,
        {"from": account}
    )
    
    print("Deployed UserManager")
    return user_manager
    

def register(_index=None):
    if _index:
        account = get_account(index=_index)
    else:
        account = get_account()
        
    user_manager = UserManager[-1]
    
    tx = user_manager.register({"from": account})
    tx.wait(1)

    return tx.gas_used
    
    # testing on localchain
    # if tx.return_value:
    #     print("The User is Registered.")
    # else:
    #     print("The User is already registered.")

def getUserInfo(_id):
    user_manager = UserManager[-1]
    account = get_account()
    
    tx = user_manager.getUserInfo(_id, {"from": account})
    
    print(tx)
    
def main():
    deploy_user_manager()
    # start_time = timeit.default_timer()
    # register(1)
    # print(timeit.default_timer() - start_time)

    # start_time = timeit.default_timer()
    # register(2)
    # print(timeit.default_timer() - start_time)
    
    # start_time = timeit.default_timer()
    # register(3)
    # print(timeit.default_timer() - start_time)
    
    # start_time = timeit.default_timer()
    # register(99)
    # print(timeit.default_timer() - start_time)
    
    # gas_consumed = 0
    # start_time = timeit.default_timer()
    # for i in range(0,25):
    #     gas_consumed += register(i)
    # print(timeit.default_timer() - start_time)
    # print(gas_consumed)
    
    # start_time = timeit.default_timer()
    # register(0)
    # print(timeit.default_timer() - start_time)

    
    