'use client';

import { useEffect, useState } from 'react';

export default function UsersPage() {
  const [inviteCode, setInviteCode] = useState('');
  const [linkedUsers, setLinkedUsers] = useState<any[]>([]);
  const [generating, setGenerating] = useState(false);

  useEffect(() => {
    fetchLinkedUsers();
  }, []);

  const fetchLinkedUsers = async () => {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${apiUrl}/caregiver/linked-users`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) setLinkedUsers(await res.json());
    } catch {}
  };

  const generateInvite = async () => {
    setGenerating(true);
    const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${apiUrl}/caregiver/generate-invite`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      setInviteCode(data.inviteCode);
    } catch {
      console.error('Failed to generate invite');
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Linked Users</h1>

      {/* Invite Section */}
      <div className="bg-white p-6 rounded-2xl shadow-sm mb-6">
        <h2 className="font-semibold text-gray-900 mb-2">Link a New User</h2>
        <p className="text-sm text-gray-500 mb-4">
          Generate an invite code and share it with a user to link their account.
        </p>
        <div className="flex gap-3">
          <button
            onClick={generateInvite}
            disabled={generating}
            className="px-4 py-2 bg-primary text-white rounded-xl font-medium hover:bg-blue-600 transition disabled:opacity-60"
          >
            {generating ? 'Generating...' : 'Generate Invite Code'}
          </button>
          {inviteCode && (
            <div className="flex items-center gap-2 px-4 py-2 bg-green-50 rounded-xl">
              <span className="font-mono text-lg font-bold text-green-700">
                {inviteCode}
              </span>
              <button
                onClick={() => navigator.clipboard.writeText(inviteCode)}
                className="text-sm text-green-600 hover:underline"
              >
                Copy
              </button>
            </div>
          )}
        </div>
      </div>

      {/* User List */}
      {linkedUsers.length === 0 ? (
        <div className="bg-white p-8 rounded-2xl shadow-sm text-center">
          <p className="text-gray-500">No linked users yet</p>
        </div>
      ) : (
        <div className="space-y-3">
          {linkedUsers.map((link: any) => (
            <div
              key={link.id}
              className="bg-white p-5 rounded-xl shadow-sm flex items-center justify-between"
            >
              <div>
                <h3 className="font-semibold text-gray-900">
                  {link.user?.displayName ?? 'Unknown User'}
                </h3>
                <p className="text-sm text-gray-500">
                  {link.relationship ?? 'No relationship set'} · {link.user?.email}
                </p>
              </div>
              <span className="px-3 py-1 bg-green-50 text-green-700 rounded-full text-xs font-medium">
                {link.status}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
