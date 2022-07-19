""" The main goal of this python file is to call 
    the functions on the smart contract periodically.
"""

from web3 import Web3
from web3.exceptions import ContractLogicError

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545/"))

abi = []


address = "0x0"
arbitrage_contract = w3.eth.contract(address=Web3.toChecksumAddress(address), abi=abi)


arbitrage_contract.functions.sth

async def swap_on_eth(tokens: list[str], amount_in: int, gas: int) -> list:
    private_key = 123
    trx_hashes = list()
    for token in tokens:
        try: 
            trx = arbitrage_contract.functions.swapOnWETH(token, amount_in, gas).buildTransaction()
            signed_trx = w3.eth.account.sign_transaction(trx, private_key)
            gas_estimate = w3.eth.estimateGas(signed_trx)
        except ContractLogicError:
            continue
        trx_hash = w3.eth.sendRawTransaction(signed_trx.rawTransaction)
        trx_hashes.append(w3.toHex(trx_hash))
    return trx_hashes

async def swap_on_stable(tokens: list[str], stable_coins: list[str], amount_in: int, gas: int) -> list:
    private_key = 123
    trx_hashes = list()
    for token in tokens:
        for coin0 in stable_coins:
            for coin1 in stable_coins:
                try: 
                    trx = arbitrage_contract.functions.swapOnStableCoin(coin0, coin1, token, amount_in, gas).buildTransaction()
                    signed_trx = w3.eth.account.sign_transaction(trx, private_key)
                    gas_estimate = w3.eth.estimateGas(signed_trx)
                except ContractLogicError:
                    continue
                trx_hash = w3.eth.sendRawTransaction(signed_trx.rawTransaction)
                trx_hashes.append(w3.toHex(trx_hash))
        return trx_hashes
