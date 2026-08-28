import React, { useState } from 'react';
import { Modal } from '../ui/Modal';
import VerificationStatusBadge from './VerificationStatusBadge';
import VerificationDocumentViewer from './VerificationDocumentViewer';
import RejectionDialog from './RejectionDialog';
import { toast } from '../ui/Toast';

export default function VerificationModal({
  isOpen,
  onClose,
  data,
  title = "Review Verification",
  profileFields = [],
  onApprove,
  onReject,
}) {
  const [isRejectOpen, setIsRejectOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!data) return null;

  const handleApprove = async () => {
    if (!window.confirm("Are you sure you want to approve this verification?")) return;
    
    setIsSubmitting(true);
    try {
      await onApprove(data.id);
      toast('Verification approved successfully!');
      onClose();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleReject = async (reason) => {
    setIsSubmitting(true);
    try {
      await onReject(data.id, reason);
      toast('Verification rejected successfully.');
      setIsRejectOpen(false);
      onClose();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const isPending = data.verification_status === 'PENDING_VERIFICATION';

  return (
    <>
      <Modal open={isOpen} onClose={onClose} title={title}>
        <div className="p-6 max-h-[80vh] overflow-y-auto">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-800">Profile Details</h3>
            <VerificationStatusBadge status={data.verification_status} />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8 border rounded-lg p-4 bg-gray-50">
            {profileFields.map((field, idx) => (
              <div key={idx} className="flex flex-col">
                <span className="text-xs text-gray-500 uppercase tracking-wider">{field.label}</span>
                <span className="text-sm font-medium text-gray-900 mt-1">
                  {field.value || 'N/A'}
                </span>
              </div>
            ))}
            
            {data.rejection_reason && data.verification_status === 'REJECTED' && (
              <div className="flex flex-col sm:col-span-2 mt-2 p-3 bg-red-50 border border-red-100 rounded-lg">
                <span className="text-xs text-red-600 uppercase tracking-wider font-semibold">Rejection Reason</span>
                <span className="text-sm text-red-800 mt-1">{data.rejection_reason}</span>
              </div>
            )}
          </div>

          <h3 className="text-lg font-semibold text-gray-800 mb-4">Verification Documents</h3>
          <VerificationDocumentViewer documents={data.documents || []} />

          {isPending && (
            <div className="mt-8 flex justify-end gap-4 border-t pt-4">
              <button
                className="px-6 py-2 rounded-lg font-semibold text-red-600 bg-red-50 hover:bg-red-100 disabled:opacity-50"
                onClick={() => setIsRejectOpen(true)}
                disabled={isSubmitting}
              >
                Reject
              </button>
              <button
                className="px-6 py-2 rounded-lg font-semibold text-white bg-green-600 hover:bg-green-700 disabled:opacity-50"
                onClick={handleApprove}
                disabled={isSubmitting}
              >
                {isSubmitting ? 'Processing...' : 'Approve'}
              </button>
            </div>
          )}
        </div>
      </Modal>

      <RejectionDialog
        isOpen={isRejectOpen}
        onClose={() => setIsRejectOpen(false)}
        onConfirm={handleReject}
        isSubmitting={isSubmitting}
      />
    </>
  );
}
