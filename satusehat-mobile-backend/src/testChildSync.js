import { loadConfig } from './config.js';
import { TokenManager } from './tokenManager.js';
import { SatuSehatClient } from './satusehatClient.js';

async function main() {
  const config = loadConfig();
  const tokens = new TokenManager(config);
  const ss = new SatuSehatClient(config, tokens);

  console.log('=== Menguji Pencarian Pasien & Kirim Antropometri ke SATUSEHAT ===');
  const testNik = '9271060312000001'; // NIK contoh sandbox

  try {

    const searchRes = await ss.searchPatientByNik(testNik);
    const patientResource = searchRes.entry?.[0]?.resource;

    if (!patientResource) {
      console.log(`Pasien dengan NIK ${testNik} tidak ditemukan.`);
      return;
    }

    const patientIhs = patientResource.id;
    const patientName = patientResource.name?.[0]?.text || 'Nama Pasien';
    console.log(`[OK] Pasien ditemukan! Nama: ${patientName}, IHS: ${patientIhs}`);

    console.log('Mengirim observasi pertumbuhan anak...');
    const growth = await ss.recordChildGrowth({
      patientIhs,
      weightKg: 12.5,
      heightCm: 86.0,
      headCircumferenceCm: 47.0,
    });

    console.log('[OK] Observation Berat Badan Sukses! ID :', growth.weight?.id);
    console.log('[OK] Observation Tinggi Badan Sukses! ID:', growth.height?.id);
    console.log('[OK] Observation LK Sukses! ID          :', growth.headCircumference?.id);
  } catch (error) {
    console.error('Pengujian Gagal:', error.message);
    if (error.details) {
      console.error('Detail Error:', JSON.stringify(error.details, null, 2));
    }
  }
}

main();
