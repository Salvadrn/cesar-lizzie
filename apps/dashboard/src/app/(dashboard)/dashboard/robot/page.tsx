'use client';

import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import { io, Socket } from 'socket.io-client';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api/v1';

interface RobotStatus {
  robot: {
    id: string;
    name: string;
    status: string;
    lastSeenAt: string;
    firmwareVersion: string;
    config: {
      followDistanceM: number;
      maxSpeed: number;
      emergencyStopCm: number;
      lidarEnabled: boolean;
    };
  };
  latestTelemetry: {
    state: string;
    batteryPercent: number;
    bleEstimatedDistance: number | null;
    bleTargetFound: boolean;
    lidarNearestObstacle: number | null;
    ultrasonicFrontLeft: number | null;
    ultrasonicFrontRight: number | null;
    motorSpeed: number;
    steeringAngle: number;
    cpuTemp: number;
    uptimeSeconds: number;
  } | null;
}

const STATE_COLORS: Record<string, string> = {
  idle: 'bg-gray-400',
  following: 'bg-green-500',
  paused: 'bg-yellow-500',
  error: 'bg-red-500',
  emergency_stop: 'bg-red-700',
  disconnected: 'bg-gray-600',
  online: 'bg-green-500',
  offline: 'bg-gray-400',
};

function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-white text-sm font-medium ${STATE_COLORS[status] || 'bg-gray-400'}`}>
      <span className="w-2 h-2 rounded-full bg-white animate-pulse" />
      {status.replace('_', ' ').toUpperCase()}
    </span>
  );
}

function StatCard({ label, value, unit, alert }: { label: string; value: string | number | null; unit?: string; alert?: boolean }) {
  return (
    <div className={`bg-white rounded-xl p-4 border ${alert ? 'border-red-300 bg-red-50' : 'border-gray-200'}`}>
      <p className="text-sm text-gray-500">{label}</p>
      <p className={`text-2xl font-bold ${alert ? 'text-red-600' : 'text-gray-900'}`}>
        {value !== null && value !== undefined ? value : '--'}
        {unit && <span className="text-sm font-normal text-gray-400 ml-1">{unit}</span>}
      </p>
    </div>
  );
}

export default function RobotPage() {
  const [status, setStatus] = useState<RobotStatus | null>(null);
  const [telemetry, setTelemetry] = useState<RobotStatus['latestTelemetry']>(null);
  const [loading, setLoading] = useState(true);
  const [socket, setSocket] = useState<Socket | null>(null);

  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;

  const fetchStatus = useCallback(async () => {
    try {
      const res = await axios.get(`${API}/robot/my`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data) {
        const statusRes = await axios.get(`${API}/robot/${res.data.id}/status`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        setStatus(statusRes.data);
        setTelemetry(statusRes.data.latestTelemetry);
      }
    } catch (err) {
      console.error('Failed to fetch robot status', err);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    fetchStatus();
  }, [fetchStatus]);

  useEffect(() => {
    if (!token) return;
    const userId = localStorage.getItem('userId');
    if (!userId) return;

    const s = io('http://localhost:3001/events', { query: { userId } });
    s.on('robot:telemetry_update', (data) => {
      setTelemetry(data);
    });
    s.on('robot:status_update', (data) => {
      setStatus((prev) => prev ? { ...prev, robot: { ...prev.robot, status: data.status } } : prev);
    });
    setSocket(s);
    return () => { s.disconnect(); };
  }, [token]);

  const sendCommand = async (commandType: string) => {
    if (!status?.robot.id) return;
    try {
      await axios.post(
        `${API}/robot/${status.robot.id}/command`,
        { commandType },
        { headers: { Authorization: `Bearer ${token}` } },
      );
    } catch (err) {
      console.error('Command failed', err);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-64 text-gray-400">Loading robot status...</div>;
  }

  if (!status) {
    return (
      <div className="text-center py-16">
        <p className="text-6xl mb-4">🤖</p>
        <h2 className="text-xl font-semibold text-gray-700">No Robot Connected</h2>
        <p className="text-gray-500 mt-2">Register a robot to start monitoring.</p>
      </div>
    );
  }

  const t = telemetry;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{status.robot.name}</h1>
          <p className="text-sm text-gray-500">SN: {status.robot.serialNumber || '--'} | FW: {status.robot.firmwareVersion || '--'}</p>
        </div>
        <StatusBadge status={t?.state || status.robot.status} />
      </div>

      {/* Telemetry Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard label="Battery" value={t?.batteryPercent?.toFixed(0) ?? null} unit="%" alert={t ? t.batteryPercent < 20 : false} />
        <StatCard label="Patient Distance" value={t?.bleEstimatedDistance?.toFixed(1) ?? null} unit="m" />
        <StatCard label="Target Found" value={t?.bleTargetFound ? 'Yes' : 'No'} alert={t ? !t.bleTargetFound : false} />
        <StatCard label="Nearest Obstacle" value={t?.lidarNearestObstacle ? (t.lidarNearestObstacle / 1000).toFixed(1) : null} unit="m" />
        <StatCard label="Speed" value={t?.motorSpeed?.toFixed(2) ?? null} />
        <StatCard label="Steering" value={t?.steeringAngle?.toFixed(1) ?? null} unit="deg" />
        <StatCard label="CPU Temp" value={t?.cpuTemp?.toFixed(1) ?? null} unit="C" alert={t ? t.cpuTemp > 75 : false} />
        <StatCard label="Uptime" value={t ? `${Math.floor(t.uptimeSeconds / 60)}m` : null} />
      </div>

      {/* Ultrasonic Sensors */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-sm font-semibold text-gray-500 uppercase mb-4">Ultrasonic Sensors</h3>
        <div className="grid grid-cols-2 gap-4">
          <StatCard
            label="Front Left"
            value={t?.ultrasonicFrontLeft?.toFixed(0) ?? null}
            unit="cm"
            alert={t ? (t.ultrasonicFrontLeft ?? 999) < 30 : false}
          />
          <StatCard
            label="Front Right"
            value={t?.ultrasonicFrontRight?.toFixed(0) ?? null}
            unit="cm"
            alert={t ? (t.ultrasonicFrontRight ?? 999) < 30 : false}
          />
        </div>
      </div>

      {/* Controls */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-sm font-semibold text-gray-500 uppercase mb-4">Controls</h3>
        <div className="flex gap-3 flex-wrap">
          <button onClick={() => sendCommand('start')} className="px-6 py-3 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700">
            Start Following
          </button>
          <button onClick={() => sendCommand('pause')} className="px-6 py-3 bg-yellow-500 text-white rounded-lg font-medium hover:bg-yellow-600">
            Pause
          </button>
          <button onClick={() => sendCommand('resume')} className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">
            Resume
          </button>
          <button onClick={() => sendCommand('stop')} className="px-6 py-3 bg-gray-600 text-white rounded-lg font-medium hover:bg-gray-700">
            Stop
          </button>
          <button onClick={() => sendCommand('emergency_stop')} className="px-6 py-3 bg-red-700 text-white rounded-lg font-bold hover:bg-red-800">
            EMERGENCY STOP
          </button>
          <button onClick={() => sendCommand('reset')} className="px-6 py-3 bg-gray-400 text-white rounded-lg font-medium hover:bg-gray-500">
            Reset
          </button>
        </div>
      </div>

      {/* Config */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-sm font-semibold text-gray-500 uppercase mb-4">Configuration</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div>
            <p className="text-gray-500">Follow Distance</p>
            <p className="font-semibold">{status.robot.config?.followDistanceM ?? '--'} m</p>
          </div>
          <div>
            <p className="text-gray-500">Max Speed</p>
            <p className="font-semibold">{status.robot.config?.maxSpeed ?? '--'}</p>
          </div>
          <div>
            <p className="text-gray-500">Emergency Stop</p>
            <p className="font-semibold">{status.robot.config?.emergencyStopCm ?? '--'} cm</p>
          </div>
          <div>
            <p className="text-gray-500">LiDAR</p>
            <p className="font-semibold">{status.robot.config?.lidarEnabled ? 'Enabled' : 'Disabled'}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
