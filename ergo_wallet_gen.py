#!/usr/bin/env python3

#python script courtsey of MGpai 

from bip_utils import *

mnemonic = Bip39MnemonicGenerator().FromWordsNumber(Bip39WordsNum.WORDS_NUM_24)
print(mnemonic)

seed_bytes = Bip39SeedGenerator(mnemonic).Generate()
bip44_mst_ctx = Bip44.FromSeed(seed_bytes, Bip44Coins.ERGO)

bip44_acc_ctx = bip44_mst_ctx.Purpose().Coin().Account(0)
bip44_chg_ctx = bip44_acc_ctx.Change(Bip44Changes.CHAIN_EXT)

bip44_addr_ctx = bip44_chg_ctx.AddressIndex(0)

address = bip44_addr_ctx.PublicKey().ToAddress()

print(address)
