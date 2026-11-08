//
//  WatchSettingsView.swift
//  watchOS/Views
//

import SwiftUI

struct WatchSettingsView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        Form {
            Section("表情自定义") {
                ForEach(StressLevel.allCases, id: \.rawValue) { level in
                    HStack {
                        Text(level.label).font(.system(size: 14))
                        Spacer()
                        TextField("emoji", text: Binding(
                            get: { viewModel.customEmojis[level] ?? level.defaultEmoji },
                            set: { viewModel.customEmojis[level] = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                    }
                }
            }
            Section("关于") {
                LabeledContent("版本", value: "0.1.0")
                LabeledContent("样本", value: "\(viewModel.sampleCount)")
            }
        }
        .navigationTitle("设置")
    }
}
