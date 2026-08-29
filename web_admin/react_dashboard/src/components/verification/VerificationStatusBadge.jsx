import React from 'react';

export default function VerificationStatusBadge({ status }) {
  let colorClass = 'bg-gray-100 text-gray-700';
  let label = 'INCOMPLETE';

  if (status === 'VERIFIED') {
    colorClass = 'bg-green-100 text-green-700';
    label = 'VERIFIED';
  } else if (status === 'PENDING_VERIFICATION') {
    colorClass = 'bg-orange-100 text-orange-700';
    label = 'PENDING';
  } else if (status === 'REJECTED') {
    colorClass = 'bg-red-100 text-red-700';
    label = 'REJECTED';
  }

  return (
    <span className={`px-2 py-1 text-xs font-semibold rounded-full whitespace-nowrap ${colorClass}`}>
      {label}
    </span>
  );
}
