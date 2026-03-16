import Foundation
import Supabase


extension APIClient {

    // MARK: - Routines

    public func fetchRoutines() async throws -> [RoutineResponse] {
        let routines: [RoutineRow] = try await supabase
            .from("routines")
            .select("*, routine_steps(*)")
            .order("created_at", ascending: false)
            .execute()
            .value
        return routines.map { $0.toResponse() }
    }

    public func fetchRoutine(id: String) async throws -> RoutineResponse {
        let routine: RoutineRow = try await supabase
            .from("routines")
            .select("*, routine_steps(*)")
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return routine.toResponse()
    }
}
