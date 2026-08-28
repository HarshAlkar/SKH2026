import React from 'react';
import VerificationModal from '../../components/verification/VerificationModal';
import { adminApi } from '../../services/apiService';

export default function DoctorVerification({ isOpen, onClose, doctor, onVerified }) {
  if (!doctor) return null;

  const profileFields = [
    { label: 'Full Name', value: doctor.full_name || doctor.name },
    { label: 'Email', value: doctor.email },
    { label: 'Phone', value: doctor.phone_number },
    { label: 'Specialization', value: doctor.specialization },
    { label: 'Hospital/Clinic', value: doctor.hospital_name },
    { label: 'License Number', value: doctor.license_number },
    { label: 'Experience (Years)', value: doctor.experience_years },
    { label: 'Registered On', value: new Date(doctor.created_at || Date.now()).toLocaleDateString() },
  ];

  return (
    <VerificationModal
      isOpen={isOpen}
      onClose={onClose}
      data={doctor}
      title={`Verify Doctor: ${doctor.full_name || doctor.name}`}
      profileFields={profileFields}
      onApprove={async (id) => {
        await adminApi.approveDoctor(id);
        if (onVerified) onVerified();
      }}
      onReject={async (id, reason) => {
        await adminApi.rejectDoctor(id, reason);
        if (onVerified) onVerified();
      }}
    />
  );
}
