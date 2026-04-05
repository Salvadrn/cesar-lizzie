'use client';

export default function SafetyPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Safety Zones</h1>
      <div className="bg-white p-8 rounded-2xl shadow-sm text-center">
        <p className="text-5xl mb-4">🗺️</p>
        <p className="text-gray-500 text-lg">Map view coming in Phase 2</p>
        <p className="text-gray-400 mt-2">
          You'll be able to set up geofenced safety zones for your users here.
          When a user leaves a safe zone, you'll receive an alert.
        </p>
      </div>
    </div>
  );
}
