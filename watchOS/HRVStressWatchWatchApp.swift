//
//  HRVStressWatchWatchApp.swift
//  watchOS App entry
//

import SwiftUI

@main
struct HRVStressWatchWatchApp: App {
    @StateObject private var viewModel = WatchViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchMainView(viewModel: viewModel)
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
