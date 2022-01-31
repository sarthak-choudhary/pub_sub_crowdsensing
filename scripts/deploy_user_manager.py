from brownie import UserManager
from scripts.helpful_scripts import get_account

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
    
    # if tx.return_value:
    #     print("The User is Registered.")
    # else:
    #     print("The User is already registered.")
    
def main():
    deploy_user_manager()
    register(1)
    register(2)
    register(3)
    
    register(1)
    
    
    