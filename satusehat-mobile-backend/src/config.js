import 'dotenv/config';

const HOSTS = {
    development: 'https://api-satusehat-dev.dto.kemkes.go.id',
    staging: 'https://api-satusehat-stg.dto.kemkes.go.id',
    production: 'https://api-satusehat.kemkes.go.id',
};

export function loadConfig(env = process.env) {
    const name = (env.SATUSEHAT_ENV || 'staging').toLowerCase();
    const host = HOSTS[name];
    if (!host) {
        throw new Error(`SATUSEHAT_ENV tidak valid: "${name}" (pilih: ${Object.keys(HOSTS).join(', ')})`);
    }

    const missing = ['SATUSEHAT_CLIENT_ID', 'SATUSEHAT_CLIENT_SECRET'].filter((k) => !env[k]);
    if (missing.length) {
        throw new Error(`Env belum diisi: ${missing.join(', ')}. Lihat .env.example`);
    }

    return {
        envName: name,
        clientId: env.SATUSEHAT_CLIENT_ID,
        clientSecret: env.SATUSEHAT_CLIENT_SECRET,
        organizationId: env.SATUSEHAT_ORGANIZATION_ID || '',
        authUrl: (env.SATUSEHAT_AUTH_URL || `${host}/oauth2/v1`).replace(/\/$/, ''),
        fhirUrl: (env.SATUSEHAT_FHIR_URL || `${host}/fhir-r4/v1`).replace(/\/$/, ''),
        appApiKey: env.APP_API_KEY || '',
        port: Number(env.PORT || 3000),
    };
}
