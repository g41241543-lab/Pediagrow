import assert from 'node:assert/strict';
import { loadConfig } from '../src/config.js';
import { TokenManager } from '../src/tokenManager.js';
import { SatuSehatClient } from '../src/satusehatClient.js';

const config = loadConfig({
  SATUSEHAT_ENV: 'staging',
  SATUSEHAT_CLIENT_ID: 'id',
  SATUSEHAT_CLIENT_SECRET: 'secret',
});
assert.equal(config.authUrl, 'https://api-satusehat-stg.dto.kemkes.go.id/oauth2/v1');
assert.throws(() => loadConfig({ SATUSEHAT_ENV: 'staging' }), /Env belum diisi/);

let tokenCalls = 0;
let first401 = true;
const mockFetch = async (url, opts) => {
  const u = String(url);
  if (u.includes('/accesstoken')) {
    tokenCalls++;
    assert.match(opts.body, /client_id=id/);
    return new Response(JSON.stringify({ access_token: `tok${tokenCalls}`, expires_in: '3599' }), { status: 200 });
  }
  if (first401) {
    first401 = false;
    return new Response('{}', { status: 401 });
  }
  assert.equal(opts.headers.Authorization, 'Bearer tok2');
  assert.ok(u.includes('identifier=https%3A%2F%2Ffhir.kemkes.go.id%2Fid%2Fnik%7C3171010101900001'));
  return new Response(JSON.stringify({ resourceType: 'Bundle', total: 0 }), { status: 200 });
};

const tm = new TokenManager(config, mockFetch);
// permintaan serentak -> hanya 1 panggilan token
await Promise.all([tm.getToken(), tm.getToken(), tm.getToken()]);
assert.equal(tokenCalls, 1);

// 401 -> token diambil ulang & request diulang sekali
const ss = new SatuSehatClient(config, tm, mockFetch);
const bundle = await ss.searchPatientByNik('3171010101900001');
assert.equal(bundle.resourceType, 'Bundle');
assert.equal(tokenCalls, 2);

console.log('Semua tes lulus');
