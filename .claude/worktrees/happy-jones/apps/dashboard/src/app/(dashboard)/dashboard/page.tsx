'use client';

import { useEffect, useState } from 'react';

interface LinkedUser {
  id: string;
  user: {
    id: string;
    displayName: string;
    email: string;
  };
  relationship: string;
}

export default function OverviewPage() {
  const [linkedUsers, setLinkedUsers] = useState<LinkedUser[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
      const token = localStorage.getItem('token');

      try {
        const res = await fetch(`${apiUrl}/caregiver/linked-users`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          setLinkedUsers(await res.json());
        }
      } catch {
        console.error('Failed to fetch linked users');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Overview</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="bg-white p-6 rounded-2xl shadow-sm">
          <p className="text-sm text-gray-500">Linked Users</p>
          <p className="text-3xl font-bold text-gray-900 mt-1">
            {linkedUsers.length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm">
          <p className="text-sm text-gray-500">Active Alerts</p>
          <p className="text-3xl font-bold text-warning mt-1">0</p>
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm">
          <p className="text-sm text-gray-500">Routines Created</p>
          <p className="text-3xl font-bold text-gray-900 mt-1">0</p>
        </div>
      </div>

      {/* Linked Users */}
      <h2 className="text-lg font-semibold text-gray-900 mb-4">Your Users</h2>
      {loading ? (
        <p className="text-gray-500">Loading...</p>
      ) : linkedUsers.length === 0 ? (
        <div className="bg-white p-8 rounded-2xl shadow-sm text-center">
          <p className="text-gray-500 text-lg">No linked users yet</p>
          <p className="text-gray-400 mt-2">
            Share an invite code with a user to get started
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {linkedUsers.map((link) => (
            <div key={link.id} className="bg-white p-6 rounded-2xl shadow-sm">
              <h3 className="text-lg font-semibold text-gray-900">
                {link.user.displayName}
              </h3>
              <p className="text-sm text-gray-500">{link.relationship}</p>
              <div className="mt-4 flex gap-2">
                <span className="px-3 py-1 bg-green-50 text-green-700 rounded-full text-xs font-medium">
                  Active
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
