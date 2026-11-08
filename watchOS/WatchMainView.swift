//
//  WatchMainView.swift
//  watchOS/Views
//

import SwiftUI
import Charts
import WatchKit

struct WatchMainView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                EmojiFace(
                    level: viewModel.currentLevel,
                    customEmoji: viewModel.customEmojis[viewModel.currentLevel],
                    score: viewModel.currentScore
                )
                .frame(width: 160, height: 160)

                if let score = viewModel.currentScore {
                    VStack(spacing: 2) {
                        Text("\(Int(score))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: viewModel.currentLevel.colorHex))
                        Text(viewModel.currentLevel.label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 4) {
                        ProgressView()
                        Text("基线学习中...")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("已采集 \(viewModel.sampleCount) 条")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }

                if let hrv = viewModel.currentHRV, let baseline = viewModel.baseline {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HRV").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text("\(Int(hrv)) ms").font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("基线").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text("\(Int(baseline)) ms").font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 8)
                }

                MiniTrendChart(samples: viewModel.recentSnapshots)
                    .frame(height: 60)
                    .padding(.horizontal, -4)

                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)

                    NavigationLink {
                        WatchSettingsView(viewModel: viewModel)
                    } label: {
                        Label("设置", systemImage: "gearshape")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("压力")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.currentLevel) { _, newLevel in
            switch newLevel {
            case .explode:   WKInterfaceDevice.current().play(.notification)
            case .stressed:  WKInterfaceDevice.current().play(.directionUp)
            case .tense:     WKInterfaceDevice.current().play(.click)
            default: break
            }
        }
    }
}

struct MiniTrendChart: View {
    let samples: [StressSnapshot]

    var body: some View {
        if samples.count < 2 {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .overlay(Text("暂无趋势数据").font(.system(size: 11)).foregroundStyle(.tertiary))
        } else {
            Chart(samples) { s in
                AreaMark(x: .value("时间", s.timestamp), y: .value("压力", s.score))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: s.level.colorHex).opacity(0.6), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                LineMark(x: .value("时间", s.timestamp), y: .value("压力", s.score))
                    .foregroundStyle(Color(hex: s.level.colorHex))
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
    }
}
