import React from 'react';
import { Download, Eye } from 'lucide-react';

export default function VerificationDocumentViewer({ documents }) {
  if (!documents || documents.length === 0) {
    return <p className="text-sm text-gray-500 italic">No documents uploaded.</p>;
  }

  const isImage = (url) => {
    if (!url) return false;
    return url.match(/\.(jpeg|jpg|gif|png)$/i) != null;
  };

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      {documents.map((doc, idx) => (
        <div key={idx} className="border rounded-lg overflow-hidden flex flex-col bg-gray-50">
          <div className="p-3 bg-white border-b flex justify-between items-center">
            <span className="text-sm font-semibold text-gray-700 capitalize">
              {doc.document_type?.replace('_', ' ')}
            </span>
            <div className="flex gap-2">
              <a
                href={doc.file}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:text-primary-dark"
                title="View Full"
              >
                <Eye size={16} />
              </a>
              <a
                href={doc.file}
                download
                className="text-gray-500 hover:text-gray-700"
                title="Download"
              >
                <Download size={16} />
              </a>
            </div>
          </div>
          <div className="p-2 flex-grow flex items-center justify-center">
            {isImage(doc.file) ? (
              <img
                src={doc.file}
                alt={doc.document_type}
                className="max-h-48 object-contain"
              />
            ) : (
              <div className="text-center py-6">
                <p className="text-sm text-gray-500 mb-2">Document format not previewable</p>
                <a
                  href={doc.file}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary text-sm font-semibold hover:underline"
                >
                  Open Document
                </a>
              </div>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}
