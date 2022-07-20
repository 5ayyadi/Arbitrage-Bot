""" The main goal of this python file is to call 
    the functions on the smart contract periodically.
"""

import asyncio
import os
import json
import ABI
import time
from typing import List
from web3 import Web3
from web3.exceptions import ContractLogicError

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545/"))
# w3 = Web3(Web3.AsyncHTTPProvider("http://127.0.0.1:8545/") ,modules={'eth': (AsyncEth,)})

with open(os.getcwd() + "/artifacts/contracts/Arbitrage.sol/Arbitrage.json") as f:
    abi = json.load(f).get("abi")


address = "0x71a0b8A2245A9770A4D887cE1E4eCc6C1d4FF28c"
arbitrage_contract = w3.eth.contract(address=Web3.toChecksumAddress(address), abi=abi)
tokens = {
    "USDT": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
    "DAI": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    "BUSD": "0x4Fabb145d64652a948d72533023f6E7A623C7C53",
    "USDC": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
}
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

# arbitrage_contract.functions.sth
def get_balance(account, token) -> int:
    if hasattr(account, "address"):
        account = account.address
    return w3.eth.contract(token, abi=ABI.ABI.TOKEN).functions.balanceOf(account).call()


def get_eth_balance(account) -> int:
    if hasattr(account, "address"):
        account = account.address
    return w3.eth.get_balance(account)


def send_approve(account, spender, token):
    try:
        return send_transaction(
            account,
            w3.eth.contract(token, abi=ABI.ABI.TOKEN)
            .functions.approve(spender, 2**95)
            .build_transaction(),
        )
    except Exception as e:
        print(e)
        ...


def send_transaction(account, trx):
    trx.update(
        **{
            "from": account.address,
            "nonce": w3.eth.get_transaction_count(account.address),
        }
    )
    return w3.toHex(
        w3.eth.wait_for_transaction_receipt(
            w3.eth.send_raw_transaction(account.sign_transaction(trx).rawTransaction)
        ).transactionHash
    )


def swap_on_eth_uniswap(account, router, tokens, amount):
    [send_approve(account, router, token) for token in tokens]
    uniswap_router = w3.eth.contract(router, abi=ABI.ABI.UNISWAP_ROUTER).functions
    print({token: get_balance(account, token) for token in tokens})
    r = send_transaction(
        account,
        uniswap_router.swapExactETHForTokens(
            0, tokens, account.address, int(time.time()) + 3600
        ).build_transaction({"value": amount}),
    )
    print({token: get_balance(account, token) for token in tokens})


async def swap_on_eth(account, tokens: List[str], amount_in: int, gas: int) -> list:
    funcs = arbitrage_contract.functions
    trx_hashes = list()
    for token in tokens:
        print(f"{w3.eth.block_number=}")
        try:
            nonce = w3.eth.get_transaction_count(account.address)
            trx = funcs.swapOnWETH(token, amount_in, gas).build_transaction(
                {"nonce": nonce, "from": account.address}
            )
            signed_trx = w3.eth.account.sign_transaction(trx, private_key)
            w3.eth.estimate_gas(trx)

            trx_result = funcs.swapOnWETH(token, amount_in, gas).call(
                {"nonce": nonce, "from": account.address}
            )
            print(f"{trx_result=}")
        except ContractLogicError as e:
            print(e)
            continue
        print(f"prevBalance {get_eth_balance(account) / 10 ** 18}")
        sent_transaction = w3.eth.sendRawTransaction(signed_trx.rawTransaction)
        print(f"{w3.eth.wait_for_transaction_receipt(sent_transaction)=}")
        time.sleep(2)
        trx_hashes.append(w3.toHex(sent_transaction))
        print(f"newBalance {get_eth_balance(account) / 10 ** 18}")
        print()
    print(f"{trx_hashes=}")
    return trx_hashes


async def swap_on_stable(
    tokens: List[str], stable_coins: List[str], amount_in: int, gas: int
) -> list:
    private_key = 123
    trx_hashes = list()
    for token in tokens:
        for coin0 in stable_coins:
            for coin1 in stable_coins:
                try:
                    trx = arbitrage_contract.functions.swapOnStableCoin(
                        coin0, coin1, token, amount_in, gas
                    ).buildTransaction()
                    signed_trx = w3.eth.account.sign_transaction(trx, private_key)
                    gas_estimate = w3.eth.estimate_gas(signed_trx)

                except ContractLogicError:
                    continue
                trx_hash = w3.eth.sendRawTransaction(signed_trx.rawTransaction)
                trx_hashes.append(w3.toHex(trx_hash))
        return trx_hashes


if __name__ == "__main__":
    private_key = "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0"
    account = w3.eth.account.privateKeyToAccount(private_key)
    print(
        swap_on_eth_uniswap(
            account,
            "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",  # UNISWAP V2
            [WETH, tokens.get("USDT")],
            90 * 10**18
        )
    )
    asyncio.run(swap_on_eth(account, tokens.values(), 10**18, 21796 * 2524589496))
