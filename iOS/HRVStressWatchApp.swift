//
//  HRVStressWatchApp.swift
//  iOS App entry point
//

import SwiftUI

@main
struct HRVStressWatchApp: App {
    @StateObject private var healthManager = HealthKitManager.shared
    @StateObject private var viewModel = iOSDashboardViewModel()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(healthManager)
                .environmentObject(viewModel)
                .task {
                    await viewModel.bootstrap()
                }
        }
    }
}
