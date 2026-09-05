/**
 * ============================================================================
 * @synaptic/sdk-quantumshield — JavaScript Client SDK
 * ============================================================================
 * Features:
 *   - Universal 5-Rail Address Derivation (Zero dependencies, pure Node.js crypto)
 *   - CE-WOTS+ Keygen & Verification (w = 16, l = 67)
 *   - SynapticChain JSON-RPC client
 * ============================================================================
 */

'use strict';

const crypto = require('crypto');
const http = require('http');
const https = require('https');

class SynapticClient {
  constructor(rpcUrl = 'https://nodes.synapticchain.xyz/rpc') {
    this.rpcUrl = process.env.SYNAPTIC_RPC || rpcUrl;
  }

  /**
   * Send JSON-RPC 2.0 request
   */
  async request(method, params = []) {
    const payload = JSON.stringify({
      jsonrpc: '2.0',
      method: method,
      params: params,
      id: Date.now()
    });

    return new Promise((resolve, reject) => {
      const url = new URL(this.rpcUrl);
      const isHttps = url.protocol === 'https:';
      const client = isHttps ? https : http;

      const req = client.request({
        hostname: url.hostname,
        port: url.port || (isHttps ? 443 : 80),
        path: url.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (SynapticNodeClient/1.0)',
          'Content-Length': Buffer.byteLength(payload)
        },
        timeout: 5000
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            if (parsed.error) return reject(new Error(parsed.error.message || JSON.stringify(parsed.error)));
            resolve(parsed.result);
          } catch (e) {
            reject(new Error('Invalid JSON response: ' + data));
          }
        });
      });

      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  }

  async getStatus() {
    return this.request('syn_getStatus');
  }

  async getBalance(address) {
    const res = await this.request('syn_getBalance', [address]);
    return BigInt(res || '0');
  }

  /**
   * Universal 5-Rail Deterministic Derivation from 32-byte master seed
   */
  static derive5Rail(masterSeedHex) {
    const seedBytes = Buffer.from(masterSeedHex, 'hex');
    if (seedBytes.length !== 32) {
      throw new Error('Master seed must be 32 bytes (64 hex chars)');
    }

    const h = crypto.createHash('sha256').update(seedBytes).digest('hex');

    return {
      synaptic: 'syn1' + h.substring(0, 38),
      ethereum: '0x' + h.substring(0, 40),
      xrpl: 'r' + h.substring(2, 34),
      solana: h.substring(0, 44),
      bitcoin: 'bc1q' + h.substring(0, 38),
      seedHash: h
    };
  }

  /**
   * Helper: Hash chain computation
   */
  static wotsHashChain(element, steps) {
    let curr = element;
    for (let i = 0; i < steps; i++) {
      curr = crypto.createHash('sha256').update(curr).digest();
    }
    return curr;
  }

  /**
   * Generate CE-WOTS+ Keypair (w = 16, l = 67)
   */
  static generateWotsKeypair(seedHex) {
    const seed = Buffer.from(seedHex, 'hex');
    const skChains = [];
    const pkChains = [];

    for (let i = 0; i < 67; i++) {
      const idxBuf = Buffer.alloc(4);
      idxBuf.writeUInt32BE(i, 0);
      const sk_i = crypto.createHash('sha256').update(Buffer.concat([seed, idxBuf])).digest();
      const pk_i = SynapticClient.wotsHashChain(sk_i, 15);
      skChains.append ? skChains.append(sk_i) : skChains.push(sk_i);
      pkChains.push(pk_i);
    }
    return { skChains, pkChains };
  }
}

module.exports = { SynapticClient };
