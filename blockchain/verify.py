#!/usr/bin/env python3
"""Verifica integritatea: recalculeaza hash-ul unui lot din .jsonl
si il compara cu cel ancorat pe blockchain."""

import json
import os
import sys

from web3 import Web3

DATA_FILE = os.path.expanduser("~/practica/proiect/dimitrie-constantin/sensor-data.jsonl")
DEPLOYED = os.path.join(os.path.dirname(__file__), "deployed.json")
GANACHE_URL = "http://localhost:8545"
BATCH_SIZE = 50

with open(DEPLOYED) as f:
    info = json.load(f)
w3 = Web3(Web3.HTTPProvider(GANACHE_URL))
c = w3.eth.contract(address=info["address"], abi=info["abi"])

def hash_batch(lines):
    return w3.keccak(text="".join(lines))   # IDENTIC cu anchor.py

# ce lot verificam (din argument, default 0)
batch_id = int(sys.argv[1]) if len(sys.argv) > 1 else 0

with open(DATA_FILE) as f:
    lines = f.readlines()

start = batch_id * BATCH_SIZE
end = start + BATCH_SIZE
batch_lines = lines[start:end]

local_hash = hash_batch(batch_lines)
chain_hash = c.functions.getHash(batch_id).call()

print(f"Lot {batch_id}")
print("  Hash local (recalculat):", local_hash.hex())
print("  Hash pe blockchain:     ", chain_hash.hex())

if local_hash == chain_hash:
    print("  ✓ INTACT — datele nu au fost modificate")
else:
    print("  ✗ ALTERAT — datele difera de ce a fost ancorat!")
