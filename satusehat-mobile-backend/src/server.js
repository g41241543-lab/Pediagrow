import crypto from 'node:crypto';
import express from 'express';
import { loadConfig } from './config.js';
import { TokenManager } from './tokenManager.js';
import { SatuSehatClient } from './satusehatClient.js';

const config = loadConfig();
const tokens = new TokenManager(config);
const ss = new SatuSehatClient(config, tokens);

const app = express();
app.use(express.json());

// Middleware Guard: Aplikasi mobile mengirim header x-api-key
function requireAppKey(req, res, next) {
  if (!config.appApiKey) return next(); // Dimatikan bila APP_API_KEY kosong (mode dev)
  const given = Buffer.from(String(req.header('x-api-key') || ''));
  const want = Buffer.from(config.appApiKey);
  if (given.length === want.length && crypto.timingSafeEqual(given, want)) return next();
  res.status(401).json({ error: 'unauthorized: x-api-key tidak valid' });
}

// 1. Healthcheck
app.get('/health', (_req, res) => res.json({ ok: true, env: config.envName }));

// 2. Cari Pasien Berdasarkan NIK (16 digit)
app.get('/patients', requireAppKey, async (req, res) => {
  const nik = String(req.query.nik || '').trim();
  if (!/^\d{16}$/.test(nik)) {
    return res.status(400).json({ error: 'NIK harus 16 digit angka' });
  }
  try {
    const result = await ss.searchPatientByNik(nik);
    res.json(result);
  } catch (e) {
    res.status(e.status || 502).json({ error: e.message, details: e.details });
  }
});

// 3. Ambil Pasien Berdasarkan IHS Number
app.get('/patients/:ihs', requireAppKey, async (req, res) => {
  try {
    const result = await ss.getPatient(req.params.ihs);
    res.json(result);
  } catch (e) {
    res.status(e.status || 502).json({ error: e.message, details: e.details });
  }
});

// 4. Mendaftarkan Pasien Anak Baru (POST /Patient)
app.post('/patients', requireAppKey, async (req, res) => {
  const { nik, name, gender, birthDate, address, city } = req.body;
  const cleanNik = String(nik || '').trim();
  if (!/^\d{16}$/.test(cleanNik)) {
    return res.status(400).json({ error: 'NIK anak wajib 16 digit angka' });
  }
  try {
    // 1. Cek dulu apakah NIK ini sudah ada di SATUSEHAT
    try {
      const searchRes = await ss.searchPatientByNik(cleanNik);
      const existingIhs = searchRes.entry?.[0]?.resource?.id;
      if (existingIhs) {
        console.log(`[OK] Pasien sudah terdaftar di SATUSEHAT. Mengambil IHS: ${existingIhs}`);
        return res.status(200).json({
          status: 'success',
          ihsNumber: existingIhs,
          patient: searchRes.entry[0].resource,
        });
      }
    } catch (_) {}

    // 2. Jika belum ada, daftarkan baru ke SATUSEHAT
    const result = await ss.createPatientByNik({ nik: cleanNik, name, gender, birthDate, address, city });
    console.log(`[OK] Pasien baru berhasil didaftarkan di SATUSEHAT! IHS: ${result.id}`);
    res.status(201).json({
      status: 'success',
      ihsNumber: result.id,
      patient: result,
    });
  } catch (e) {
    res.status(e.status || 502).json({ error: e.message, details: e.details });
  }
});

// 5. Mengirim Data Pengukuran Antropometri Anak (BB, TB, Lingkar Kepala)
app.post('/children/growth', requireAppKey, async (req, res) => {
  const { patientIhs, weightKg, heightCm, headCircumferenceCm, recordDate } = req.body;
  if (!patientIhs) {
    return res.status(400).json({ error: 'patientIhs wajib diisi' });
  }
  try {
    const growth = await ss.recordChildGrowth({
      patientIhs,
      weightKg,
      heightCm,
      headCircumferenceCm,
      recordDate,
    });
    res.status(201).json({
      status: 'success',
      patientIhs,
      observations: {
        weightId: growth.weight?.id || null,
        heightId: growth.height?.id || null,
        headCircumferenceId: growth.headCircumference?.id || null,
      },
    });
  } catch (e) {
    res.status(e.status || 502).json({ error: e.message, details: e.details });
  }
});

// 6. Sinkronisasi Data Profil Anak (Cari IHS / Daftarkan Baru + Simpan Antropometri)
app.post('/children/sync-profile', requireAppKey, async (req, res) => {
  const { nik, name, gender, birthDate, address, city, weightKg, heightCm, headCircumferenceCm, recordDate } = req.body;
  const cleanNik = String(nik || '').trim();
  if (!/^\d{16}$/.test(cleanNik)) {
    return res.status(400).json({ error: 'NIK anak wajib 16 digit angka' });
  }

  try {
    console.log(`\n[LOG SATUSEHAT] Memproses Sinkronisasi Profil Anak NIK: ${cleanNik}`);

    // Coba cari dulu apakah anak sudah punya IHS di SATUSEHAT
    let patientIhs = null;
    let patientName = name;

    const searchResult = await ss.searchPatientByNik(cleanNik);
    const existing = searchResult.entry?.[0]?.resource;

    if (existing && existing.id) {
      patientIhs = existing.id;
      patientName = existing.name?.[0]?.text || patientName;
      console.log(`[OK] Pasien sudah terdaftar di SATUSEHAT. IHS: ${patientIhs}`);
    } else {
      // Jika belum ada, daftarkan pasien baru
      console.log(`[INFO] Pasien belum terdaftar. Mendaftarkan pasien baru ke SATUSEHAT...`);
      const newPatient = await ss.createPatientByNik({
        nik: cleanNik,
        name: patientName,
        gender,
        birthDate,
        address,
        city,
      });
      patientIhs = newPatient.id;
      console.log(`[OK] Pasien baru berhasil didaftarkan! IHS: ${patientIhs}`);
    }

    // Rekam observasi pertumbuhan (BB, TB, LK) jika datanya ada
    let growthResult = {};
    if (weightKg != null || heightCm != null || headCircumferenceCm != null) {
      growthResult = await ss.recordChildGrowth({
        patientIhs,
        weightKg,
        heightCm,
        headCircumferenceCm,
        recordDate,
      });
      console.log(`[OK] Data Pertumbuhan Anak berhasil dicatat ke SATUSEHAT!`);
    }

    res.status(201).json({
      status: 'success',
      patientIhs,
      patientName,
      observations: {
        weightId: growthResult.weight?.id || null,
        heightId: growthResult.height?.id || null,
        headCircumferenceId: growthResult.headCircumference?.id || null,
      },
    });
  } catch (e) {
    console.error(`[ERROR] Gagal memproses data anak:`, e.message);
    res.status(e.status || 502).json({ error: e.message, details: e.details });
  }
});

app.listen(config.port, () => {
  console.log(`Backend SATUSEHAT jalan di :${config.port} (env: ${config.envName})`);
});
