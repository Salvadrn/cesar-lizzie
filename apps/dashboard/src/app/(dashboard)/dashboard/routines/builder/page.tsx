'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface StepDraft {
  title: string;
  instruction: string;
  instructionSimple: string;
  durationHint: number;
  checkpoint: boolean;
}

const CATEGORIES = [
  'cooking', 'hygiene', 'laundry', 'medication',
  'transit', 'shopping', 'cleaning', 'social', 'custom',
];

export default function RoutineBuilderPage() {
  const router = useRouter();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('custom');
  const [steps, setSteps] = useState<StepDraft[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const addStep = () => {
    setSteps([
      ...steps,
      {
        title: '',
        instruction: '',
        instructionSimple: '',
        durationHint: 60,
        checkpoint: false,
      },
    ]);
  };

  const updateStep = (index: number, data: Partial<StepDraft>) => {
    const updated = [...steps];
    updated[index] = { ...updated[index], ...data };
    setSteps(updated);
  };

  const removeStep = (index: number) => {
    setSteps(steps.filter((_, i) => i !== index));
  };

  const saveRoutine = async () => {
    if (!title || steps.length === 0) return;
    setSaving(true);
    setError(null);

    const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3001/api/v1';
    const token = localStorage.getItem('token');
    if (!token) {
      setSaving(false);
      setError('Sesión expirada. Inicia sesión de nuevo.');
      router.replace('/');
      return;
    }

    let createdRoutineId: string | null = null;
    try {
      const routineRes = await fetch(`${apiUrl}/routines`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ title, description, category }),
      });
      if (!routineRes.ok) {
        throw new Error(`No se pudo crear la rutina (${routineRes.status})`);
      }
      const routine = await routineRes.json();
      if (!routine?.id) {
        throw new Error('Respuesta inválida al crear la rutina');
      }
      createdRoutineId = routine.id;

      for (let i = 0; i < steps.length; i++) {
        const stepRes = await fetch(`${apiUrl}/routines/${routine.id}/steps`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            ...steps[i],
            stepOrder: i + 1,
          }),
        });
        if (!stepRes.ok) {
          throw new Error(`Falló el paso ${i + 1} (${stepRes.status})`);
        }
      }

      router.push('/dashboard/routines');
    } catch (err) {
      console.error('Failed to save routine:', err);
      // Roll back the half-created routine so we don't leave orphans.
      if (createdRoutineId) {
        try {
          await fetch(`${apiUrl}/routines/${createdRoutineId}`, {
            method: 'DELETE',
            headers: { Authorization: `Bearer ${token}` },
          });
        } catch (cleanupErr) {
          console.error('Failed to clean up partial routine:', cleanupErr);
        }
      }
      setError(err instanceof Error ? err.message : 'Error al guardar la rutina');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="max-w-3xl">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        Create New Routine
      </h1>

      <div className="bg-white p-6 rounded-2xl shadow-sm space-y-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Routine Title
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g., Morning Hygiene Routine"
            className="w-full p-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Brief description of the routine..."
            rows={2}
            className="w-full p-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Category
          </label>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="w-full p-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
          >
            {CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat.charAt(0).toUpperCase() + cat.slice(1)}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Steps */}
      <h2 className="text-lg font-semibold text-gray-900 mb-4">
        Steps ({steps.length})
      </h2>

      <div className="space-y-4 mb-4">
        {steps.map((step, index) => (
          <div
            key={index}
            className="bg-white p-5 rounded-2xl shadow-sm space-y-3"
          >
            <div className="flex items-center justify-between">
              <span className="text-sm font-bold text-primary">
                Step {index + 1}
              </span>
              <button
                onClick={() => removeStep(index)}
                className="text-red-500 text-sm hover:underline"
              >
                Remove
              </button>
            </div>

            <input
              type="text"
              value={step.title}
              onChange={(e) => updateStep(index, { title: e.target.value })}
              placeholder="Step title"
              className="w-full p-3 border border-gray-200 rounded-xl"
            />

            <textarea
              value={step.instruction}
              onChange={(e) => updateStep(index, { instruction: e.target.value })}
              placeholder="Detailed instruction"
              rows={2}
              className="w-full p-3 border border-gray-200 rounded-xl"
            />

            <input
              type="text"
              value={step.instructionSimple}
              onChange={(e) =>
                updateStep(index, { instructionSimple: e.target.value })
              }
              placeholder="Simple instruction (for lower complexity levels)"
              className="w-full p-3 border border-gray-200 rounded-xl"
            />

            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <label className="text-sm text-gray-600">Duration (sec):</label>
                <input
                  type="number"
                  value={step.durationHint}
                  onChange={(e) =>
                    updateStep(index, { durationHint: Number(e.target.value) })
                  }
                  className="w-20 p-2 border border-gray-200 rounded-lg text-center"
                />
              </div>

              <label className="flex items-center gap-2 text-sm text-gray-600">
                <input
                  type="checkbox"
                  checked={step.checkpoint}
                  onChange={(e) =>
                    updateStep(index, { checkpoint: e.target.checked })
                  }
                  className="rounded"
                />
                Safety checkpoint
              </label>
            </div>
          </div>
        ))}
      </div>

      <button
        onClick={addStep}
        className="w-full p-3 border-2 border-dashed border-gray-300 rounded-xl text-gray-500 hover:border-primary hover:text-primary transition mb-6"
      >
        + Add Step
      </button>

      {error && (
        <div
          role="alert"
          className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-xl text-sm"
        >
          {error}
        </div>
      )}

      {/* Save */}
      <button
        onClick={saveRoutine}
        disabled={!title || steps.length === 0 || saving}
        className="w-full p-4 bg-primary text-white rounded-xl font-semibold hover:bg-blue-600 transition disabled:opacity-50"
      >
        {saving ? 'Saving...' : 'Save Routine'}
      </button>
    </div>
  );
}
