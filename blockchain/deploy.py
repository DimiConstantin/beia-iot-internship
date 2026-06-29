#!/usr/bin/env python3

import json
import os
from solcx import compile_standard, install_solc
from web3 import Web3

CONTRACT_FILE = os.path.join(os.path.dirname(__file__), "AnchorStore.sol")
OUT_FILE = os.path.join(os.path.dirname(__file__), "deployed.json")
GANACHE_URL = "http://localhost:8545"
SOLC_VERSION = "0.8.0"

# --- 1. citeste sursa ---
with open(CONTRACT_FILE) as f:
    source = f.read()

# --- 2. compileaza ---
install_solc(SOLC_VERSION)
compiled = compile_standard({
    "language": "Solidity",
    "sources": {"AnchorStore.sol": {"content": source}},
    "settings": {
        "outputSelection": {
            "*": {"*": ["abi", "evm.bytecode.object"]}
        }
    },
}, solc_version=SOLC_VERSION)

abi = compiled["contracts"]["AnchorStore.sol"]["AnchorStore"]["abi"]
bytecode = compiled["contracts"]["AnchorStore.sol"]["AnchorStore"]["evm"]["bytecode"]["object"]

# --- 3. conecteaza-te la Ganache ---
w3 = Web3(Web3.HTTPProvider(GANACHE_URL))
assert w3.is_connected(), "Ganache nu raspunde la " + GANACHE_URL
account = w3.eth.accounts[0]          # primul cont de test
w3.eth.default_account = account

# --- 4. deploy ---
Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
tx_hash = Contract.constructor().transact()
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
address = receipt.contractAddress

print("Contract deployat la:", address)

# --- 5. salveaza adresa + ABI pentru anchor.py ---
with open(OUT_FILE, "w") as f:
    json.dump({"address": address, "abi": abi}, f, indent=2)
print("Adresa + ABI salvate in", OUT_FILE)
