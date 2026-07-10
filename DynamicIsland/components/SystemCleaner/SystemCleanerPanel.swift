import SwiftUI
import AppKit
import Defaults

// MARK: - Panel Manager

final class SystemCleanerPanelManager: ObservableObject {
    static let shared = SystemCleanerPanelManager()
    private var panel: SystemCleanerPanel?

    private init() {}

    func show() {
        hide()
        let p = SystemCleanerPanel()
        panel = p
        p.positionCenter()
        p.makeKeyAndOrderFront(nil)
        p.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { p.makeKey() }
    }

    func hide() {
        panel?.close()
        panel = nil
    }

    func toggle() {
        panel?.isVisible == true ? hide() : show()
    }
}

// MARK: - NSPanel

private func applyCleanerCornerMask(_ view: NSView) {
    view.wantsLayer = true
    view.layer?.masksToBounds = true
    view.layer?.cornerRadius = 16
    view.layer?.backgroundColor = NSColor.clear.cgColor
    if #available(macOS 13.0, *) {
        view.layer?.cornerCurve = .continuous
    }
}

final class SystemCleanerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: true)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true
        styleMask.insert(.fullSizeContentView)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        ScreenCaptureVisibilityManager.shared.register(self, scope: .panelsOnly)
        acceptsMouseMovedEvents = true

        let hosting = NSHostingView(rootView: SystemCleanerView())
        applyCleanerCornerMask(hosting)
        contentView = hosting
        let size = CGSize(width: 520, height: 500)
        hosting.setFrameSize(size)
        setContentSize(size)
    }

    func positionCenter() {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        setFrameOrigin(NSPoint(x: (sf.width - frame.width) / 2 + sf.minX,
                               y: (sf.height - frame.height) / 2 + sf.minY))
    }

    deinit {
        ScreenCaptureVisibilityManager.shared.unregister(self)
    }
}

// MARK: - Main View

struct SystemCleanerView: View {
    @StateObject private var manager = SystemCleanerManager.shared
    @State private var selectedTab: CleanerTab = .cache
    @State private var selectAll = true

    enum CleanerTab: String, CaseIterable { case cache = "缓存清理", process = "进程管理" }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider().background(Color.gray.opacity(0.2))
            tabPicker
            Divider().background(Color.gray.opacity(0.2))
            if selectedTab == .cache { cacheTab } else { processTab }
            statusBar
        }
        .background(CleanerVisualEffect(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            NativeStyleCloseButton { SystemCleanerPanelManager.shared.hide() }
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .medium)).foregroundColor(.blue)
                Text("系统清理").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
            }
            Spacer()
            if selectedTab == .cache {
                Button(action: { Task { await manager.scanCaches() } }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 12, weight: .medium))
                        Text("重新扫描").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.blue).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1)).cornerRadius(7)
                }.buttonStyle(PlainButtonStyle()).disabled(manager.isScanning)
            } else {
                Button(action: { Task { await manager.scanProcesses() } }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 12, weight: .medium))
                        Text("刷新").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.blue).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1)).cornerRadius(7)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.gray.opacity(0.04))
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(CleanerTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .cache ? "folder.badge.minus" : "cpu").font(.system(size: 12))
                        Text(tab.rawValue).font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(selectedTab == tab ? Color.blue.opacity(0.8) : Color.clear))
                }.buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
    }

    // MARK: - Cache Tab

    private var cacheTab: some View {
        VStack(spacing: 0) {
            if manager.isScanning {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView().scaleEffect(1.2)
                    Text("正在扫描系统缓存...").font(.system(size: 14)).foregroundColor(.secondary)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.cacheEntries.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "sparkles").font(.system(size: 36)).foregroundColor(.blue.opacity(0.6))
                    Text("点击扫描分析系统缓存").font(.system(size: 14)).foregroundColor(.secondary)
                    Button("立即扫描") { Task { await manager.scanCaches() } }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                cacheList
            }
        }
    }

    private var cacheList: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    let allSelected = manager.cacheEntries.allSatisfy { $0.isSelected }
                    for i in manager.cacheEntries.indices {
                        manager.cacheEntries[i].isSelected = !allSelected
                    }
                    if let first = manager.cacheEntries.first {
                        manager.toggleSelection(for: first)
                    }
                }) {
                    Text(manager.cacheEntries.allSatisfy { $0.isSelected } ? "取消全选" : "全选")
                        .font(.system(size: 12)).foregroundColor(.blue)
                }.buttonStyle(PlainButtonStyle())
                Spacer()
                Text("共 \(ByteCountFormatter.string(fromByteCount: Int64(manager.totalCacheSize), countStyle: .file))")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 6)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(manager.cacheEntries) { entry in
                        CacheRowView(entry: entry, onToggle: { manager.toggleSelection(for: entry) })
                    }
                }.padding(.horizontal, 12).padding(.bottom, 8)
            }

            if manager.selectedCacheSize > 0 {
                Divider().background(Color.gray.opacity(0.2))
                HStack {
                    Text("选中: \(ByteCountFormatter.string(fromByteCount: Int64(manager.selectedCacheSize), countStyle: .file))")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                    Spacer()
                    Button(action: { Task { await manager.cleanSelected() } }) {
                        HStack(spacing: 6) {
                            if manager.isCleaning {
                                ProgressView().scaleEffect(0.7).tint(.white)
                            } else {
                                Image(systemName: "trash").font(.system(size: 12))
                            }
                            Text(manager.isCleaning ? "清理中..." : "清理选中").font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 7)
                        .background(manager.isCleaning ? Color.gray : Color.red.opacity(0.85)).cornerRadius(8)
                    }.buttonStyle(PlainButtonStyle()).disabled(manager.isCleaning)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    // MARK: - Process Tab

    private var processTab: some View {
        VStack(spacing: 0) {
            if manager.processEntries.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "cpu").font(.system(size: 36)).foregroundColor(.blue.opacity(0.6))
                    Text("点击刷新扫描运行中的进程").font(.system(size: 14)).foregroundColor(.secondary)
                    Button("刷新进程列表") { Task { await manager.scanProcesses() } }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Text("进程").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("CPU").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).frame(width: 50)
                    Text("内存").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).frame(width: 70)
                    Text("PID").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).frame(width: 50)
                    Text("").font(.system(size: 11)).frame(width: 40)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
                Divider().background(Color.gray.opacity(0.15))
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(manager.processEntries) { proc in
                            ProcessRowView(entry: proc, onKill: { manager.killProcess(proc) })
                        }
                    }
                }
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if let time = manager.lastScanTime {
                Image(systemName: "clock").font(.system(size: 10)).foregroundColor(.secondary)
                Text("上次扫描: \(time, style: .time)").font(.system(size: 11)).foregroundColor(.secondary)
            }
            Spacer()
            Text("Atoll 系统工具").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(Color.gray.opacity(0.03))
    }
}

// MARK: - Cache Row

struct CacheRowView: View {
    let entry: CacheEntry
    let onToggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(get: { entry.isSelected }, set: { _ in onToggle() }))
                .toggleStyle(.checkbox).scaleEffect(0.85)

            Image(systemName: categoryIcon)
                .font(.system(size: 12)).foregroundColor(categoryColor).frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.system(size: 13)).foregroundColor(.primary).lineLimit(1)
                Text(entry.path).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Text(entry.sizeFormatted)
                .font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.secondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(isHovered ? Color.white.opacity(0.05) : Color.clear))
        .onHover { isHovered = $0 }
    }

    private var categoryIcon: String {
        switch entry.category {
        case .user: return "doc"
        case .system: return "gearshape.2"
        case .xcode: return "hammer"
        case .logs: return "list.bullet.rectangle"
        case .trash: return "trash"
        }
    }

    private var categoryColor: Color {
        switch entry.category {
        case .user: return .blue
        case .system: return .orange
        case .xcode: return .indigo
        case .logs: return .gray
        case .trash: return .red
        }
    }
}

// MARK: - Process Row

struct ProcessRowView: View {
    let entry: ProcessEntry
    let onKill: () -> Void
    @State private var isHovered = false
    @State private var showConfirm = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.system(size: 13, weight: .medium)).foregroundColor(.primary).lineLimit(1)
                Text(entry.user).font(.system(size: 10)).foregroundColor(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.cpuFormatted)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(entry.cpuPercent > 50 ? .red : .secondary).frame(width: 50, alignment: .trailing)

            Text(entry.memoryFormatted)
                .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary).frame(width: 70, alignment: .trailing)

            Text("\(entry.pid)")
                .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary.opacity(0.7)).frame(width: 50, alignment: .trailing)

            Button(action: { showConfirm = true }) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundColor(.red.opacity(isHovered ? 1 : 0.6))
            }.buttonStyle(PlainButtonStyle()).frame(width: 40)
            .popover(isPresented: $showConfirm, arrowEdge: .leading) {
                VStack(spacing: 12) {
                    Text("确认结束进程?").font(.system(size: 13, weight: .semibold))
                    Text("\(entry.name) (PID \(entry.pid))").font(.system(size: 12)).foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        Button("取消") { showConfirm = false }.buttonStyle(.bordered).controlSize(.small)
                        Button("强制结束") { onKill(); showConfirm = false }
                            .buttonStyle(.borderedProminent).controlSize(.small).tint(.red)
                    }
                }.padding(16).frame(width: 220)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 7).fill(isHovered ? Color.white.opacity(0.05) : Color.clear))
        .onHover { isHovered = $0 }
    }
}

// MARK: - Visual Effect

struct CleanerVisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material; v.blendingMode = blendingMode; v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}
