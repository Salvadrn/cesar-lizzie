'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

interface Routine {
  id: string;
  title: string;
  category: string;
  isActive: boolean;
  assignedTo?: string;
  steps?: { id: string }[];
}

export default function RoutinesPage() {
  const [routines, setRoutines] = useState<Routine[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRoutines = async () => {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
      const token = localStorage.getItem('token');

      try {
        const res = await fetch(`${apiUrl}/routines`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          setRoutines(await res.json());
        }
      } catch {
        console.error('Failed to fetch routines');
      } finally {
        setLoading(false);
      }
    };

    fetchRoutines();
  }, []);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Routines</h1>
        <Link
          href="/dashboard/routines/builder"
          className="px-4 py-2 bg-primary text-white rounded-xl font-medium hover:bg-blue-600 transition"
        >
          + Create Routine
        </Link>
      </div>

      {loading ? (
        <p className="text-gray-500">Loading...</p>
      ) : routines.length === 0 ? (
        <div className="bg-white p-8 rounded-2xl shadow-sm text-center">
          <p className="text-5xl mb-4">📋</p>
          <p className="text-gray-500 text-lg">No routines yet</p>
          <p className="text-gray-400 mt-2">
            Create a routine to help your users with daily tasks
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {routines.map((routine) => (
            <div
              key={routine.id}
              className="bg-white p-5 rounded-xl shadow-sm flex items-center justify-between"
            >
              <div>
                <h3 className="font-semibold text-gray-900">{routine.title}</h3>
                <p className="text-sm text-gray-500 capitalize">
                  {routine.category} · {routine.steps?.length ?? 0} steps
                </p>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-xs font-medium ${
                  routine.isActive
                    ? 'bg-green-50 text-green-700'
                    : 'bg-gray-100 text-gray-500'
                }`}
              >
                {routine.isActive ? 'Active' : 'Inactive'}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
