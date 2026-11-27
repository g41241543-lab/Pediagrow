const NIK_SYSTEM = 'https://fhir.kemkes.go.id/id/nik';

export class SatuSehatClient {
  constructor(config, tokenManager, fetchImpl = globalThis.fetch) {
    this.config = config;
    this.tokens = tokenManager;
    this.fetch = fetchImpl;
  }

  async #request(method, path, { params, body } = {}, retried = false) {
    const url = new URL(`${this.config.fhirUrl}${path}`);
    if (params) Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));

    const token = await this.tokens.getToken();
    const res = await this.fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/fhir+json',
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    // Token ditolak (mis. kedaluwarsa): batalkan cache, ulangi sekali
    if (res.status === 401 && !retried) {
      this.tokens.invalidate();
      return this.#request(method, path, { params, body }, true);
    }

    const data = await res.json().catch(() => null);
    if (!res.ok) {
      const err = new Error(`SATUSEHAT ${method} ${path} gagal (HTTP ${res.status})`);
      err.status = res.status;
      err.details = data;
      throw err;
    }
    return data;
  }

  // 1. Cari data pasien berdasarkan NIK (16 digit) -> FHIR Bundle
  searchPatientByNik(nik) {
    return this.#request('GET', '/Patient', { params: { identifier: `${NIK_SYSTEM}|${nik}` } });
  }

  // 2. Ambil data pasien berdasarkan IHS number
  getPatient(ihsNumber) {
    return this.#request('GET', `/Patient/${encodeURIComponent(ihsNumber)}`);
  }

  // 3. Mendaftarkan Pasien Anak Baru menggunakan NIK mandiri (POST /Patient)
  async createPatientByNik({ nik, name, gender, birthDate, address, city }) {
    const cleanName = (name || 'Pasien Anak').trim();
    const nameParts = cleanName.split(/\s+/);
    const familyName = nameParts.length > 1 ? nameParts[nameParts.length - 1] : nameParts[0];
    const givenNames = nameParts.length > 1 ? nameParts.slice(0, -1) : [nameParts[0]];

    const payload = {
      resourceType: 'Patient',
      meta: {
        profile: ['https://fhir.kemkes.go.id/r4/StructureDefinition/Patient'],
      },
      identifier: [
        {
          use: 'official',
          system: NIK_SYSTEM,
          value: String(nik).trim(),
        },
      ],
      active: true,
      name: [
        {
          use: 'official',
          text: cleanName,
          family: familyName,
          given: givenNames,
        },
      ],
      gender: (gender === 'Perempuan' || gender === 'female') ? 'female' : 'male',
      birthDate: birthDate || '2024-01-01',
      multipleBirthBoolean: false, // Rule 10167 & 10813
      telecom: [
        {
          system: 'phone',
          value: '081234567890',
          use: 'mobile',
        },
      ],
      address: [
        {
          use: 'home',
          line: [address || 'Jl. Medan Merdeka Barat No. 1'],
          city: city || 'Jakarta Pusat',
          postalCode: '10110',
          country: 'ID',
          extension: [
            {
              url: 'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
              extension: [
                {
                  url: 'province',
                  valueCode: '31', // DKI Jakarta
                },
                {
                  url: 'city',
                  valueCode: '3171', // Jakarta Pusat
                },
                {
                  url: 'district',
                  valueCode: '317101', // Gambir
                },
                {
                  url: 'village',
                  valueCode: '3171011001', // Kel. Gambir (Master Kemendagri Valid)
                },
                {
                  url: 'rt',
                  valueCode: '001',
                },
                {
                  url: 'rw',
                  valueCode: '001',
                },
              ],
            },
          ],
        },
      ],
    };

    return this.#request('POST', '/Patient', { body: payload });
  }

  // 4. Membuat Kunjungan/Pemeriksaan (Encounter)
  async createEncounter({ patientIhs, practitionerIhs = '10001700778', startTime, endTime }) {
    const start = startTime || new Date().toISOString();
    const end = endTime || new Date().toISOString();

    const payload = {
      resourceType: 'Encounter',
      status: 'finished',
      class: {
        system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
        code: 'AMB',
        display: 'ambulatory',
      },
      subject: {
        reference: `Patient/${patientIhs}`,
      },
      participant: [
        {
          type: [
            {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/v3-ParticipationType',
                  code: 'ATND',
                  display: 'attender',
                },
              ],
            },
          ],
          individual: {
            reference: `Practitioner/${practitionerIhs}`,
          },
        },
      ],
      period: {
        start: start,
        end: end,
      },
      serviceProvider: {
        reference: `Organization/${this.config.organizationId}`,
      },
    };

    return this.#request('POST', '/Encounter', { body: payload });
  }

  // 5. Mengirim data antropometri anak (BB, TB, Lingkar Kepala) -> FHIR Observation
  async recordChildGrowth({
    patientIhs,
    encounterId,
    practitionerIhs = '10001700778',
    weightKg,
    heightCm,
    headCircumferenceCm,
    recordDate,
  }) {
    const timestamp = recordDate || new Date().toISOString();

    // Di SATUSEHAT, Observation wajib memiliki Encounter induk (Rule 10130)
    let activeEncounterId = encounterId;
    if (!activeEncounterId) {
      const enc = await this.createEncounter({ patientIhs, practitionerIhs, startTime: timestamp, endTime: timestamp });
      activeEncounterId = enc.id;
    }

    const results = { encounterId: activeEncounterId };

    // Berat Badan (LOINC: 29463-7)
    if (weightKg != null && weightKg !== '') {
      results.weight = await this.#request('POST', '/Observation', {
        body: {
          resourceType: 'Observation',
          status: 'final',
          category: [
            {
              coding: [{ system: 'http://terminology.hl7.org/CodeSystem/observation-category', code: 'vital-signs' }],
            },
          ],
          code: {
            coding: [{ system: 'http://loinc.org', code: '29463-7', display: 'Body weight' }],
          },
          subject: { reference: `Patient/${patientIhs}` },
          encounter: { reference: `Encounter/${activeEncounterId}` }, // Rule 10130
          performer: [{ reference: `Practitioner/${practitionerIhs}` }], // Rule 10383
          effectiveDateTime: timestamp,
          issued: timestamp, // Rule 10296
          valueQuantity: {
            value: Number(weightKg),
            unit: 'kg',
            system: 'http://unitsofmeasure.org',
            code: 'kg',
          },
        },
      });
    }

    // Tinggi Badan (LOINC: 8302-2)
    if (heightCm != null && heightCm !== '') {
      results.height = await this.#request('POST', '/Observation', {
        body: {
          resourceType: 'Observation',
          status: 'final',
          category: [
            {
              coding: [{ system: 'http://terminology.hl7.org/CodeSystem/observation-category', code: 'vital-signs' }],
            },
          ],
          code: {
            coding: [{ system: 'http://loinc.org', code: '8302-2', display: 'Body height' }],
          },
          subject: { reference: `Patient/${patientIhs}` },
          encounter: { reference: `Encounter/${activeEncounterId}` }, // Rule 10130
          performer: [{ reference: `Practitioner/${practitionerIhs}` }], // Rule 10383
          effectiveDateTime: timestamp,
          issued: timestamp, // Rule 10296
          valueQuantity: {
            value: Number(heightCm),
            unit: 'cm',
            system: 'http://unitsofmeasure.org',
            code: 'cm',
          },
        },
      });
    }

    // Lingkar Kepala (LOINC: 9843-4)
    if (headCircumferenceCm != null && headCircumferenceCm !== '') {
      results.headCircumference = await this.#request('POST', '/Observation', {
        body: {
          resourceType: 'Observation',
          status: 'final',
          category: [
            {
              coding: [{ system: 'http://terminology.hl7.org/CodeSystem/observation-category', code: 'vital-signs' }],
            },
          ],
          code: {
            coding: [{ system: 'http://loinc.org', code: '9843-4', display: 'Head Occipital-frontal circumference' }],
          },
          subject: { reference: `Patient/${patientIhs}` },
          encounter: { reference: `Encounter/${activeEncounterId}` }, // Rule 10130
          performer: [{ reference: `Practitioner/${practitionerIhs}` }], // Rule 10383
          effectiveDateTime: timestamp,
          issued: timestamp, // Rule 10296
          valueQuantity: {
            value: Number(headCircumferenceCm),
            unit: 'cm',
            system: 'http://unitsofmeasure.org',
            code: 'cm',
          },
        },
      });
    }

    return results;
  }
}
