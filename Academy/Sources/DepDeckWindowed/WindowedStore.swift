import Foundation
import SwiftUI
import AcademyCore

// GIVEN — but notice: this store is just *wiring*. Every line that does
// real work calls a function YOU wrote in Stages 1–5. Until those stages
// pass, the window stays empty. That's the deal.

@MainActor
final class WindowedStore: ObservableObject {
    @Published var packages: [Package] = []
    @Published var isLoading = false
    @Published var error: String?

    var issuePackages: [Package] { packages.filter(\.hasIssue) }   // Stage 1

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let json = try await Shell.run("brew info --json=v2 --installed") // Stage 2
            packages = sortedByName(try parseBrewInfo(json))                  // Stages 3 + 5
        } catch {
            self.error = error.localizedDescription
        }
    }
}
