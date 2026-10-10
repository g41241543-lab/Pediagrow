import 'package:flutter/material.dart';

import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'booking_dokter_page.dart';

export 'booking_dokter_page.dart';

/// Halaman Menunggu Persetujuan Dokter telah digantikan oleh [BookingDokterPage]
/// sesuai sistem booking jadwal dokter oleh pengguna.
class MenungguPersetujuanPage extends StatelessWidget {
  final DoctorModel? doctor;
  final ConsultationModel? consultation;
  final DateTime? consultationCreatedAt;
  final ChildModel? child;

  const MenungguPersetujuanPage({
    super.key,
    this.doctor,
    this.consultation,
    this.consultationCreatedAt,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BookingDokterPage(
      doctor: doctor ?? consultation?.doctor,
      child: child,
    );
  }
}
