import { loadConfig } from './config.js';
import { TokenManager } from './tokenManager.js';

const config = loadConfig();
const token = await new TokenManager(config).getToken();
console.log(`Token OK (env: ${config.envName}), panjang: ${token.length}`);
