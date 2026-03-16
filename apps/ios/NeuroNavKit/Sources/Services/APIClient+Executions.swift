import Foundation
import Supabase


extension APIClient {

    // MARK: - Executions

    public func startExecution(routineId: String) async throws -> ExecutionResponse {
        let userId = try await currentUserId()

        let steps: [StepRow] = try await supabase
            .from("routine_steps")
            .select()
            .eq("routine_id", value: routineId)
            .execute()
            .value

        let newExecution = NewExecution(
            routineId: routineId,
            userId: userId,
            totalSteps: steps.count
        )

        let row: ExecutionRow = try await supabase
            .from("routine_executions")
            .insert(newExecution)
            .select()
            .single()
            .execute()
            .value
        return row.toResponse()
    }

    /// Completes a step and atomically increments execution counters via RPC.
    /// Falls back to read-then-write if RPC is not available.
    public func completeStep(executionId: String, stepId: String, duration: Int, errors: Int, stalls: Int, rePrompts: Int) async throws {
        let stepExec = NewStepExecution(
            executionId: executionId,
            stepId: stepId,
            status: AppConstants.StepExecutionStatus.completed.rawValue,
            durationSeconds: duration,
            errorCount: errors,
            stallCount: stalls,
            rePromptCount: rePrompts
        )
        try await supabase
            .from("step_executions")
            .insert(stepExec)
            .execute()

        // Atomic increment via RPC — avoids race condition from read-then-write
        do {
            try await supabase.rpc("increment_execution_counters", params: [
                "p_execution_id": executionId,
                "p_error_count": errors,
                "p_stall_count": stalls
            ]).execute()
        } catch {
            // Fallback: read-then-write (less safe but functional without RPC)
            let current: ExecutionRow = try await supabase
                .from("routine_executions")
                .select()
                .eq("id", value: executionId)
                .single()
                .execute()
                .value

            try await supabase
                .from("routine_executions")
                .update([
                    "completed_steps": current.completedSteps + 1,
                    "error_count": current.errorCount + errors,
                    "stall_count": current.stallCount + stalls
                ])
                .eq("id", value: executionId)
                .execute()
        }
    }

    public func completeExecution(id: String) async throws {
        try await supabase
            .from("routine_executions")
            .update([
                "status": AppConstants.ExecutionStatus.completed.rawValue,
                "completed_at": Self.iso8601.string(from: Date())
            ])
            .eq("id", value: id)
            .execute()
    }

    public func fetchTodayExecutions() async throws -> [ExecutionRow] {
        let userId = try await currentUserId()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let startOfDayISO = Self.iso8601.string(from: startOfDay)

        let executions: [ExecutionRow] = try await supabase
            .from("routine_executions")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: AppConstants.ExecutionStatus.completed.rawValue)
            .gte("started_at", value: startOfDayISO)
            .execute()
            .value
        return executions
    }

    public func fetchPatientExecutions(userId: String) async throws -> [ExecutionRow] {
        let executions: [ExecutionRow] = try await supabase
            .from("routine_executions")
            .select()
            .eq("user_id", value: userId)
            .order("started_at", ascending: false)
            .limit(20)
            .execute()
            .value
        return executions
    }
}
