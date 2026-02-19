'use client';

import { useEffect, useState } from 'react';

interface Alert {
  id: string;
  alertType: string;
  severity: 'info' | 'warning' | 'critical';
  title: string;
  message?: string;
  isRead: boolean;
  createdAt: string;
}

const SEVERITY_STYLES = {
  info: 'bg-blue-50 border-blue-200 text-blue-800',
  warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
  critical: 'bg-red-50 border-red-200 text-red-800',
};

export default function AlertsPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAlerts = async () => {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
      const token = localStorage.getItem('token');
      try {
        const res = await fetch(`${apiUrl}/alerts`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) setAlerts(await res.json());
      } catch {} finally {
        setLoading(false);
      }
    };
    fetchAlerts();
  }, []);

  const markRead = async (id: string) => {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
    const token = localStorage.getItem('token');
    await fetch(`${apiUrl}/alerts/${id}/read`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token}` },
    });
    setAlerts(alerts.map((a) => (a.id === id ? { ...a, isRead: true } : a)));
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Alerts</h1>

      {loading ? (
        <p className="text-gray-500">Loading...</p>
      ) : alerts.length === 0 ? (
        <div className="bg-white p-8 rounded-2xl shadow-sm text-center">
          <p className="text-5xl mb-4">🔔</p>
          <p className="text-gray-500 text-lg">No alerts</p>
          <p className="text-gray-400 mt-2">
            You'll see alerts here when your users need attention
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {alerts.map((alert) => (
            <div
              key={alert.id}
              className={`p-4 rounded-xl border ${SEVERITY_STYLES[alert.severity]} ${
                !alert.isRead ? 'ring-2 ring-offset-1' : 'opacity-75'
              }`}
            >
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold uppercase">
                      {alert.severity}
                    </span>
                    <span className="text-xs opacity-60">
                      {new Date(alert.createdAt).toLocaleString()}
                    </span>
                  </div>
                  <h3 className="font-semibold mt-1">{alert.title}</h3>
                  {alert.message && (
                    <p className="text-sm mt-1 opacity-80">{alert.message}</p>
                  )}
                </div>
                {!alert.isRead && (
                  <button
                    onClick={() => markRead(alert.id)}
                    className="text-xs underline opacity-60 hover:opacity-100"
                  >
                    Mark read
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
