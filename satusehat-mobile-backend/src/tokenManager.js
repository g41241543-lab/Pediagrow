// OAuth2 client_credentials untuk SATUSEHAT.
// Token berlaku ~1 jam; disimpan di memori, di-refresh sebelum kedaluwarsa,
// dan permintaan serentak digabung jadi satu request (tidak membanjiri server auth).

const EARLY_REFRESH_MS = 60_000;

export class TokenManager {
  constructor(config, fetchImpl = globalThis.fetch) {
    this.config = config;
    this.fetch = fetchImpl;
    this.token = null;
    this.expiresAt = 0;
    this.inflight = null;
  }

  async getToken() {
    if (this.token && Date.now() < this.expiresAt - EARLY_REFRESH_MS) {
      return this.token;
    }
    if (!this.inflight) {
      this.inflight = this.#requestToken().finally(() => {
        this.inflight = null;
      });
    }
    return this.inflight;
  }

  invalidate() {
    this.token = null;
    this.expiresAt = 0;
  }

  async #requestToken() {
    const { authUrl, clientId, clientSecret } = this.config;
    const res = await this.fetch(`${authUrl}/accesstoken?grant_type=client_credentials`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret }).toString(),
    });

    const text = await res.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = null;
    }

    if (!res.ok || !body?.access_token) {
      // Jangan pernah mencetak client_secret ke log/error.
      throw new Error(`Gagal mengambil token SATUSEHAT (HTTP ${res.status})`);
    }

    this.token = body.access_token;
    this.expiresAt = Date.now() + Number(body.expires_in || 3599) * 1000;
    return this.token;
  }
}
