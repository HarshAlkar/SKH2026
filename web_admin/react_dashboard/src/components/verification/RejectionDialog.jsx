import React, { useState } from 'react';
import { Modal } from '../ui/Modal';

export default function RejectionDialog({ isOpen, onClose, onConfirm, isSubmitting }) {
  const [reason, setReason] = useState('');

  const handleConfirm = () => {
    if (!reason.trim()) return;
    onConfirm(reason);
  };

  return (
    <Modal open={isOpen} onClose={onClose} title="Reject Verification">
      <div className="p-4">
        <p className="text-sm text-gray-600 mb-4">
          Please provide a reason for rejecting this verification request. This reason will be shown to the user.
        </p>
        <textarea
          className="w-full border rounded-lg p-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
          rows={4}
          placeholder="Reason for rejection (mandatory)..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
        <div className="flex justify-end gap-3 mt-6">
          <button
            className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg"
            onClick={onClose}
            disabled={isSubmitting}
          >
            Cancel
          </button>
          <button
            className="px-4 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
            onClick={handleConfirm}
            disabled={!reason.trim() || isSubmitting}
          >
            {isSubmitting ? 'Rejecting...' : 'Reject'}
          </button>
        </div>
      </div>
    </Modal>
  );
}
