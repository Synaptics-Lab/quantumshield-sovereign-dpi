const { SynapticClient } = require('./index');
const assert = require('assert');

async function test() {
  console.log('Testing JS SynapticClient SDK...');
  const seed = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  const rails = SynapticClient.derive5Rail(seed);

  assert(rails.synaptic.startsWith('syn1'));
  assert(rails.ethereum.startsWith('0x'));
  assert(rails.xrpl.startsWith('r'));
  assert(rails.bitcoin.startsWith('bc1q'));
  assert.strictEqual(rails.solana.length, 44);

  console.log('✓ 5-Rail Derivation Passed:');
  console.log('  Synaptic:', rails.synaptic);
  console.log('  Ethereum:', rails.ethereum);

  const { skChains, pkChains } = SynapticClient.generateWotsKeypair(seed);
  assert.strictEqual(skChains.length, 67);
  assert.strictEqual(pkChains.length, 67);
  console.log('✓ CE-WOTS+ Keygen (67 chains) Passed');

  const client = new SynapticClient();
  try {
    const status = await client.getStatus();
    console.log(`✓ L1 RPC Connectivity Passed: Height #${status.checkpoint_height}`);
  } catch (e) {
    console.log('Note: RPC connection test:', e.message);
  }
}

test().catch(err => {
  console.error(err);
  process.exit(1);
});
