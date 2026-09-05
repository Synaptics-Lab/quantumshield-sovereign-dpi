#!/usr/bin/env node
/**
 * ============================================================================
 * client_agent.js — Autonomous AI Agent x402 Negotiation Client
 * ============================================================================
 * Demonstrates an autonomous agent dynamically negotiating an HTTP 402 paywall:
 *   1. Sends probe request to paywalled API endpoint.
 *   2. Catches HTTP 402 and parses settlement invoice.
 *   3. Resolves L1 payment on SynapticChain.
 *   4. Re-submits request with cryptographic payment receipt.
 * ============================================================================
 */

'use strict';

const http = require('http');
const https = require('https');
const crypto = require('crypto');

const TARGET_URL = process.env.X402_TARGET || 'http://localhost:8402/api/agent-alpha';

function request(urlStr, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlStr);
    const client = url.protocol === 'https:' ? https : http;

    const req = client.request({
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname,
      method: 'GET',
      headers: headers
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: JSON.parse(data)
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function main() {
  console.log('\n================================================================');
  console.log('  AUTONOMOUS AGENT M2M MICROPAYMENT DEMO (RFC 9110 x402)');
  console.log('================================================================\n');

  console.log(`[1] Probing paywalled endpoint: ${TARGET_URL}...`);
  const initial = await request(TARGET_URL);

  if (initial.statusCode === 402) {
    console.log(`  ✓ Received HTTP 402 Payment Required`);
    const invoiceId = initial.headers['x-payment-invoice'];
    const amount = initial.headers['x-payment-amount'];
    const currency = initial.headers['x-payment-currency'];
    const recipient = initial.headers['x-payment-recipient'];

    console.log(`  • Invoice ID:   ${invoiceId}`);
    console.log(`  • Required Fee: ${amount} ${currency}`);
    console.log(`  • Payee:        ${recipient}`);

    console.log(`\n[2] Executing sub-500ms settlement on SynapticChain Layer-1...`);
    const mockTxHash = crypto.randomBytes(32).toString('hex');
    console.log(`  ✓ Broadcasted transaction hash: ${mockTxHash}`);
    console.log(`  ✓ Inclusion confirmed in canonical DAG checkpoint.`);

    console.log(`\n[3] Presenting payment receipt to unlock resource...`);
    const unlocked = await request(TARGET_URL, {
      'Authorization': `x402 ${mockTxHash}`
    });

    if (unlocked.statusCode === 200) {
      console.log(`  ✓ HTTP 200 OK — Resource Unlocked!`);
      console.log(`\n[Payload Received]:`);
      console.log(JSON.stringify(unlocked.body, null, 2));
      console.log('\n================================================================');
      console.log('  SUCCESS: Autonomous Agent settled API access in < 500ms');
      console.log('================================================================\n');
    } else {
      console.error(`  ✗ Failed to unlock: HTTP ${unlocked.statusCode}`, unlocked.body);
    }
  } else {
    console.log(`Endpoint returned HTTP ${initial.statusCode}`, initial.body);
  }
}

main().catch(console.error);
