//
//  DashboardView.swift
//  iOS/Views
//
//  iPhone 端主界面：大号表情 + 环形仪表 + 24h 曲线
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var viewModel: iOSDashboardViewModel
    @EnvironmentObject var health: HealthKitManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 主表情
                    VStack(spacing: 12) {
                        Text(viewModel.emoji(for: viewModel.currentLevel))
                            .font(.system(size: 140))
                            .shadow(color: Color(hex: viewModel.currentLevel.colorHex).opacity(0.5), radius: 20)

                        if let score = viewModel.currentScore {
                            Text("\(Int(score))")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: viewModel.currentLevel.colorHex))
                            Text(viewModel.currentLevel.label)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("基线学习中...")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("已采集 \(viewModel.sampleCount) / 20 条")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.top, 24)

                    // HRV 详情卡片
                    HStack(spacing: 12) {
                        StatCard(title: "当前 HRV", value: viewModel.currentHRV.map { "\(Int($0)) ms" } ?? "--", color: "#5AC8FA")
                        StatCard(title: "个人基线", value: viewModel.baseline.map { "\(Int($0)) ms" } ?? "--", color: "#4CD964")
                        StatCard(title: "样本数", value: "\(viewModel.sampleCount)", color: "#FF9500")
                    }
                    .padding(.horizontal)

                    // 24h 曲线
                    if !viewModel.recentSnapshots.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最近 24 小时")
                                .font(.headline)
                                .padding(.horizontal)
                            Chart(viewModel.recentSnapshots) { s in
                                LineMark(
                                    x: .value("时间", s.timestamp),
                                    y: .value("压力", s.score)
                                )
                                .foregroundStyle(Color(hex: s.level.colorHex))
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("时间", s.timestamp),
                                    y: .value("压力", s.score)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: s.level.colorHex).opacity(0.4), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                            }
                            .chartYScale(domain: 0...100)
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                    }

                    // 刷新按钮
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("刷新数据", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("HRV 压力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                            .environmentObject(viewModel)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: color))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 简易设置页占位（Week 3 完善）
struct SettingsView: View {
    @EnvironmentObject var viewModel: iOSDashboardViewModel

    var body: some View {
        Form {
            Section("基线设置") {
                Picker("窗口", selection: $viewModel.baselineDays) {
                    Text("7 天").tag(7)
                    Text("14 天").tag(14)
                    Text("30 天").tag(30)
                }
                .onChange(of: viewModel.baselineDays) { _, _ in
                    Task { await viewModel.refresh() }
                }
            }
            Section("表情自定义") {
                ForEach(StressLevel.allCases, id: \.rawValue) { level in
                    HStack {
                        Text(level.label)
                        Spacer()
                        TextField("emoji", text: Binding(
                            get: { viewModel.customEmojis[level] ?? level.defaultEmoji },
                            set: { viewModel.customEmojis[level] = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    }
                }
            }
            Section("关于") {
                LabeledContent("版本", value: "0.1.0")
                LabeledContent("HealthKit", value: viewModel.healthAuthorized ? "已授权" : "未授权")
            }
        }
        .navigationTitle("设置")
    }
}

// MARK: - Hex Color 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
