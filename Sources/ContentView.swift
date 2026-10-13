import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var practice = ""
    private let blue = Color(red: 0.13, green: 0.46, blue: 0.79)

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable().interpolation(.high).frame(width: 88, height: 88)
                    .scaleEffect(model.pulse ? 1.055 : 1)
                    .animation(.easeOut(duration: 0.12), value: model.pulse)
                Text("冰键").font(.system(size: 29, weight: .semibold, design: .rounded))
            }
            HStack(spacing: 12) {
                Image(systemName: model.enabled ? "waveform" : "pause.fill")
                    .font(.system(size: 18, weight: .medium)).foregroundStyle(blue)
                    .frame(width: 38, height: 38).background(blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text("键盘音效").font(.system(size: 15, weight: .semibold))
                    HStack(spacing: 5) {
                        Circle().fill(model.globallyListening ? Color.green : Color.gray.opacity(0.6)).frame(width: 5, height: 5)
                        Text(model.status).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Toggle("键盘音效", isOn: Binding(get: { model.enabled }, set: { model.setEnabled($0) }))
                    .labelsHidden().toggleStyle(.switch).tint(blue).accessibilityLabel("启用键盘音效")
            }.padding(17).card()

            VStack(spacing: 17) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("冰块轻响").font(.system(size: 14, weight: .semibold))
                        Text("你的专属音效 · 0.67 秒").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: model.preview) { Label("试听", systemImage: "play.fill").font(.system(size: 12, weight: .medium)).padding(.horizontal, 5).padding(.vertical, 3) }
                        .buttonStyle(.bordered).tint(blue)
                }
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                    Slider(value: $model.volume, in: 0...1).tint(blue).accessibilityLabel("音效音量")
                    Text("\(Int(model.volume * 100))%").font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary).frame(width: 34, alignment: .trailing)
                }
                Divider().opacity(0.6)
                Toggle("长按按键时连续播放", isOn: $model.repeatKeys)
                    .font(.system(size: 12)).toggleStyle(.switch).controlSize(.small).tint(blue)
            }.padding(18).card()

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("试着敲几下").font(.system(size: 12, weight: .medium))
                    Spacer()
                    if !practice.isEmpty { Button("清空") { practice = "" }.buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(blue) }
                }
                TextField(model.enabled ? "在这里输入，听听冰块的声音…" : "开启音效后，在这里试试…", text: $practice)
                    .textFieldStyle(.plain).font(.system(size: 13)).padding(13)
                    .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(blue.opacity(0.12)))
                    .onChange(of: practice) { _, value in if value.count > 200 { practice = String(value.suffix(200)) } }
            }

            if !model.hasPermission || model.connectionFailed {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "keyboard.badge.ellipsis").font(.system(size: 17)).foregroundStyle(blue).padding(.top, 2)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(model.connectionFailed ? "输入监控暂未连接" : "在所有 App 中播放")
                            .font(.system(size: 12, weight: .semibold))
                        Text(model.connectionFailed ? "权限已开启。请重新连接；若仍无响应，请退出并重新打开冰键。" : "允许“输入监控”后，在其他 App 中打字也能听见音效。授权前可以在上方试打。")
                            .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 14) {
                            Button("打开权限设置", action: model.authorize)
                            Button("重新连接") { model.refreshPermission(force: true) }
                        }.buttonStyle(.plain).font(.system(size: 11, weight: .medium)).foregroundStyle(blue)
                    }
                }.padding(13).frame(maxWidth: .infinity, alignment: .leading)
                    .background(blue.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Label("输入监控已授权", systemImage: "checkmark.shield")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let error = model.audioError {
                Text("音频暂不可用：\(error)").font(.system(size: 11)).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28).padding(.top, 34).padding(.bottom, 20)
        .frame(width: 460, height: 740)
        .background(LinearGradient(colors: [Color(red: 0.90, green: 0.96, blue: 1), Color(red: 0.97, green: 0.985, blue: 1), .white], startPoint: .topLeading, endPoint: .bottomTrailing))
        .preferredColorScheme(.light)
    }
}

private extension View {
    func card() -> some View {
        self.background(.white.opacity(0.83), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.95)))
            .shadow(color: Color.blue.opacity(0.035), radius: 12, x: 0, y: 5)
    }
}
