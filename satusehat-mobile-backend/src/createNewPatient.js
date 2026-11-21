import { loadConfig } from './config.js';
import { TokenManager } from './tokenManager.js';
import { SatuSehatClient } from './satusehatClient.js';

async function main() {
    const config = loadConfig();
    const tokens = new TokenManager(config);
    const ss = new SatuSehatClient(config, tokens);

    console.log('=== Mendaftarkan Pasien Anak Baru (POST /Patient) ke SATUSEHAT Sandbox ===');

    // NIK 16 digit baru (kombinasi 3509 + 12 digit acak agar selalu unik di Sandbox)
    const randomSuffix = Math.floor(100000000000 + Math.random() * 900000000000);
    const nikBaru = '3509' + randomSuffix;

    // Anda juga bisa menentukan NIK pilihan Anda sendiri pada data di bawah:
    const dataPasienBaru = {
        nik: 3501123456780001,
        name: 'Mirza Ayo Sholat',
        gender: 'male', // 'male' (Laki-laki) atau 'female' (Perempuan)
        birthDate: '2024-02-15', // Format YYYY-MM-DD
        address: 'Jl. Medan Merdeka Barat No. 1',
        city: 'Jakarta Pusat',
    };

    try {
        console.log(`Mengirim POST /Patient dengan NIK: ${dataPasienBaru.nik}...`);
        const patientResult = await ss.createPatientByNik(dataPasienBaru);
        const newIhsNumber = patientResult.id;

        console.log('\n======================================================');
        console.log('🎉 SUKSES BESAR! DATA PASIEN BERHASIL DIBUAT DI KEMENKES!');
        console.log('======================================================');
        console.log('Status        : 201 Created');
        console.log('IHS Number    :', newIhsNumber);
        console.log('NIK Pasien    :', dataPasienBaru.nik);
        console.log('Nama Lengkap  :', dataPasienBaru.name);
        console.log('Jenis Kelamin :', patientResult.gender);
        console.log('Tanggal Lahir :', patientResult.birthDate);
        console.log('======================================================\n');
        console.log('Silakan refresh Portal Log SATUSEHAT Anda untuk melihat status Sukses!');
    } catch (error) {
        console.error('\nPendaftaran Gagal:', error.message);
        if (error.details) {
            console.error('Detail Error Respons Kemenkes:', JSON.stringify(error.details, null, 2));
        }
    }
}

main();
