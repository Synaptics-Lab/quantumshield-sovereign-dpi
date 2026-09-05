#!/usr/bin/env python3
"""
Unit test suite for SynapticClient SDK.
Verifies:
  - Universal 5-Rail address derivation
  - CE-WOTS+ key generation, signing, and batch verification
  - Monotonic lane watermark key folding
"""

import unittest
import hashlib
from synaptic_client import SynapticClient

class TestSynapticClient(unittest.TestCase):

    def setUp(self):
        self.client = SynapticClient()
        self.test_seed = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

    def test_5rail_derivation(self):
        rails = self.client.derive_5rail(self.test_seed)
        self.assertTrue(rails["synaptic"].startswith("syn1"))
        self.assertTrue(rails["ethereum"].startswith("0x"))
        self.assertTrue(rails["xrpl"].startswith("r"))
        self.assertTrue(rails["bitcoin"].startswith("bc1q"))
        self.assertEqual(len(rails["solana"]), 44)

    def test_wots_signing_and_verification(self):
        sk_chains, pk_chains = self.client.generate_wots_keypair(self.test_seed)
        self.assertEqual(len(sk_chains), 67)
        self.assertEqual(len(pk_chains), 67)

        msg = b"FINOS-HACKATHON-SOVEREIGN-PAYMENT-2026"
        msg_hash = hashlib.sha256(msg).digest()

        sig_chains = self.client.sign_wots(sk_chains, msg_hash)
        self.assertEqual(len(sig_chains), 67)

        # Valid signature must pass
        valid = self.client.verify_wots(pk_chains, sig_chains, msg_hash)
        self.assertTrue(valid, "CE-WOTS+ signature verification failed on valid signature")

        # Corrupted message must fail
        corrupted_hash = hashlib.sha256(b"CORRUPTED").digest()
        invalid = self.client.verify_wots(pk_chains, sig_chains, corrupted_hash)
        self.assertFalse(invalid, "CE-WOTS+ verification must fail on corrupted message")

    def test_watermark_folding(self):
        _, pk_chains = self.client.generate_wots_keypair(self.test_seed)
        f1 = self.client.fold_wots_watermark(pk_chains, 100)
        f2 = self.client.fold_wots_watermark(pk_chains, 101)
        self.assertNotEqual(f1, f2, "Watermark folding must produce unique digests as watermark advances")

if __name__ == "__main__":
    unittest.main()
