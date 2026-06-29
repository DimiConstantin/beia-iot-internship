#!/usr/bin/env python3
"""Citeste citiri din .jsonl, le grupeaza in loturi de 50,
calculeaza Keccak-256 peste fiecare lot si ancoreaza hash-ul pe blockchain."""

import json
import os
import time
import logging

from web3 import Web3

# ---------- Config ----------
DATA_FILE = os.path.expanduser("~/practica/proiect/dimitrie-constantin/sensor-data.jsonl")
DEPLOYED = os.path.join(os.path.dirname(__file__), "deployed.json")
STATE_FILE = os.path.join(os.path.dirname(__file__), ".anchor-state")

GANACHE_URL = "http://localhost:8545"
BATCH_SIZE = 50
CHECK_INTERVAL = 15  # secunde

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s",
                    datefmt="%H:%M:%S")
log = logging.getLogger("anchor")

# ---------- Conectare la contract ----------
with open(DEPLOYED) as f:
    info = json.load(f)

w3 = Web3(Web3.HTTPProvider(GANACHE_URL))
w3.eth.default_account = w3.eth.accounts[0]
contract = w3.eth.contract(address=info["address"], abi=info["abi"])

# ---------- Checkpoint (cate LINII am procesat in loturi) ----------
def read_checkpoint():
    try:
        with open(STATE_FILE) as f:
            return int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return 0

def write_checkpoint(n):
    with open(STATE_FILE, "w") as f:
        f.write(str(n))

# ---------- Hashing ----------
def hash_batch(lines):
    # concateneaza cele 50 de linii intr-un singur text si calculeaza Keccak-256
    blob = "".join(lines)
    return w3.keccak(text=blob)   # intoarce 32 de bytes

# ---------- O runda de ancorare ----------
def anchor_once():
    if not w3.is_connected():
        log.warning("Ganache indisponibil, astept...")
        return

    processed = read_checkpoint()

    try:
        with open(DATA_FILE) as f:
            lines = f.readlines()
    except FileNotFoundError:
        return

    # cate loturi complete de 50 am acumulat peste ce-am procesat deja
    available = len(lines) - processed
    full_batches = available // BATCH_SIZE
    if full_batches == 0:
        return  # inca nu s-au strans 50 de citiri noi

    for _ in range(full_batches):
        batch_id = processed // BATCH_SIZE          # 0, 1, 2, ...
        start = processed
        end = processed + BATCH_SIZE
        batch_lines = lines[start:end]

        digest = hash_batch(batch_lines)

        tx = contract.functions.storeHash(batch_id, digest).transact()
        w3.eth.wait_for_transaction_receipt(tx)

        processed = end
        write_checkpoint(processed)
        log.info("Lot %d ancorat: %s", batch_id, digest.hex())

# ---------- Bucla ----------
def main():
    log.info("Serviciu de anchoring pornit (lot=%d, interval=%ds)", BATCH_SIZE, CHECK_INTERVAL)
    while True:
        anchor_once()
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()