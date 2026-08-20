import Cocoa
import Foundation
import SQLite3
import QuartzCore
import ServiceManagement

// MARK: - Session Model & Metrics
struct OpencodeSession {
    let id: String
    let title: String
    let timeUpdated: Int64
    let modelID: String?
    let providerID: String?
    let cost: Double
    let tokensInput: Int64
    let tokensOutput: Int64
    let recentTool: String?
    let modelSwitch: String?
}

// MARK: - Session State Enum
enum SessionState {
    case inactive
    case idle      // 就绪
    case thinking  // 思考
    case working   // 工作
    case compacting
    case error     // 报错
    
    var baseColor: NSColor {
        get {
            let key = "Color_\(self)"
            if let data = UserDefaults.standard.data(forKey: key),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
                return color
            }
            switch self {
            case .inactive: return NSColor.systemGray
            case .idle:     return NSColor.systemGreen
            case .thinking: return NSColor.systemCyan
            case .working:  return NSColor.systemPurple
            case .compacting: return NSColor.systemOrange
            case .error:    return NSColor.systemRed
            }
        }
        set {
            let key = "Color_\(self)"
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}

// MARK: - Settings Manager
class SettingsManager {
    static let shared = SettingsManager()
    
    var barWidth: CGFloat {
        get { UserDefaults.standard.object(forKey: "BarWidth") as? CGFloat ?? 280 }
        set { UserDefaults.standard.set(newValue, forKey: "BarWidth") }
    }
    
    var barHeight: CGFloat {
        get { UserDefaults.standard.object(forKey: "BarHeight") as? CGFloat ?? 12 }
        set { UserDefaults.standard.set(newValue, forKey: "BarHeight") }
    }
    
    var barOpacity: Double {
        get { UserDefaults.standard.object(forKey: "BarOpacity") as? Double ?? 0.9 }
        set { UserDefaults.standard.set(newValue, forKey: "BarOpacity") }
    }
    
    var zenMode: Bool {
        get { UserDefaults.standard.bool(forKey: "ZenMode") }
        set { UserDefaults.standard.set(newValue, forKey: "ZenMode") }
    }
    
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }

    var autoStartAPIService: Bool {
        get { UserDefaults.standard.bool(forKey: "AutoStartAPIService") }
        set { UserDefaults.standard.set(newValue, forKey: "AutoStartAPIService") }
    }
    
    var contextLimit: Double {
        get {
            let val = UserDefaults.standard.double(forKey: "ContextLimit")
            return val > 0 ? val : 800000.0
        }
        set { UserDefaults.standard.set(newValue, forKey: "ContextLimit") }
    }
    
    var miniMode: Bool {
        get { UserDefaults.standard.bool(forKey: "MiniMode") }
        set { UserDefaults.standard.set(newValue, forKey: "MiniMode") }
    }
    
    var archiveDays: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "ArchiveDays")
            return val > 0 ? val : 7
        }
        set { UserDefaults.standard.set(newValue, forKey: "ArchiveDays") }
    }
    
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "BarWidth")
        UserDefaults.standard.removeObject(forKey: "BarHeight")
        UserDefaults.standard.removeObject(forKey: "BarOpacity")
        UserDefaults.standard.removeObject(forKey: "ZenMode")
        UserDefaults.standard.removeObject(forKey: "ContextLimit")
        UserDefaults.standard.removeObject(forKey: "MiniMode")
        UserDefaults.standard.removeObject(forKey: "ArchiveDays")
        UserDefaults.standard.removeObject(forKey: "AutoStartAPIService")
        for state in [SessionState.inactive, .idle, .thinking, .working, .compacting, .error] {
            UserDefaults.standard.removeObject(forKey: "Color_\(state)")
        }
    }
}

// MARK: - Onboarding / Tutorial Tip Window
class OnboardingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "欢迎使用 OpenCodeMonitor"
        window.center()
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let window = self.window else { return }
        
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = NSVisualEffectView.Material.hudWindow
        visualEffect.state = NSVisualEffectView.State.active
        visualEffect.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        window.contentView = visualEffect
        
        let container = NSView(frame: visualEffect.bounds)
        container.autoresizingMask = [.width, .height]
        visualEffect.addSubview(container)
        
        let title = NSTextField(labelWithString: "快速上手指南 (桌宠模式已开启)")
        title.font = NSFont.boldSystemFont(ofSize: 16)
        title.frame = NSRect(x: 40, y: 310, width: 400, height: 24)
        container.addSubview(title)
        
        let tips = """
        1. 桌面宠物交互：直接点击底部的状态胶囊条，它会在右上角随机吐出一个手写风格的颜表情或萌趣符号！
        2. 菜单栏图标：点击顶部菜单栏图标可随时切换监控的 OpenCode 会话。
        3. 悬浮详情 (HUD)：将鼠标悬停在底部指示条上，即可实时查看 Token 消耗、模型与费用。
        4. 庆祝彩带：当 AI 成功完成一项任务时，底部会自动绽放微型庆祝粒子！
        5. 偏好设置：通过菜单栏或右键打开设置，可自定义宽度、透明度、开机启动及状态颜色。
        """
        
        let textView = NSTextField(wrappingLabelWithString: tips)
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = .secondaryLabelColor
        textView.frame = NSRect(x: 40, y: 100, width: 400, height: 190)
        container.addSubview(textView)
        
        let okButton = NSButton(title: "开始使用", target: self, action: #selector(closeWindow))
        okButton.bezelStyle = .rounded
        okButton.frame = NSRect(x: 340, y: 30, width: 100, height: 32)
        container.addSubview(okButton)
    }
    
    @objc private func closeWindow() {
        self.close()
        UserDefaults.standard.set(true, forKey: "HasShownOnboarding")
    }
}

// MARK: - Settings Window
class SettingsWindowController: NSWindowController {
    private var widthLabel: NSTextField!
    private var opacityLabel: NSTextField!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OpenCodeMonitor 偏好设置"
        window.minSize = NSSize(width: 460, height: 500)
        window.center()
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let window = self.window else { return }
        
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = NSVisualEffectView.Material.hudWindow
        visualEffect.state = NSVisualEffectView.State.active
        visualEffect.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        window.contentView = visualEffect
        
        let scrollView = NSScrollView(frame: visualEffect.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        visualEffect.addSubview(scrollView)

        let contentHeight: CGFloat = 680
        let container = NSView(frame: NSRect(x: 0, y: 0, width: visualEffect.bounds.width, height: contentHeight))
        container.autoresizingMask = [.width]
        scrollView.documentView = container
        
        var y: CGFloat = contentHeight - 70
        
        let loginCheckbox = NSButton(checkboxWithTitle: "开机自动启动", target: nil, action: #selector(loginToggled(_:)))
        loginCheckbox.frame = NSRect(x: 40, y: y, width: 300, height: 24)
        loginCheckbox.state = SettingsManager.shared.launchAtLogin ? .on : .off
        loginCheckbox.target = self
        container.addSubview(loginCheckbox)
        
        y -= 35

        let apiServiceCheckbox = NSButton(checkboxWithTitle: "启动时自动开启 OpenCode API 服务", target: nil, action: #selector(apiServiceToggled(_:)))
        apiServiceCheckbox.frame = NSRect(x: 40, y: y, width: 340, height: 24)
        apiServiceCheckbox.state = SettingsManager.shared.autoStartAPIService ? .on : .off
        apiServiceCheckbox.target = self
        container.addSubview(apiServiceCheckbox)

        y -= 45
        
        let zenCheckbox = NSButton(checkboxWithTitle: "全屏时自动隐藏 (专注模式)", target: nil, action: #selector(zenToggled(_:)))
        zenCheckbox.frame = NSRect(x: 40, y: y, width: 300, height: 24)
        zenCheckbox.state = SettingsManager.shared.zenMode ? .on : .off
        zenCheckbox.target = self
        container.addSubview(zenCheckbox)
        
        y -= 35
        
        let miniCheckbox = NSButton(checkboxWithTitle: "Mini 悬浮球模式 (小圆点)", target: nil, action: #selector(miniToggled(_:)))
        miniCheckbox.frame = NSRect(x: 40, y: y, width: 300, height: 24)
        miniCheckbox.state = SettingsManager.shared.miniMode ? .on : .off
        miniCheckbox.target = self
        container.addSubview(miniCheckbox)
        
        y -= 35
        
        let archiveLabel = NSTextField(labelWithString: "Session 归档天数:")
        archiveLabel.font = NSFont.systemFont(ofSize: 12)
        archiveLabel.frame = NSRect(x: 40, y: y + 4, width: 120, height: 20)
        container.addSubview(archiveLabel)
        
        let archivePopup = NSPopUpButton(frame: NSRect(x: 170, y: y, width: 100, height: 26))
        let archiveDays = SettingsManager.shared.archiveDays
        let archiveOptions: [(String, Int)] = [("3 天", 3), ("7 天", 7), ("14 天", 14), ("30 天", 30), ("永不", 999)]
        for (label, value) in archiveOptions {
            archivePopup.addItem(withTitle: label)
            archivePopup.lastItem?.representedObject = value
            if value == archiveDays {
                archivePopup.selectItem(at: archivePopup.numberOfItems - 1)
            }
        }
        archivePopup.target = self
        archivePopup.action = #selector(archiveDaysChanged(_:))
        container.addSubview(archivePopup)
        
        y -= 45
        
        widthLabel = NSTextField(labelWithString: "指示条宽度: \(Int(SettingsManager.shared.barWidth)) px")
        widthLabel.frame = NSRect(x: 40, y: y + 22, width: 300, height: 20)
        container.addSubview(widthLabel)
        
        let widthSlider = NSSlider(value: Double(SettingsManager.shared.barWidth), minValue: 150, maxValue: 500, target: self, action: #selector(widthChanged(_:)))
        widthSlider.frame = NSRect(x: 40, y: y, width: 380, height: 24)
        container.addSubview(widthSlider)
        
        y -= 55
        
        opacityLabel = NSTextField(labelWithString: "指示条透明度: \(Int(SettingsManager.shared.barOpacity * 100))%")
        opacityLabel.frame = NSRect(x: 40, y: y + 22, width: 300, height: 20)
        container.addSubview(opacityLabel)
        
        let opacitySlider = NSSlider(value: SettingsManager.shared.barOpacity, minValue: 0.3, maxValue: 1.0, target: self, action: #selector(opacityChanged(_:)))
        opacitySlider.frame = NSRect(x: 40, y: y, width: 380, height: 24)
        container.addSubview(opacitySlider)
        
        y -= 55
        
        let contextLabel = NSTextField(labelWithString: "上下文窗口限制:")
        contextLabel.font = NSFont.systemFont(ofSize: 12)
        contextLabel.frame = NSRect(x: 40, y: y + 4, width: 120, height: 20)
        container.addSubview(contextLabel)
        
        let contextPopup = NSPopUpButton(frame: NSRect(x: 170, y: y, width: 150, height: 26))
        let contextLimit = SettingsManager.shared.contextLimit
        let contextOptions: [(String, Double)] = [
            ("32k", 32000), ("64k", 64000), ("128k", 128000),
            ("200k", 200000), ("400k", 400000), ("800k", 800000),
            ("1M", 1000000), ("2M", 2000000)
        ]
        for (label, value) in contextOptions {
            contextPopup.addItem(withTitle: label)
            contextPopup.lastItem?.representedObject = value
            if abs(value - contextLimit) < 1000 {
                contextPopup.selectItem(at: contextPopup.numberOfItems - 1)
            }
        }
        contextPopup.target = self
        contextPopup.action = #selector(contextLimitChanged(_:))
        container.addSubview(contextPopup)
        
        y -= 60
        
        let colorTitle = NSTextField(labelWithString: "自定义状态颜色:")
        colorTitle.font = NSFont.boldSystemFont(ofSize: 12)
        colorTitle.frame = NSRect(x: 40, y: y, width: 120, height: 20)
        container.addSubview(colorTitle)
        
        y -= 35
        addColorWell(to: container, label: "就绪 (绿):", state: .idle, x: 40, y: y)
        addColorWell(to: container, label: "思考 (青):", state: .thinking, x: 240, y: y)
        
        y -= 35
        addColorWell(to: container, label: "工作 (紫):", state: .working, x: 40, y: y)
        addColorWell(to: container, label: "报错 (红):", state: .error, x: 240, y: y)
        
        y -= 55
        
        let resetButton = NSButton(title: "恢复默认设置", target: self, action: #selector(resetClicked(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 40, y: y, width: 120, height: 32)
        container.addSubview(resetButton)

        scrollView.contentView.scroll(to: NSPoint(x: 0, y: max(contentHeight - visualEffect.bounds.height, 0)))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
    
    private func addColorWell(to container: NSView, label: String, state: SessionState, x: CGFloat, y: CGFloat) {
        let lbl = NSTextField(labelWithString: label)
        lbl.frame = NSRect(x: x, y: y + 4, width: 80, height: 18)
        container.addSubview(lbl)
        
        let well = NSColorWell(frame: NSRect(x: x + 85, y: y, width: 50, height: 26))
        well.color = state.baseColor
        well.target = self
        well.action = #selector(colorChanged(_:))
        well.tag = hashForState(state)
        container.addSubview(well)
    }
    
    private func hashForState(_ state: SessionState) -> Int {
        switch state {
        case .inactive: return 0
        case .idle: return 1
        case .thinking: return 2
        case .working: return 3
        case .compacting: return 5
        case .error: return 4
        }
    }
    
    private func stateForHash(_ hash: Int) -> SessionState {
        switch hash {
        case 1: return .idle
        case 2: return .thinking
        case 3: return .working
        case 4: return .error
        case 5: return .compacting
        default: return .inactive
        }
    }
    
    @objc private func loginToggled(_ sender: NSButton) {
        SettingsManager.shared.launchAtLogin = (sender.state == .on)
    }

    @objc private func apiServiceToggled(_ sender: NSButton) {
        SettingsManager.shared.autoStartAPIService = (sender.state == .on)
    }
    
    @objc private func zenToggled(_ sender: NSButton) {
        SettingsManager.shared.zenMode = (sender.state == .on)
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    @objc private func miniToggled(_ sender: NSButton) {
        SettingsManager.shared.miniMode = (sender.state == .on)
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    @objc private func archiveDaysChanged(_ sender: NSPopUpButton) {
        if let value = sender.selectedItem?.representedObject as? Int {
            SettingsManager.shared.archiveDays = value
            NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        }
    }
    
    @objc private func widthChanged(_ sender: NSSlider) {
        let val = CGFloat(sender.intValue)
        SettingsManager.shared.barWidth = val
        widthLabel.stringValue = "指示条宽度: \(Int(val)) px"
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    @objc private func opacityChanged(_ sender: NSSlider) {
        let val = sender.doubleValue
        SettingsManager.shared.barOpacity = val
        opacityLabel.stringValue = "指示条透明度: \(Int(val * 100))%"
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    @objc private func contextLimitChanged(_ sender: NSPopUpButton) {
        if let value = sender.selectedItem?.representedObject as? Double {
            SettingsManager.shared.contextLimit = value
            NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
        }
    }
    
    @objc private func colorChanged(_ sender: NSColorWell) {
        let state = stateForHash(sender.tag)
        var s = state
        s.baseColor = sender.color
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    @objc private func resetClicked(_ sender: NSButton) {
        SettingsManager.shared.resetToDefaults()
        self.close()
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
}

// MARK: - HUD Hover Details Panel
class HoverHUDWindow: NSWindow {
    init() {
        let rect = NSRect(x: 0, y: 0, width: 300, height: 210)
        super.init(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let visualEffect = NSVisualEffectView(frame: rect)
        visualEffect.material = NSVisualEffectView.Material.hudWindow
        visualEffect.state = NSVisualEffectView.State.active
        visualEffect.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true
        self.contentView = visualEffect
    }
    
    func updateContent(title: String, model: String, cost: Double, inputTokens: Int, outputTokens: Int, durationSeconds: Int, recentTool: String? = nil, modelSwitch: String? = nil) {
        guard let view = self.contentView else { return }
        view.subviews.forEach { v in v.removeFromSuperview() }
        
        let stack = NSStackView(frame: view.bounds.insetBy(dx: 16, dy: 12))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        view.addSubview(stack)
        
        let titleLabel = NSTextField(labelWithString: "会话: \(title)")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 12)
        titleLabel.textColor = .labelColor
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.toolTip = title
        titleLabel.frame.size.width = 268
        stack.addArrangedSubview(titleLabel)
        
        let modelLabel = NSTextField(labelWithString: "模型: \(model)")
        modelLabel.font = NSFont.systemFont(ofSize: 11)
        modelLabel.textColor = .secondaryLabelColor
        modelLabel.maximumNumberOfLines = 1
        modelLabel.lineBreakMode = .byTruncatingMiddle
        modelLabel.toolTip = model
        modelLabel.frame.size.width = 268
        stack.addArrangedSubview(modelLabel)

        if let modelSwitch = modelSwitch {
            let switchLabel = NSTextField(labelWithString: "模型切换: \(modelSwitch)")
            switchLabel.font = NSFont.systemFont(ofSize: 10)
            switchLabel.textColor = .systemPurple
            switchLabel.maximumNumberOfLines = 1
            switchLabel.lineBreakMode = .byTruncatingMiddle
            switchLabel.toolTip = modelSwitch
            switchLabel.frame.size.width = 268
            stack.addArrangedSubview(switchLabel)
        }

        if let recentTool = recentTool {
            let toolLabel = NSTextField(labelWithString: "最近工具: \(recentTool)")
            toolLabel.font = NSFont.systemFont(ofSize: 10)
            toolLabel.textColor = .systemCyan
            toolLabel.maximumNumberOfLines = 1
            toolLabel.lineBreakMode = .byTruncatingMiddle
            toolLabel.toolTip = recentTool
            toolLabel.frame.size.width = 268
            stack.addArrangedSubview(toolLabel)
        }
        
        let contextTokens = inputTokens
        let contextLabel2 = NSTextField(labelWithString: "上下文占用: \(contextTokens) tokens")
        contextLabel2.font = NSFont.systemFont(ofSize: 10)
        contextLabel2.textColor = .tertiaryLabelColor
        stack.addArrangedSubview(contextLabel2)
        
        let costText = "N/A (自定义 Provider)"
        let costLabel = NSTextField(labelWithString: "费用: \(costText) | 耗时: \(durationSeconds / 60)分\(durationSeconds % 60)秒")
        costLabel.font = NSFont.systemFont(ofSize: 11)
        costLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(costLabel)
        
        let progressContainer = NSView(frame: NSRect(x: 0, y: 0, width: 268, height: 16))
        let bgBar = NSBox(frame: progressContainer.bounds)
        bgBar.boxType = .custom
        bgBar.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5)
        bgBar.cornerRadius = 4
        bgBar.borderWidth = 0
        progressContainer.addSubview(bgBar)
        
        let maxContext = SettingsManager.shared.contextLimit
        let fillRatio = min(Double(contextTokens) / maxContext, 1.0)
        
        let fillWidth = CGFloat(fillRatio) * 268
        let fillBar = NSBox(frame: NSRect(x: 0, y: 0, width: max(fillWidth, 4), height: 16))
        fillBar.boxType = .custom
        fillBar.fillColor = fillRatio > 0.8 ? .systemRed : .systemCyan
        fillBar.cornerRadius = 4
        fillBar.borderWidth = 0
        progressContainer.addSubview(fillBar)
        
        let ctxLimitK = Int(maxContext / 1000)
        let ctxLabel = NSTextField(labelWithString: "上下文占用: \(Int(fillRatio * 100))% (\(ctxLimitK)k Limit)")
        ctxLabel.font = NSFont.systemFont(ofSize: 9)
        ctxLabel.textColor = .secondaryLabelColor
        
        stack.addArrangedSubview(progressContainer)
        stack.addArrangedSubview(ctxLabel)
    }
}

// MARK: - Floating Handwritten Kaomoji Bubble Window (Desktop Pet Feature)
class PetBubbleWindow: NSWindow {
    init(text: String, at point: CGPoint) {
        let rect = NSRect(x: point.x - 30, y: point.y + 2, width: 80, height: 30)
        super.init(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        
        let label = NSTextField(labelWithString: text)
        let handwritingFont = NSFont(name: "Noteworthy-Bold", size: 16) ?? NSFont.systemFont(ofSize: 16, weight: .regular)
        label.font = handwritingFont
        label.textColor = .systemYellow
        label.alignment = .center
        label.frame = rect
        
        let shadow = NSShadow()
        shadow.shadowColor = .black
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 1, height: -1)
        label.shadow = shadow
        
        self.contentView = label
    }
}

// MARK: - Compaction Warning HUD Window
class CompactionHUDWindow: NSWindow {
    init() {
        let rect = NSRect(x: 0, y: 0, width: 280, height: 60)
        super.init(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let visualEffect = NSVisualEffectView(frame: rect)
        visualEffect.material = NSVisualEffectView.Material.hudWindow
        visualEffect.state = NSVisualEffectView.State.active
        visualEffect.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        self.contentView = visualEffect
    }
    
    func updateContent(beforeTokens: Int, afterTokens: Int) {
        guard let view = self.contentView else { return }
        view.subviews.forEach { v in v.removeFromSuperview() }
        
        let stack = NSStackView(frame: view.bounds.insetBy(dx: 16, dy: 10))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        view.addSubview(stack)
        
        let titleLabel = NSTextField(labelWithString: "上下文已压缩")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 12)
        titleLabel.textColor = .systemOrange
        stack.addArrangedSubview(titleLabel)
        
        let detailLabel = NSTextField(labelWithString: "\(beforeTokens) -> \(afterTokens) tokens (减少 \(beforeTokens - afterTokens))")
        detailLabel.font = NSFont.systemFont(ofSize: 10)
        detailLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(detailLabel)
    }
}

// MARK: - Session Ball Indicator Window
class SessionBallWindow: NSWindow {
    let state: SessionState
    let sessionID: String
    var onHover: ((Bool) -> Void)?
    
    init(state: SessionState, sessionID: String, size: CGFloat = 14) {
        self.state = state
        self.sessionID = sessionID
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let ballView = SessionBallView(frame: NSRect(x: 0, y: 0, width: size, height: size), state: state)
        ballView.autoresizingMask = [.width, .height]
        ballView.onHover = { [weak self] hovering in
            self?.onHover?(hovering)
        }
        self.contentView = ballView
    }
}

class SessionBallView: NSView {
    let state: SessionState
    var onHover: ((Bool) -> Void)?
    private var trackingArea: NSTrackingArea?
    private let pillLayer = CALayer()
    private let glowLayer = CALayer()
    
    init(frame frameRect: NSRect, state: SessionState) {
        self.state = state
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupLayers()
        setupTracking()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayers() {
        guard let layer = self.layer else { return }
        
        glowLayer.frame = bounds
        glowLayer.cornerRadius = bounds.height / 2
        glowLayer.masksToBounds = false
        layer.addSublayer(glowLayer)
        
        pillLayer.frame = bounds
        pillLayer.cornerRadius = bounds.height / 2
        pillLayer.masksToBounds = true
        pillLayer.borderWidth = 0.8
        layer.addSublayer(pillLayer)
        
        applyStyle()
    }
    
    override func layout() {
        super.layout()
        glowLayer.frame = bounds
        pillLayer.frame = bounds
        pillLayer.cornerRadius = bounds.height / 2
        glowLayer.cornerRadius = bounds.height / 2
    }
    
    private func applyStyle() {
        let color = state.baseColor
        let opacity = SettingsManager.shared.barOpacity
        
        pillLayer.backgroundColor = color.withAlphaComponent(CGFloat(opacity * 0.3)).cgColor
        pillLayer.borderColor = color.withAlphaComponent(CGFloat(opacity * 0.8)).cgColor
        
        glowLayer.shadowColor = color.cgColor
        glowLayer.shadowRadius = 8
        glowLayer.shadowOpacity = 0.5
        glowLayer.shadowOffset = CGSize(width: 0, height: 0)
        
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.8
        pulse.toValue = 1.0
        pulse.duration = 2.0
        pulse.autoreverses = true
        pulse.repeatCount = .greatestFiniteMagnitude
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pillLayer.add(pulse, forKey: "pulse")
    }
    
    private func setupTracking() {
        if let existing = trackingArea { removeTrackingArea(existing) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    func disableTracking() {
        if let existing = trackingArea { removeTrackingArea(existing) }
        trackingArea = nil
    }
    
    func enableTracking() {
        setupTracking()
    }
    
    override func mouseEntered(with event: NSEvent) {
        onHover?(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        onHover?(false)
    }
}

// MARK: - Child Session Dot Window
class ChildDotView: NSView {
    var onHover: ((Bool) -> Void)?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        trackingArea = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        animator().alphaValue = 1.0
        onHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        animator().alphaValue = 0.92
        onHover?(false)
    }
}

class ChildDotWindow: NSWindow {
    var onHover: ((Bool) -> Void)? {
        didSet { (contentView as? ChildDotView)?.onHover = onHover }
    }

    init(state: SessionState, size: CGFloat = 7, hitWidth: CGFloat = 22, hitHeight: CGFloat = 18) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: hitWidth, height: hitHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let badgeView = ChildDotView(frame: NSRect(x: 0, y: 0, width: hitWidth, height: hitHeight))
        badgeView.autoresizingMask = [.width, .height]
        badgeView.alphaValue = 0.92
        badgeView.wantsLayer = true
        badgeView.layer?.backgroundColor = NSColor.clear.cgColor

        let outer = NSView(frame: NSRect(x: (hitWidth - size) / 2, y: (hitHeight - size) / 2, width: size, height: size))
        outer.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        outer.wantsLayer = true
        outer.layer?.cornerRadius = size / 2
        outer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.35).cgColor

        let innerSize = max(size - 3, 3)
        let inner = NSView(frame: NSRect(x: (size - innerSize) / 2, y: (size - innerSize) / 2, width: innerSize, height: innerSize))
        inner.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        inner.wantsLayer = true
        inner.layer?.cornerRadius = innerSize / 2
        inner.layer?.backgroundColor = state.baseColor.cgColor
        inner.layer?.shadowColor = state.baseColor.cgColor
        inner.layer?.shadowOpacity = state == .error ? 0.9 : 0.45
        inner.layer?.shadowRadius = state == .error ? 5 : 2
        outer.addSubview(inner)
        badgeView.addSubview(outer)

        self.contentView = badgeView
    }
}

class SubagentDetailsHUDWindow: NSWindow {
    private var cards: [NSView] = []
    private var finalFrames: [NSRect] = []

    init() {
        let rect = NSRect(x: 0, y: 0, width: 360, height: 190)
        super.init(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    }

    func updateContent(children: [(session: OpencodeSession, state: SessionState)]) {
        let visibleChildren = Array(children.prefix(3))
        let totalW: CGFloat = 360
        let totalH: CGFloat = 190
        setContentSize(NSSize(width: totalW, height: totalH))
        cards.removeAll()
        finalFrames.removeAll()

        let root = NSView(frame: NSRect(x: 0, y: 0, width: totalW, height: totalH))
        root.wantsLayer = true

        // Fan layout: left, middle, right tickets fanning out from bottom-right anchor
        struct TicketLayout {
            let x: CGFloat, y: CGFloat, angle: CGFloat
        }
        let layouts: [TicketLayout] = [
            TicketLayout(x: 22,  y: 40, angle: -8),
            TicketLayout(x: 108, y: 70, angle: 0),
            TicketLayout(x: 194, y: 40, angle: 8),
        ]

        let ticketW: CGFloat = 138
        let ticketH: CGFloat = 78

        // Build tickets in visual order (left=0, middle=1, right=2)
        for (index, child) in visibleChildren.enumerated() {
            guard index < layouts.count else { break }
            let layout = layouts[index]
            let finalFrame = NSRect(x: layout.x, y: layout.y, width: ticketW, height: ticketH)
            let card = makeTicket(child: child, ticketW: ticketW, ticketH: ticketH, angle: layout.angle)
            
            // Start position: shared anchor at bottom-right, small frame, alpha 0
            let anchorX: CGFloat = totalW - 30
            let anchorY: CGFloat = 15
            card.frame = NSRect(x: anchorX, y: anchorY, width: 24, height: 24)
            card.alphaValue = 0
            
            root.addSubview(card)
            cards.append(card)
            finalFrames.append(finalFrame)
        }

        contentView = root
    }

    private func makeTicket(child: (session: OpencodeSession, state: SessionState), ticketW: CGFloat, ticketH: CGFloat, angle: CGFloat) -> NSView {
        let stateColor = child.state.baseColor
        
        // Outer wrapper with shadow
        let wrapper = NSView(frame: NSRect(x: 0, y: 0, width: ticketW, height: ticketH))
        wrapper.wantsLayer = true
        wrapper.layer?.shadowColor = NSColor.black.cgColor
        wrapper.layer?.shadowOpacity = 0.18
        wrapper.layer?.shadowRadius = 7
        wrapper.layer?.shadowOffset = CGSize(width: 0, height: 2)

        // Ticket body: warm off-white translucent paper
        let body = NSView(frame: NSRect(x: 0, y: 0, width: ticketW, height: ticketH))
        body.wantsLayer = true
        body.layer?.cornerRadius = 5
        body.layer?.masksToBounds = true
        body.layer?.backgroundColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 0.93).cgColor
        wrapper.addSubview(body)

        // Colored top strip (thin accent line using state color)
        let stripH: CGFloat = 3.5
        let topStrip = NSView(frame: NSRect(x: 0, y: ticketH - stripH, width: ticketW, height: stripH))
        topStrip.wantsLayer = true
        topStrip.layer?.backgroundColor = stateColor.cgColor
        body.addSubview(topStrip)

        // Perforation holes on left side (small circular dots)
        let holeRadius: CGFloat = 1.8
        let holeSpacing: CGFloat = 14
        let holeX: CGFloat = 7
        var holeY = ticketH - stripH - 12
        while holeY > 10 {
            let hole = NSView(frame: NSRect(x: holeX - holeRadius, y: holeY - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
            hole.wantsLayer = true
            hole.layer?.cornerRadius = holeRadius
            hole.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.7).cgColor
            body.addSubview(hole)
            holeY -= holeSpacing
        }

        // Content: title
        let titleText = child.session.title.isEmpty ? child.session.id : child.session.title
        let title = NSTextField(labelWithString: titleText)
        title.frame = NSRect(x: 15, y: ticketH - 24, width: ticketW - 26, height: 14)
        title.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        title.textColor = .labelColor
        title.maximumNumberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.toolTip = titleText
        body.addSubview(title)

        // State label
        let stateText = stateLabel(child.state)
        let stateField = NSTextField(labelWithString: stateText)
        stateField.frame = NSRect(x: 15, y: ticketH - 40, width: ticketW - 26, height: 12)
        stateField.font = NSFont.systemFont(ofSize: 9, weight: .medium)
        stateField.textColor = stateColor
        stateField.maximumNumberOfLines = 1
        stateField.lineBreakMode = .byTruncatingTail
        body.addSubview(stateField)

        // Meta: model and tool
        let modelText = child.session.modelID ?? "Custom"
        let toolText = child.session.recentTool ?? "无工具调用"
        let metaText = "\(modelText) · \(toolText)"
        let meta = NSTextField(labelWithString: metaText)
        meta.frame = NSRect(x: 15, y: 9, width: ticketW - 26, height: 11)
        meta.font = NSFont.systemFont(ofSize: 8, weight: .regular)
        meta.textColor = .secondaryLabelColor
        meta.maximumNumberOfLines = 1
        meta.lineBreakMode = .byTruncatingTail
        meta.toolTip = metaText
        body.addSubview(meta)

        // Apply rotation via layer transform around z-axis
        wrapper.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        wrapper.layer?.transform = CATransform3DMakeRotation(angle * .pi / 180.0, 0, 0, 1)

        return wrapper
    }

    private func stateLabel(_ state: SessionState) -> String {
        switch state {
        case .inactive: return "未活跃"
        case .idle: return "就绪"
        case .thinking: return "思考"
        case .working: return "工作中"
        case .compacting: return "压缩中"
        case .error: return "报错"
        }
    }

    func showAnimated() {
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            animator().alphaValue = 1
        }
        
        // Staggered fan-out animation from shared anchor
        for (index, card) in cards.enumerated() {
            let delay = Double(index) * 0.09
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.42
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    if index < self.finalFrames.count {
                        card.animator().frame = self.finalFrames[index]
                    }
                    card.animator().alphaValue = 1
                }
            }
        }
    }

    func hideAnimated() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
        })
    }
}

class SubagentListHUDWindow: NSWindow {
    private var rows: [NSView] = []

    init() {
        let rect = NSRect(x: 0, y: 0, width: 260, height: 40)
        super.init(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let visualEffect = NSVisualEffectView(frame: rect)
        visualEffect.material = NSVisualEffectView.Material.hudWindow
        visualEffect.state = NSVisualEffectView.State.active
        visualEffect.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true
        self.contentView = visualEffect
    }

    func updateContent(children: [(session: OpencodeSession, state: SessionState)]) {
        guard let view = self.contentView else { return }
        view.subviews.forEach { v in v.removeFromSuperview() }
        
        let visibleChildren = Array(children.prefix(3))
        let rowHeight: CGFloat = 32
        let padding: CGFloat = 10
        let totalW: CGFloat = 260
        let totalH: CGFloat = padding + CGFloat(visibleChildren.count) * rowHeight + padding
        setContentSize(NSSize(width: totalW, height: totalH))
        
        let contentFrame = NSRect(x: 0, y: 0, width: totalW, height: totalH)
        let content = NSView(frame: contentFrame)
        content.wantsLayer = true
        view.addSubview(content)
        rows.removeAll()

        for (index, child) in visibleChildren.enumerated() {
            let row = makeRow(child: child, width: totalW, height: rowHeight)
            row.frame = NSRect(x: 0, y: totalH - padding - CGFloat(index + 1) * rowHeight, width: totalW, height: rowHeight)
            content.addSubview(row)
            rows.append(row)
        }
    }

    private func makeRow(child: (session: OpencodeSession, state: SessionState), width: CGFloat, height: CGFloat) -> NSView {
        let row = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        row.wantsLayer = true
        row.layer?.backgroundColor = NSColor.clear.cgColor

        let dot = NSView(frame: NSRect(x: 12, y: (height - 8) / 2, width: 8, height: 8))
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 4
        dot.layer?.backgroundColor = child.state.baseColor.cgColor
        row.addSubview(dot)

        let titleText = child.session.title.isEmpty ? child.session.id : child.session.title
        let title = NSTextField(labelWithString: titleText)
        title.frame = NSRect(x: 28, y: (height - 16) / 2, width: width - 40, height: 16)
        title.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        title.textColor = .labelColor
        title.maximumNumberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.toolTip = titleText
        row.addSubview(title)

        return row
    }

    func showAnimated() {
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1
        }
    }

    func hideAnimated() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
        })
    }
}

// MARK: - Overlay Window
class StatusOverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    }
}

// MARK: - Confetti Window
class ConfettiWindow: NSWindow {
    init(frame: NSRect) {
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let view = NSView(frame: NSRect(origin: .zero, size: frame.size))
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        self.contentView = view

    }

    func burst() {
        let colors: [NSColor] = [.systemGreen, .systemCyan, .systemYellow, .systemOrange, .white, .systemPurple]
        guard let root = contentView else { return }
        root.subviews.forEach { $0.removeFromSuperview() }

        for index in 0..<34 {
            let size = CGFloat(Int.random(in: 5...9))
            let startX = root.bounds.midX + CGFloat.random(in: -70...70)
            let particle = NSView(frame: NSRect(x: startX, y: 8, width: size, height: size))
            particle.wantsLayer = true
            particle.layer?.cornerRadius = size / 2
            particle.layer?.backgroundColor = colors[index % colors.count].cgColor
            particle.layer?.shadowColor = colors[index % colors.count].cgColor
            particle.layer?.shadowOpacity = 0.8
            particle.layer?.shadowRadius = 4
            root.addSubview(particle)

            let endX = startX + CGFloat.random(in: -110...110)
            let endY = CGFloat.random(in: 70...130)
            let delay = Double.random(in: 0...0.12)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.85
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    particle.animator().frame = NSRect(x: endX, y: endY, width: size, height: size)
                    particle.animator().alphaValue = 0
                }) {
                    particle.removeFromSuperview()
                }
            }
        }
    }

    private static func particleImage() -> NSImage? {
        let size = CGSize(width: 10, height: 10)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        img.unlockFocus()
        return img
    }
}

// MARK: - Indicator View with Desktop Pet Click Interaction
class StatusIndicatorView: NSView {
    var currentState: SessionState = .inactive {
        didSet {
            if oldValue != currentState {
                applyAmbientStyleAndAnimation()
            }
        }
    }
    
    var isCollapsed: Bool = false
    
    var onHoverStateChanged: ((Bool) -> Void)?
    var onClicked: (() -> Void)?
    
    private let pillLayer = CALayer()
    private let glowLayer = CALayer()
    private let shimmerLayer = CAGradientLayer()
    private let emitterLayer = CAEmitterLayer()
    private var trackingArea: NSTrackingArea?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupLayers()
        setupTracking()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        setupLayers()
        setupTracking()
    }
    
    private func setupTracking() {
        if let existing = trackingArea { removeTrackingArea(existing) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) { onHoverStateChanged?(true) }
    override func mouseExited(with event: NSEvent) { onHoverStateChanged?(false) }
    
    override func mouseDown(with event: NSEvent) {
        onClicked?()
    }
    
    private func setupLayers() {
        guard let layer = self.layer else { return }
        layer.masksToBounds = false
        
        glowLayer.frame = bounds
        glowLayer.cornerRadius = bounds.height / 2
        glowLayer.masksToBounds = false
        layer.addSublayer(glowLayer)
        
        pillLayer.frame = bounds
        pillLayer.cornerRadius = bounds.height / 2
        pillLayer.masksToBounds = true
        pillLayer.borderWidth = 0.8
        layer.addSublayer(pillLayer)
        
        shimmerLayer.frame = bounds.insetBy(dx: 2, dy: 2)
        shimmerLayer.cornerRadius = shimmerLayer.bounds.height / 2
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.colors = [
            NSColor.clear.cgColor,
            NSColor.white.withAlphaComponent(0.2).cgColor,
            NSColor.clear.cgColor
        ]
        shimmerLayer.locations = [-0.3, 0.0, 0.3]
        pillLayer.addSublayer(shimmerLayer)

        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 2)
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .unordered
        emitterLayer.birthRate = 0
        emitterLayer.zPosition = 20
        layer.addSublayer(emitterLayer)
        
        applyAmbientStyleAndAnimation()
    }
    
    override func layout() {
        super.layout()
        glowLayer.frame = bounds
        pillLayer.frame = bounds
        pillLayer.cornerRadius = bounds.height / 2
        glowLayer.cornerRadius = bounds.height / 2
        shimmerLayer.frame = bounds.insetBy(dx: 2, dy: 2)
        shimmerLayer.cornerRadius = shimmerLayer.bounds.height / 2
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 2)
        
        if isCollapsed {
            shimmerLayer.isHidden = true
            glowLayer.isHidden = true
        }
        
        setupTracking()
    }
    
    func updateState(_ state: SessionState) { self.currentState = state }

    func celebrateTaskCompletion() {
        triggerTaskCompletionConfetti()
    }
    
    func setCollapsed(_ collapsed: Bool) {
        isCollapsed = collapsed
        if collapsed {
            shimmerLayer.isHidden = true
            glowLayer.isHidden = true
            pillLayer.removeAnimation(forKey: "ambientPulse")
            shimmerLayer.removeAnimation(forKey: "ambientShimmer")
        } else {
            shimmerLayer.isHidden = false
            glowLayer.isHidden = false
            applyAmbientStyleAndAnimation()
        }
    }
    
    private func triggerTaskCompletionConfetti() {
        let colors: [NSColor] = [.systemGreen, .systemCyan, .systemYellow, .systemOrange, .white, .systemPurple]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 12
            cell.lifetime = 1.8
            cell.velocity = 120
            cell.velocityRange = 40
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = .pi / 4
            cell.spin = 3.5
            cell.spinRange = 2.0
            cell.scale = 0.08
            cell.scaleRange = 0.04
            cell.color = color.cgColor
            cell.contents = createParticleImage()?.cgImage
            cell.yAcceleration = 180
            cells.append(cell)
        }
        
        emitterLayer.birthRate = 1
        emitterLayer.emitterCells = cells
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.emitterLayer.birthRate = 0
        }
    }
    
    private func createParticleImage() -> NSImage? {
        let size = CGSize(width: 10, height: 10)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.white.setFill()
        let path = NSBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        path.fill()
        img.unlockFocus()
        return img
    }
    
    private func applyAmbientStyleAndAnimation() {
        guard !isCollapsed else {
            shimmerLayer.isHidden = true
            glowLayer.isHidden = true
            return
        }

        let color = currentState.baseColor
        let opacitySetting = SettingsManager.shared.barOpacity
        
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        CATransaction.setAnimationDuration(0.6)
        
        pillLayer.backgroundColor = color.withAlphaComponent(CGFloat(opacitySetting * 0.3)).cgColor
        pillLayer.borderColor = color.withAlphaComponent(CGFloat(opacitySetting * 0.8)).cgColor
        
        glowLayer.shadowColor = color.cgColor
        glowLayer.shadowRadius = currentState == .inactive ? 2 : 12
        glowLayer.shadowOpacity = currentState == .inactive ? 0.2 : 0.6
        glowLayer.shadowOffset = CGSize(width: 0, height: 0)
        
        CATransaction.commit()
        
        pillLayer.removeAnimation(forKey: "ambientPulse")
        shimmerLayer.removeAnimation(forKey: "ambientShimmer")
        
        if currentState != .inactive {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = currentState == .compacting ? 0.55 : 0.75
            pulse.toValue = 0.98
            pulse.duration = currentState == .compacting ? 0.7 : (currentState == .error ? 1.0 : 3.0)
            pulse.autoreverses = true
            pulse.repeatCount = .greatestFiniteMagnitude
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pillLayer.add(pulse, forKey: "ambientPulse")
            
            let shimmer = CABasicAnimation(keyPath: "locations")
            shimmer.fromValue = [-0.5, -0.25, 0.0]
            shimmer.toValue = [1.0, 1.25, 1.5]
            shimmer.duration = currentState == .compacting ? 0.9 : 4.0
            shimmer.repeatCount = .greatestFiniteMagnitude
            shimmer.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            shimmerLayer.add(shimmer, forKey: "ambientShimmer")
        } else {
            pillLayer.opacity = 0.35
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var overlayWindow: StatusOverlayWindow!
    var indicatorView: StatusIndicatorView!
    var settingsWindowController: SettingsWindowController?
    var onboardingWindowController: OnboardingWindowController?
    var hoverHUDWindow: HoverHUDWindow!
    var compactionHUDWindow: CompactionHUDWindow?
    var confettiWindow: ConfettiWindow?
    var subagentDetailsHUDWindow: SubagentListHUDWindow?
    var subagentHUDDismissWorkItem: DispatchWorkItem?
    var apiServiceProcess: Process?
    var apiServiceStatusMessage: String = "API 服务未启动"
    
    var sessionBallWindows: [NSWindow] = []
    var activeSessionIDs: [String] = []
    var childDotWindows: [String: [ChildDotWindow]] = [:]
    
    var isOpencodeRunning: Bool = true
    var lastStateDebug: String = "idle"
    var lastCelebratedStopTime: Int64 = 0
    var lastObservedSessionState: SessionState?
    
    var selectedSessionID: String? {
        didSet {
            UserDefaults.standard.set(selectedSessionID, forKey: "SelectedSessionID")
            refreshSessionsList()
        }
    }
    
    var sessionsMenu: NSMenu!
    var pollTimer: Timer?
    var sessionStartTime: Date = Date()
    
    let dbPath = NSString("~/.local/share/opencode/opencode.db").expandingTildeInPath

    func isProviderErrorMessage(_ json: [String: Any]) -> Bool {
        guard let error = json["error"] as? [String: Any] else { return false }
        let name = (error["name"] as? String ?? "").lowercased()
        let data = error["data"] as? [String: Any]
        let message = (data?["message"] as? String ?? error["message"] as? String ?? "").lowercased()
        let statusCode = data?["statusCode"] as? Int ?? error["statusCode"] as? Int ?? 0
        
        guard name.contains("apierror") else { return false }

        return statusCode == 401 ||
            statusCode == 402 ||
            statusCode == 429 ||
            message.contains("quota") ||
            message.contains("allocated quota") ||
            message.contains("rate limit") ||
            message.contains("insufficient credits") ||
            message.contains("spend limit")
    }

    func stateForLatestPart(_ json: [String: Any], ageMs: Int64) -> (SessionState, String) {
        let type = json["type"] as? String ?? ""
        let activeWindowMs: Int64 = 15 * 1000
        let idleWindowMs: Int64 = 3 * 60 * 1000

        if type == "tool" {
            let stateDict = json["state"] as? [String: Any]
            let status = stateDict?["status"] as? String ?? ""
            if status == "running" || status == "pending" {
                return (.working, "working: tool \(status)")
            }
            if ageMs <= activeWindowMs {
                return (.thinking, "thinking: tool \(status)")
            }
            return (.inactive, "inactive: tool stale")
        }

        if type == "reasoning" || type == "step-start" || type == "text" {
            if ageMs <= activeWindowMs {
                return (.thinking, "thinking: \(type)")
            }
            return (.inactive, "inactive: \(type) stale")
        }

        if type == "step-finish" {
            let reason = json["reason"] as? String ?? ""
            if reason == "tool-calls" && ageMs <= activeWindowMs {
                return (.working, "working: tool-calls")
            }
            if reason == "stop" && ageMs <= idleWindowMs {
                return (.idle, "idle: recent stop")
            }
            return (.inactive, "inactive: step-finish stale")
        }

        if type == "compaction" {
            if ageMs <= activeWindowMs {
                return (.thinking, "thinking: compaction")
            }
            return (.inactive, "inactive: compaction stale")
        }

        return (.inactive, "inactive: \(type)")
    }

    func inferSessionState(db: OpaquePointer?, sessionID: String) -> (SessionState, String) {
        var hasRunningTool = false
        let toolQuery = """
            SELECT 1 FROM part
            WHERE session_id = ?
              AND json_extract(data, '$.type') = 'tool'
              AND json_extract(data, '$.state.status') IN ('running', 'pending')
            LIMIT 1;
        """
        var toolStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, toolQuery, -1, &toolStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(toolStmt, 1, (sessionID as NSString).utf8String, -1, nil)
            hasRunningTool = sqlite3_step(toolStmt) == SQLITE_ROW
            sqlite3_finalize(toolStmt)
        }

        if hasRunningTool {
            return (.working, "working: running tool")
        }

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let compactingQuery = """
            SELECT time_compacting FROM session
            WHERE id = ? AND time_compacting IS NOT NULL
            LIMIT 1;
        """
        var compactStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, compactingQuery, -1, &compactStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(compactStmt, 1, (sessionID as NSString).utf8String, -1, nil)
            if sqlite3_step(compactStmt) == SQLITE_ROW {
                let compactTime = sqlite3_column_int64(compactStmt, 0)
                if compactTime > 0 && nowMs - compactTime <= 5 * 60 * 1000 {
                    sqlite3_finalize(compactStmt)
                    return (.compacting, "compacting: session")
                }
            }
            sqlite3_finalize(compactStmt)
        }

        let compactPartQuery = """
            SELECT time_created FROM part
            WHERE session_id = ? AND json_extract(data, '$.type') = 'compaction'
            ORDER BY time_created DESC LIMIT 1;
        """
        var compactPartStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, compactPartQuery, -1, &compactPartStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(compactPartStmt, 1, (sessionID as NSString).utf8String, -1, nil)
            if sqlite3_step(compactPartStmt) == SQLITE_ROW {
                let compactTime = sqlite3_column_int64(compactPartStmt, 0)
                if nowMs - compactTime <= 5 * 60 * 1000 {
                    sqlite3_finalize(compactPartStmt)
                    return (.compacting, "compacting: recent")
                }
            }
            sqlite3_finalize(compactPartStmt)
        }

        let assistantQuery = """
            SELECT data FROM message
            WHERE session_id = ?
              AND json_extract(data, '$.role') = 'assistant'
            ORDER BY time_created DESC LIMIT 1;
        """
        var assistantStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, assistantQuery, -1, &assistantStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(assistantStmt, 1, (sessionID as NSString).utf8String, -1, nil)
            defer { sqlite3_finalize(assistantStmt) }

            if sqlite3_step(assistantStmt) == SQLITE_ROW,
               let ptr = sqlite3_column_text(assistantStmt, 0) {
                let str = String(cString: ptr)
                if let data = str.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["error"] as? [String: Any] {
                        let name = error["name"] as? String ?? "error"
                        return isProviderErrorMessage(json) ? (.error, "error: \(name)") : (.inactive, "inactive: \(name)")
                    }

                    if let timeDict = json["time"] as? [String: Any], timeDict["completed"] != nil {
                        let finish = json["finish"] as? String ?? "completed"
                        return finish == "tool-calls" ? (.thinking, "thinking: tool-calls") : (.idle, "idle: completed")
                    }

                    return (.thinking, "thinking: assistant incomplete")
                }
            }
        }

        return (.inactive, "inactive: no assistant")
    }

    func fetchChildSessions(db: OpaquePointer?, parentID: String) -> [(id: String, state: SessionState)] {
        var children: [(id: String, state: SessionState)] = []
        let tenMinutesAgo = Int64(Date().timeIntervalSince1970 * 1000) - 10 * 60 * 1000
        let query = "SELECT id FROM session WHERE parent_id = ? AND time_updated > ? ORDER BY time_updated DESC LIMIT 3;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return children }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (parentID as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 2, tenMinutesAgo)

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let ptr = sqlite3_column_text(stmt, 0) {
                let childID = String(cString: ptr)
                children.append((childID, inferSessionState(db: db, sessionID: childID).0))
            }
        }

        return children
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = createCircularIcon()
            button.image?.isTemplate = true
        }
        
        sessionsMenu = NSMenu()
        statusItem.menu = sessionsMenu
        
        let savedID = UserDefaults.standard.string(forKey: "SelectedSessionID")
        let sessions = fetchSessions()
        
        if let savedID = savedID, sessions.contains(where: { $0.id == savedID }) {
            selectedSessionID = savedID
        } else {
            selectedSessionID = sessions.first?.id
        }
        
        setupOverlayWindow()
        setupHoverHUD()
        refreshSessionsList()
        
        if !UserDefaults.standard.bool(forKey: "HasShownOnboarding") {
            onboardingWindowController = OnboardingWindowController()
            onboardingWindowController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollSessionState()
        }

        if SettingsManager.shared.autoStartAPIService {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startAPIService()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateOverlayGeometry), name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    func createCircularIcon(color: NSColor = .labelColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        color.set()
        let rect = NSRect(x: 3, y: 3, width: 12, height: 12)
        let path = NSBezierPath(ovalIn: rect)
        path.fill()
        image.unlockFocus()
        return image
    }
    
    func updateMenuIconColor(_ state: SessionState) {
        guard let button = statusItem.button else { return }
        button.image = createCircularIcon(color: state.baseColor)
    }
    
    func setupOverlayWindow() {
        let isMini = SettingsManager.shared.miniMode
        let barWidth = isMini ? 20 : SettingsManager.shared.barWidth
        let barHeight = isMini ? 20 : SettingsManager.shared.barHeight
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        
        let x = screenRect.midX - (barWidth / 2)
        let y = screenRect.minY + 16
        
        let frame = NSRect(x: x, y: y, width: barWidth, height: barHeight)
        overlayWindow = StatusOverlayWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        overlayWindow.alphaValue = 1.0
        stableBarFrame = frame
        
        indicatorView = StatusIndicatorView(frame: NSRect(x: 0, y: 0, width: barWidth, height: barHeight))
        indicatorView.autoresizingMask = [.width, .height]
        indicatorView.updateState(.inactive)
        
        indicatorView.onHoverStateChanged = { [weak self] isHovered in
            self?.handleHover(isHovered)
        }
        
        indicatorView.onClicked = { [weak self] in
            self?.showPetBubble()
        }
        
        overlayWindow.contentView = indicatorView
        overlayWindow.orderFrontRegardless()
    }
    
    // Show handwritten Kaomoji floating upwards from top-right of the bar
    func showPetBubble() {
        let kaomojis = ["(๑•̀ㅂ•́)و", "(｡•̀ᴗ-)", "(๑>◡<๑)", "(ง •̀_•́)ง", "(◍•ᴗ•◍)", "(๑• . •๑)", "(* ॑꒳॑ *)", "(ᵔᴥᵔ)", "(ﾉ◕ヮ◕)ﾉ"]
        let randomKaomoji = kaomojis.randomElement() ?? "(๑>◡<๑)"
        
        let barFrame = overlayWindow.frame
        let bubbleX = barFrame.maxX - 40
        let bubbleY = barFrame.maxY
        
        let bubble = PetBubbleWindow(text: randomKaomoji, at: CGPoint(x: bubbleX, y: bubbleY))
        bubble.alphaValue = 0
        bubble.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            bubble.animator().alphaValue = 1.0
            bubble.setFrame(NSRect(x: bubbleX, y: bubbleY + 8, width: 80, height: 30), display: true)
        }) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                bubble.animator().alphaValue = 0
            }) {
                bubble.orderOut(nil)
            }
        }
    }
    
    func setupHoverHUD() {
        hoverHUDWindow = HoverHUDWindow()
    }
    
    func handleHover(_ isHovered: Bool) {
        guard !isBallHovered else { return }

        if isHovered {
            let barFrame = overlayWindow.frame
            let hudWidth: CGFloat = 300
            let hudHeight: CGFloat = 210
            let hudX = barFrame.midX - (hudWidth / 2)
            let hudY = barFrame.maxY + 10
            
            hoverHUDWindow.setFrame(NSRect(x: hudX, y: hudY, width: hudWidth, height: hudHeight), display: true)
            
            if let sessionID = selectedSessionID, let session = fetchSessionDetails(sessionID) {
                let duration = Int(Date().timeIntervalSince(sessionStartTime))
                hoverHUDWindow.updateContent(
                    title: session.title,
                    model: session.modelID ?? "Custom Model",
                    cost: session.cost,
                    inputTokens: Int(session.tokensInput),
                    outputTokens: Int(session.tokensOutput),
                    durationSeconds: duration,
                    recentTool: session.recentTool,
                    modelSwitch: session.modelSwitch
                )
            } else {
                hoverHUDWindow.updateContent(title: "未选择会话", model: "-", cost: 0, inputTokens: 0, outputTokens: 0, durationSeconds: 0)
            }
            
            hoverHUDWindow.alphaValue = 0
            hoverHUDWindow.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                hoverHUDWindow.animator().alphaValue = 1.0
            }
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                hoverHUDWindow.animator().alphaValue = 0
            }) {
                self.hoverHUDWindow.orderOut(nil)
            }
        }
    }
    
    @objc func updateOverlayGeometry() {
        let isMini = SettingsManager.shared.miniMode
        let barWidth = isMini ? 20 : SettingsManager.shared.barWidth
        let barHeight = isMini ? 20 : SettingsManager.shared.barHeight
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let x = screenRect.midX - (barWidth / 2)
        let y = screenRect.minY + 16
        
        overlayWindow.setFrame(NSRect(x: x, y: y, width: barWidth, height: barHeight), display: true)
        stableBarFrame = overlayWindow.frame
        indicatorView.frame = NSRect(x: 0, y: 0, width: barWidth, height: barHeight)
        indicatorView.needsLayout = true
        
        updateSessionBallPositions()
    }
    
    func updateSessionBallPositions() {
        guard !isBallHovered, !isAnimating else { return }
        let barFrame = stableBarFrame == .zero ? overlayWindow.frame : stableBarFrame
        let ballSize: CGFloat = 14
        let spacing: CGFloat = 6
        
        for (index, window) in sessionBallWindows.enumerated() {
            let offset = CGFloat(index + 1) * (ballSize + spacing)
            let x = barFrame.minX - offset
            let y = barFrame.midY - ballSize / 2
            window.setFrame(NSRect(x: x, y: y, width: ballSize, height: ballSize), display: true)
        }
        updateChildDotPositions(animated: false)
    }
    
    func updateSessionBallPositionsAnimated() {
        let barFrame = originalBarFrame
        let ballSize: CGFloat = 14
        let spacing: CGFloat = 6
        
        for (index, window) in sessionBallWindows.enumerated() {
            let offset = CGFloat(index + 1) * (ballSize + spacing)
            let x = barFrame.minX - offset
            let y = barFrame.midY - ballSize / 2
            window.animator().setFrame(NSRect(x: x, y: y, width: ballSize, height: ballSize), display: true)
        }
        updateChildDotPositions(animated: true)
    }

    func updateChildDotWindows() {
        var parentIDs: [String] = []
        if let mainID = selectedSessionID {
            parentIDs.append(mainID)
        }

        for (parentID, dots) in childDotWindows where !parentIDs.contains(parentID) {
            dots.forEach { $0.orderOut(nil) }
            childDotWindows.removeValue(forKey: parentID)
        }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return }
        defer { sqlite3_close(db) }

        for parentID in parentIDs {
            let children = fetchChildSessions(db: db, parentID: parentID)
            let existingDots = childDotWindows[parentID] ?? []
            
            if existingDots.count != min(children.count, 3) {
                existingDots.forEach { $0.orderOut(nil) }
                
                let newDots = children.prefix(3).map { child -> ChildDotWindow in
                    let dot = ChildDotWindow(state: child.state)
                    dot.onHover = { [weak self] isHovering in
                        if isHovering {
                            self?.showSubagentDetailsHUD(parentID: parentID)
                        } else {
                            self?.scheduleSubagentDetailsHUDHide()
                        }
                    }
                    dot.orderFrontRegardless()
                    return dot
                }
                childDotWindows[parentID] = Array(newDots)
            }
        }

        updateChildDotPositions(animated: false)
    }

    func updateChildDotPositions(animated: Bool) {
        let dotSize: CGFloat = 7
        let dotGap: CGFloat = -2
        let hitWidth: CGFloat = 22
        let hitHeight: CGFloat = 18

        if SettingsManager.shared.miniMode || indicatorView.isCollapsed {
            for dots in childDotWindows.values {
                dots.forEach { $0.orderOut(nil) }
            }
            return
        }

        if let mainID = selectedSessionID, let dots = childDotWindows[mainID] {
            let frame = originalBarFrame == .zero ? (stableBarFrame == .zero ? overlayWindow.frame : stableBarFrame) : originalBarFrame
            for (index, dot) in dots.enumerated() {
                let centerX = frame.maxX - 6 - CGFloat(index) * (dotSize + dotGap)
                let centerY = frame.maxY
                let target = NSRect(x: centerX - hitWidth / 2, y: centerY - hitHeight / 2, width: hitWidth, height: hitHeight)
                animated ? dot.animator().setFrame(target, display: true) : dot.setFrame(target, display: true)
            }
        }
    }

    func showSubagentDetailsHUD(parentID: String) {
        subagentHUDDismissWorkItem?.cancel()
        subagentHUDDismissWorkItem = nil
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return }
        defer { sqlite3_close(db) }

        let children = fetchChildSessions(db: db, parentID: parentID).compactMap { child -> (session: OpencodeSession, state: SessionState)? in
            guard let session = fetchSessionDetails(child.id) else { return nil }
            return (session, child.state)
        }
        guard !children.isEmpty else { return }

        let hud = subagentDetailsHUDWindow ?? SubagentListHUDWindow()
        subagentDetailsHUDWindow = hud
        hud.updateContent(children: children)

        let frame = stableBarFrame == .zero ? overlayWindow.frame : stableBarFrame
        let hudWidth = hud.frame.width
        let hudHeight = hud.frame.height
        let target = NSRect(x: frame.maxX - hudWidth + 18, y: frame.maxY + 12, width: hudWidth, height: hudHeight)
        hud.setFrame(target, display: true)
        hud.showAnimated()
    }

    func scheduleSubagentDetailsHUDHide() {
        subagentHUDDismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.subagentDetailsHUDWindow?.hideAnimated()
        }
        subagentHUDDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: workItem)
    }
    
    var ballHoverHUD: HoverHUDWindow?
    var isBallHovered = false
    var stableBarFrame: NSRect = .zero
    var originalBarFrame: NSRect = .zero
    var hoveredBallWindow: SessionBallWindow?
    var hoveredBallIndex: Int = -1
    var isAnimating = false
    var dismissWorkItem: DispatchWorkItem?
    var hoverMonitorTimer: Timer?
    
    func handleBallHover(_ isHovering: Bool, ballWindow: SessionBallWindow) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        
        if isHovering {
            guard !isAnimating, !isBallHovered else { return }
            isBallHovered = true
            hoveredBallWindow = ballWindow
            if stableBarFrame == .zero {
                stableBarFrame = overlayWindow.frame
            }
            originalBarFrame = stableBarFrame
            
            guard let idx = sessionBallWindows.firstIndex(of: ballWindow) else {
                isBallHovered = false
                return
            }
            hoveredBallIndex = idx
            
            let barWidth = originalBarFrame.width
            let barHeight = originalBarFrame.height
            let ballSize: CGFloat = 14
            let spacing: CGFloat = 6
            let barCenterX = originalBarFrame.midX
            let collapsedBarMinX = barCenterX - ballSize / 2
            let expandedCenterX = collapsedBarMinX - spacing - barWidth / 2
            let dotY = originalBarFrame.midY - ballSize / 2
            let barY = originalBarFrame.minY
            
            isAnimating = true
            
            indicatorView.setCollapsed(true)
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                overlayWindow.animator().setFrame(
                    NSRect(x: barCenterX - ballSize / 2, y: dotY, width: ballSize, height: ballSize),
                    display: true
                )
                
                ballWindow.animator().setFrame(
                    NSRect(x: expandedCenterX - barWidth / 2, y: barY, width: barWidth, height: barHeight),
                    display: true
                )
                
                for (i, w) in sessionBallWindows.enumerated() {
                    guard i != idx else { continue }
                    let newX: CGFloat
                    if i < idx {
                        let rightEdge = expandedCenterX - barWidth / 2 - spacing
                        newX = rightEdge - CGFloat(idx - i) * (ballSize + spacing)
                    } else {
                        let leftEdge = expandedCenterX + barWidth / 2 + spacing
                        newX = leftEdge + CGFloat(i - idx - 1) * (ballSize + spacing)
                    }
                    w.animator().setFrame(
                        NSRect(x: newX, y: dotY, width: ballSize, height: ballSize),
                        display: true
                    )
                }
            }, completionHandler: { [weak self] in
                self?.isAnimating = false
                self?.updateChildDotPositions(animated: false)
            })
            startBallHoverMonitor()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self = self, self.isBallHovered else { return }
                
                if self.ballHoverHUD == nil {
                    self.ballHoverHUD = HoverHUDWindow()
                }
                guard let hud = self.ballHoverHUD, let session = self.fetchSessionDetails(ballWindow.sessionID) else { return }
                
                let expandedFrame = ballWindow.frame
                let hudWidth: CGFloat = 300
                let hudHeight: CGFloat = 210
                let hudX = expandedFrame.midX - hudWidth / 2
                let hudY = expandedFrame.maxY + 10
                
                hud.setFrame(NSRect(x: hudX, y: hudY, width: hudWidth, height: hudHeight), display: true)
                hud.updateContent(
                    title: session.title,
                    model: session.modelID ?? "Custom",
                    cost: session.cost,
                    inputTokens: Int(session.tokensInput),
                    outputTokens: Int(session.tokensOutput),
                    durationSeconds: 0,
                    recentTool: session.recentTool,
                    modelSwitch: session.modelSwitch
                )
                
                hud.alphaValue = 0
                hud.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.25
                    hud.animator().alphaValue = 1.0
                })
            }
        } else {
            scheduleBallHoverCollapse()
        }
    }

    func startBallHoverMonitor() {
        hoverMonitorTimer?.invalidate()
        hoverMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self, self.isBallHovered, !self.isAnimating else { return }
            let mouse = NSEvent.mouseLocation
            let expandedFrame = self.hoveredBallWindow?.frame.insetBy(dx: -12, dy: -14) ?? .zero
            let collapsedBarFrame = self.overlayWindow.frame.insetBy(dx: -12, dy: -14)
            let hudFrame = self.ballHoverHUD?.frame.insetBy(dx: -8, dy: -8) ?? .zero
            
            if !expandedFrame.contains(mouse) && !collapsedBarFrame.contains(mouse) && !hudFrame.contains(mouse) {
                self.collapseBallHover()
            }
        }
    }

    func scheduleBallHoverCollapse() {
        guard isBallHovered, !isAnimating else { return }
        dismissWorkItem = DispatchWorkItem { [weak self] in
            self?.collapseBallHover()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: dismissWorkItem!)
    }

    func collapseBallHover() {
        guard isBallHovered, !isAnimating, originalBarFrame != .zero else { return }
        hoverMonitorTimer?.invalidate()
        hoverMonitorTimer = nil
        isBallHovered = false
        
        if let hud = ballHoverHUD {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                hud.animator().alphaValue = 0
            }) {
                hud.orderOut(nil)
            }
        }
        
        isAnimating = true
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            overlayWindow.animator().setFrame(originalBarFrame, display: true)
            updateSessionBallPositionsAnimated()
        }, completionHandler: { [weak self] in
            guard let self = self else { return }
            self.isAnimating = false
            self.originalBarFrame = .zero
            self.hoveredBallWindow = nil
            self.hoveredBallIndex = -1
            self.indicatorView.setCollapsed(false)
            self.updateChildDotPositions(animated: false)
        })
    }
    
    func fetchSessionDetails(_ id: String) -> OpencodeSession? {
        var db: OpaquePointer?
        var session: OpencodeSession?
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            defer { sqlite3_close(db) }
            
            let query = "SELECT id, title, time_updated, model, cost, tokens_input, tokens_output FROM session WHERE id = ?;"
            var stmt: OpaquePointer?
            
            var baseTitle = "Untitled"
            var baseModel: String?
            var timeUpdated: Int64 = 0
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if let titlePtr = sqlite3_column_text(stmt, 1) { baseTitle = String(cString: titlePtr) }
                    timeUpdated = sqlite3_column_int64(stmt, 2)
                    if let modelPtr = sqlite3_column_text(stmt, 3) { baseModel = String(cString: modelPtr) }
                }
                sqlite3_finalize(stmt)
            }
            
            let msgQuery = "SELECT data FROM message WHERE session_id = ? ORDER BY time_created DESC;"
            var msgStmt: OpaquePointer?
            var latestModelID: String?
            var previousModelID: String?
            var contextTokens: Int64 = 0
            var totalInputTokens: Int64 = 0
            var totalOutputTokens: Int64 = 0
            var recentTool: String?

            let partTokenQuery = "SELECT data FROM part WHERE session_id = ? AND data LIKE '%\"tokens\"%' ORDER BY time_created DESC LIMIT 20;"
            var partTokenStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, partTokenQuery, -1, &partTokenStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(partTokenStmt, 1, (id as NSString).utf8String, -1, nil)
                while sqlite3_step(partTokenStmt) == SQLITE_ROW && contextTokens == 0 {
                    if let ptr = sqlite3_column_text(partTokenStmt, 0) {
                        let str = String(cString: ptr)
                        if let data = str.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let tokensDict = json["tokens"] as? [String: Any] {
                            if let total = tokensDict["total"] as? Int64, total > 0 {
                                contextTokens = total
                            } else if let total = tokensDict["total"] as? Int, total > 0 {
                                contextTokens = Int64(total)
                            }
                        }
                    }
                }
                sqlite3_finalize(partTokenStmt)
            }
            
            if sqlite3_prepare_v2(db, msgQuery, -1, &msgStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(msgStmt, 1, (id as NSString).utf8String, -1, nil)
                while sqlite3_step(msgStmt) == SQLITE_ROW {
                    if let ptr = sqlite3_column_text(msgStmt, 0) {
                        let str = String(cString: ptr)
                        if let data = str.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let modelID = json["modelID"] as? String, !modelID.isEmpty {
                                if latestModelID == nil {
                                    latestModelID = modelID
                                } else if previousModelID == nil && modelID != latestModelID {
                                    previousModelID = modelID
                                }
                            }
                            if let tokensDict = json["tokens"] as? [String: Any] {
                                if let total = tokensDict["total"] as? Int64, total > 0, contextTokens == 0 {
                                    contextTokens = total
                                } else if let total = tokensDict["total"] as? Int, total > 0, contextTokens == 0 {
                                    contextTokens = Int64(total)
                                }
                                if let inp = tokensDict["input"] as? Int64 { totalInputTokens += inp }
                                else if let inp = tokensDict["input"] as? Int { totalInputTokens += Int64(inp) }
                                if let outp = tokensDict["output"] as? Int64 { totalOutputTokens += outp }
                                else if let outp = tokensDict["output"] as? Int { totalOutputTokens += Int64(outp) }
                            }
                        }
                    }
                }
                sqlite3_finalize(msgStmt)
            }

            let toolQuery = """
                SELECT data FROM part
                WHERE session_id = ? AND json_extract(data, '$.type') = 'tool'
                ORDER BY time_created DESC LIMIT 1;
            """
            var toolStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, toolQuery, -1, &toolStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(toolStmt, 1, (id as NSString).utf8String, -1, nil)
                if sqlite3_step(toolStmt) == SQLITE_ROW,
                   let ptr = sqlite3_column_text(toolStmt, 0) {
                    let str = String(cString: ptr)
                    if let data = str.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let toolName = json["tool"] as? String ?? "tool"
                        let stateDict = json["state"] as? [String: Any]
                        let status = stateDict?["status"] as? String ?? "unknown"
                        recentTool = "\(toolName) · \(status)"
                    }
                }
                sqlite3_finalize(toolStmt)
            }
            
            let finalModel = latestModelID ?? baseModel
            let modelSwitch = previousModelID != nil && finalModel != nil ? "\(previousModelID!) -> \(finalModel!)" : nil
            session = OpencodeSession(id: id, title: baseTitle, timeUpdated: timeUpdated, modelID: finalModel, providerID: nil, cost: 0, tokensInput: totalInputTokens, tokensOutput: totalOutputTokens, recentTool: recentTool, modelSwitch: modelSwitch)
            if contextTokens > 0 {
                session = OpencodeSession(id: id, title: baseTitle, timeUpdated: timeUpdated, modelID: finalModel, providerID: nil, cost: 0, tokensInput: contextTokens, tokensOutput: 0, recentTool: recentTool, modelSwitch: modelSwitch)
            }
        }
        return session
    }
    
    func fetchSessions() -> [OpencodeSession] {
        var sessions: [OpencodeSession] = []
        var db: OpaquePointer?
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            defer { sqlite3_close(db) }
            
            let query = "SELECT id, title, time_updated, model, cost, tokens_input, tokens_output FROM session WHERE parent_id IS NULL ORDER BY time_updated DESC LIMIT 40;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                defer { sqlite3_finalize(stmt) }
                
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(stmt, 0))
                    let title: String
                    if let titlePtr = sqlite3_column_text(stmt, 1) {
                        title = String(cString: titlePtr)
                    } else {
                        title = "Untitled"
                    }
                    let timeUpdated = sqlite3_column_int64(stmt, 2)
                    let modelID: String?
                    if let modelPtr = sqlite3_column_text(stmt, 3) {
                        modelID = String(cString: modelPtr)
                    } else {
                        modelID = nil
                    }
                    let cost = sqlite3_column_double(stmt, 4)
                    let tokensIn = sqlite3_column_int64(stmt, 5)
                    let tokensOut = sqlite3_column_int64(stmt, 6)
                    
                    sessions.append(OpencodeSession(id: id, title: title, timeUpdated: timeUpdated, modelID: modelID, providerID: nil, cost: cost, tokensInput: tokensIn, tokensOutput: tokensOut, recentTool: nil, modelSwitch: nil))
                }
            }
        }
        return sessions
    }
    
    func refreshSessionsList() {
        sessionsMenu.removeAllItems()
        
        let sessions = fetchSessions()
        let archiveDays = SettingsManager.shared.archiveDays
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let archiveThreshold = now - Int64(archiveDays) * 24 * 60 * 60 * 1000
        
        let activeSessions = sessions.filter { $0.timeUpdated > archiveThreshold || archiveDays >= 999 }
        let archivedSessions = sessions.filter { $0.timeUpdated <= archiveThreshold && archiveDays < 999 }
        
        let processStatus = isOpencodeRunning ? "OpenCode 运行中" : "OpenCode 未运行"
        let processItem = NSMenuItem(title: processStatus, action: nil, keyEquivalent: "")
        processItem.isEnabled = false
        sessionsMenu.addItem(processItem)
        sessionsMenu.addItem(NSMenuItem.separator())
        
        let currentTitle = sessions.first(where: { $0.id == selectedSessionID })?.title ?? "未选择"
        let shortTitle = currentTitle.count > 25 ? String(currentTitle.prefix(25)) + "..." : currentTitle
        
        let statusHeader = NSMenuItem(title: "正在监控: \(shortTitle)", action: nil, keyEquivalent: "")
        statusHeader.isEnabled = false
        sessionsMenu.addItem(statusHeader)

        let debugItem = NSMenuItem(title: "状态来源: \(lastStateDebug)", action: nil, keyEquivalent: "")
        debugItem.isEnabled = false
        sessionsMenu.addItem(debugItem)
        sessionsMenu.addItem(NSMenuItem.separator())
        
        let headerItem = NSMenuItem(title: "最近会话 (点击切换):", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        sessionsMenu.addItem(headerItem)
        
        if activeSessions.isEmpty && archivedSessions.isEmpty {
            let emptyItem = NSMenuItem(title: "暂无可用会话 (请先启动 OpenCode)", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            sessionsMenu.addItem(emptyItem)
        } else {
            let topSessions = Array(activeSessions.prefix(8))
            for session in topSessions {
                let title = session.title.count > 38 ? String(session.title.prefix(38)) + "..." : session.title
                let item = NSMenuItem(title: title, action: #selector(sessionSelected(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = session.id
                if session.id == selectedSessionID {
                    item.state = .on
                }
                sessionsMenu.addItem(item)
            }
            
            let remainingActive = activeSessions.dropFirst(8)
            if !remainingActive.isEmpty || !archivedSessions.isEmpty {
                let moreSubmenu = NSMenu()
                for session in remainingActive {
                    let title = session.title.count > 38 ? String(session.title.prefix(38)) + "..." : session.title
                    let item = NSMenuItem(title: title, action: #selector(sessionSelected(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = session.id
                    if session.id == selectedSessionID {
                        item.state = .on
                    }
                    moreSubmenu.addItem(item)
                }
                
                if !archivedSessions.isEmpty {
                    if !remainingActive.isEmpty {
                        moreSubmenu.addItem(NSMenuItem.separator())
                    }
                    let archivedHeader = NSMenuItem(title: "已归档 (\(archiveDays)天前):", action: nil, keyEquivalent: "")
                    archivedHeader.isEnabled = false
                    moreSubmenu.addItem(archivedHeader)
                    
                    for session in archivedSessions.prefix(20) {
                        let title = session.title.count > 38 ? String(session.title.prefix(38)) + "..." : session.title
                        let item = NSMenuItem(title: title, action: #selector(sessionSelected(_:)), keyEquivalent: "")
                        item.target = self
                        item.representedObject = session.id
                        if session.id == selectedSessionID {
                            item.state = .on
                        }
                        moreSubmenu.addItem(item)
                    }
                }
                
                let moreItem = NSMenuItem(title: "更多历史会话...", action: nil, keyEquivalent: "")
                moreItem.submenu = moreSubmenu
                sessionsMenu.addItem(moreItem)
            }
        }
        
        sessionsMenu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "偏好设置...", action: #selector(openSettings(_:)), keyEquivalent: ",")
        settingsItem.target = self
        sessionsMenu.addItem(settingsItem)
        
        let helpItem = NSMenuItem(title: "使用指南...", action: #selector(openOnboarding(_:)), keyEquivalent: "")
        helpItem.target = self
        sessionsMenu.addItem(helpItem)
        
        let toggleVisItem = NSMenuItem(title: "显示/隐藏指示条", action: #selector(toggleVisibility(_:)), keyEquivalent: "h")
        toggleVisItem.target = self
        sessionsMenu.addItem(toggleVisItem)
        
        let refreshItem = NSMenuItem(title: "刷新会话列表", action: #selector(refreshClicked(_:)), keyEquivalent: "r")
        refreshItem.target = self
        sessionsMenu.addItem(refreshItem)

        let apiServiceTitle = apiServiceProcess?.isRunning == true ? "停止 OpenCode API 服务" : (isAPIServiceRunning() ? "OpenCode API 服务已运行" : "启动 OpenCode API 服务")
        let apiServiceItem = NSMenuItem(title: apiServiceTitle, action: #selector(toggleAPIService(_:)), keyEquivalent: "")
        apiServiceItem.target = self
        apiServiceItem.isEnabled = apiServiceProcess?.isRunning == true || !isAPIServiceRunning()
        sessionsMenu.addItem(apiServiceItem)

        let apiServiceStatusItem = NSMenuItem(title: apiServiceStatusText(), action: nil, keyEquivalent: "")
        apiServiceStatusItem.isEnabled = false
        sessionsMenu.addItem(apiServiceStatusItem)

        let confettiItem = NSMenuItem(title: "测试彩带", action: #selector(testConfetti(_:)), keyEquivalent: "")
        confettiItem.target = self
        sessionsMenu.addItem(confettiItem)
        
        sessionsMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出 OpenCode 状态监控", action: #selector(quitClicked(_:)), keyEquivalent: "q")
        quitItem.target = self
        sessionsMenu.addItem(quitItem)
    }
    
    @objc func sessionSelected(_ sender: NSMenuItem) {
        if let sessionID = sender.representedObject as? String {
            selectedSessionID = sessionID
            sessionStartTime = Date()
        }
    }
    
    @objc func openSettings(_ sender: NSMenuItem) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openOnboarding(_ sender: NSMenuItem) {
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController()
        }
        onboardingWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func toggleVisibility(_ sender: NSMenuItem) {
        let isVisible = overlayWindow.alphaValue > 0
        overlayWindow.alphaValue = isVisible ? 0 : 1
    }

    @objc func toggleAPIService(_ sender: NSMenuItem) {
        if isAPIServiceRunning() {
            stopAPIService()
        } else {
            startAPIService()
        }
        refreshSessionsList()
    }
    
    @objc func refreshClicked(_ sender: NSMenuItem) {
        refreshSessionsList()
    }

    @objc func testConfetti(_ sender: NSMenuItem) {
        showConfettiBurst()
    }
    
    @objc func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
    
    func pollSessionState() {
        isOpencodeRunning = checkOpencodeProcess()
        
        if SettingsManager.shared.zenMode {
            let screens = NSScreen.screens
            let inFullscreen = screens.contains { $0.frame.equalTo($0.visibleFrame) }
            overlayWindow.alphaValue = inFullscreen ? 0 : 1
        } else {
            overlayWindow.alphaValue = 1
        }
        
        guard let sessionID = selectedSessionID else {
            DispatchQueue.main.async {
                self.indicatorView.updateState(.inactive)
            }
            return
        }
        
        var db: OpaquePointer?
        var currentState: SessionState = .idle
        var stateDebug = "idle"
        var compactionDetected: (before: Int, after: Int)?
        var freshStopTime: Int64 = 0
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            defer { sqlite3_close(db) }
            
            var hasProviderError = false
            let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
            let providerErrorWindowMs: Int64 = 30 * 60 * 1000
            let errorQuery = "SELECT data, time_created FROM message WHERE session_id = ? ORDER BY time_created DESC LIMIT 30;"
            var errorStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, errorQuery, -1, &errorStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(errorStmt, 1, (sessionID as NSString).utf8String, -1, nil)
                while sqlite3_step(errorStmt) == SQLITE_ROW {
                    let created = sqlite3_column_int64(errorStmt, 1)
                    if nowMs - created > providerErrorWindowMs { continue }
                    if let ptr = sqlite3_column_text(errorStmt, 0) {
                        let str = String(cString: ptr)
                        if let data = str.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let role = json["role"] as? String ?? ""
                            if role == "assistant" && isProviderErrorMessage(json) {
                                hasProviderError = true
                                let error = json["error"] as? [String: Any]
                                let name = error?["name"] as? String ?? "APIError"
                                let data = error?["data"] as? [String: Any]
                                let statusCode = data?["statusCode"] as? Int ?? 0
                                stateDebug = "error: \(name) \(statusCode)"
                            }
                            if role == "assistant", json["error"] == nil {
                                var completedTime = created
                                if let timeDict = json["time"] as? [String: Any] {
                                    if let completed = timeDict["completed"] as? Int64 {
                                        completedTime = completed
                                    } else if let completed = timeDict["completed"] as? Int {
                                        completedTime = Int64(completed)
                                    } else if let completed = timeDict["completed"] as? Double {
                                        completedTime = Int64(completed)
                                    }
                                }

                                if completedTime > 0 && nowMs - completedTime <= 180000 {
                                    freshStopTime = max(freshStopTime, completedTime)
                                }
                            }
                        }
                    }
                }
                sqlite3_finalize(errorStmt)
            }

            if hasProviderError {
                currentState = .error
            } else {
                let inferred = inferSessionState(db: db, sessionID: sessionID)
                currentState = inferred.0
                stateDebug = inferred.1

                let partQuery = """
                    SELECT data, time_created FROM part
                    WHERE session_id = ?
                    ORDER BY time_created DESC LIMIT 10;
                """
                var partStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, partQuery, -1, &partStmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(partStmt, 1, (sessionID as NSString).utf8String, -1, nil)
                    
                    let now = Int64(Date().timeIntervalSince1970 * 1000)
                    while sqlite3_step(partStmt) == SQLITE_ROW {
                        let timeCreated = sqlite3_column_int64(partStmt, 1)
                        let ageMs = now - timeCreated
                        
                        if let ptr = sqlite3_column_text(partStmt, 0) {
                            let str = String(cString: ptr)
                            if let data = str.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                let type = json["type"] as? String ?? ""
                                
                                if type == "step-finish" {
                                    let reason = json["reason"] as? String ?? ""
                                    if reason == "stop" && ageMs <= 180000 {
                                        freshStopTime = max(freshStopTime, timeCreated)
                                    }
                                }
                                
                                if type == "compaction" {
                                    let beforeTokens = json["tokensBefore"] as? Int ?? 0
                                    let afterTokens = json["tokensAfter"] as? Int ?? 0
                                    if beforeTokens > 0 && afterTokens > 0 {
                                        compactionDetected = (beforeTokens, afterTokens)
                                    }
                                }
                            }
                        }
                    }
                    sqlite3_finalize(partStmt)
                }
            }
        }
        
        DispatchQueue.main.async {
            let previousState = self.lastObservedSessionState
            self.lastStateDebug = stateDebug
            self.indicatorView.updateState(currentState)
            if previousState != nil && previousState != .idle && currentState == .idle && freshStopTime > self.lastCelebratedStopTime {
                self.lastCelebratedStopTime = freshStopTime
                self.showConfettiBurst()
            }
            self.lastObservedSessionState = currentState
            self.updateMenuIconColor(currentState)
            self.checkAndShowQuestionChoices(sessionID: sessionID)
            self.updateMultiSessionIndicators()
            self.updateChildDotWindows()
            
            if let compaction = compactionDetected {
                self.showCompactionHUD(beforeTokens: compaction.before, afterTokens: compaction.after)
            }
        }
    }

    func showConfettiBurst() {
        let barFrame = stableBarFrame == .zero ? overlayWindow.frame : stableBarFrame
        let width = max(barFrame.width + 80, 220)
        let height: CGFloat = 140
        let frame = NSRect(
            x: barFrame.midX - width / 2,
            y: barFrame.maxY - 8,
            width: width,
            height: height
        )

        let window = ConfettiWindow(frame: frame)
        confettiWindow = window
        window.orderFrontRegardless()
        window.burst()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak window] in
            window?.orderOut(nil)
            if self?.confettiWindow === window {
                self?.confettiWindow = nil
            }
        }
    }
    
    func checkOpencodeProcess() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-x", "opencode"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func showCompactionHUD(beforeTokens: Int, afterTokens: Int) {
        if compactionHUDWindow == nil {
            compactionHUDWindow = CompactionHUDWindow()
        }
        
        guard let hud = compactionHUDWindow else { return }
        let barFrame = overlayWindow.frame
        let hudWidth: CGFloat = 280
        let hudHeight: CGFloat = 60
        let hudX = barFrame.midX - (hudWidth / 2)
        let hudY = barFrame.maxY + 10
        
        hud.setFrame(NSRect(x: hudX, y: hudY, width: hudWidth, height: hudHeight), display: true)
        hud.updateContent(beforeTokens: beforeTokens, afterTokens: afterTokens)
        
        hud.alphaValue = 0
        hud.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            hud.animator().alphaValue = 1.0
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    hud.animator().alphaValue = 0
                }) {
                    hud.orderOut(nil)
                }
            }
        }
    }
    
    func updateMultiSessionIndicators() {
        guard !isBallHovered, !isAnimating else { return }
        
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let tenMinutesAgo = now - 10 * 60 * 1000
        
        var db: OpaquePointer?
        var recentSessionIDs: [String] = []
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            defer { sqlite3_close(db) }
            
            let query = "SELECT id FROM session WHERE parent_id IS NULL AND time_updated > ? ORDER BY time_updated DESC LIMIT 5;"
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int64(stmt, 1, tenMinutesAgo)
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let ptr = sqlite3_column_text(stmt, 0) {
                        let id = String(cString: ptr)
                        if id != selectedSessionID {
                            recentSessionIDs.append(id)
                        }
                    }
                }
                sqlite3_finalize(stmt)
            }
        }
        
        for window in sessionBallWindows {
            window.orderOut(nil)
        }
        sessionBallWindows.removeAll()
        
        for sessionID in recentSessionIDs.prefix(3) {
            var state: SessionState = .inactive
            
            if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                state = inferSessionState(db: db, sessionID: sessionID).0
                sqlite3_close(db)
            }
            
            let ballWindow = SessionBallWindow(state: state, sessionID: sessionID)
            ballWindow.onHover = { [weak self] isHovering in
                self?.handleBallHover(isHovering, ballWindow: ballWindow)
            }
            ballWindow.orderFrontRegardless()
            sessionBallWindows.append(ballWindow)
        }
        
        activeSessionIDs = recentSessionIDs
        updateSessionBallPositions()
    }
    
    // MARK: - Question Tool Choice Detection & UI
    struct QuestionChoice {
        let requestID: String?
        let callID: String
        let header: String
        let question: String
        let options: [(label: String, description: String)]
    }
    
    var currentQuestionChoices: [QuestionChoice] = []
    var choiceChipViews: [NSView] = []
    var choiceContainerWindow: NSWindow?
    var displayedQuestionCallID: String?
    var answeredQuestionCallIDs = Set<String>()
    var questionRequestsByCallID: [String: String] = [:]
    var questionSessionIDByCallID: [String: String] = [:]
    var questionDirectoryBySessionID: [String: String] = [:]
    enum QuestionSubmitResult {
        case submitted
        case copied
    }
    
    func checkAndShowQuestionChoices(sessionID: String) {
        var db: OpaquePointer?
        var pendingQuestion: QuestionChoice?
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            defer { sqlite3_close(db) }
            
            let query = """
                SELECT data FROM part
                WHERE session_id = ? AND data LIKE '%"tool":"question"%'
                ORDER BY time_created DESC LIMIT 1;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (sessionID as NSString).utf8String, -1, nil)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if let ptr = sqlite3_column_text(stmt, 0) {
                        let str = String(cString: ptr)
                        if let data = str.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let stateDict = json["state"] as? [String: Any],
                               let status = stateDict["status"] as? String,
                               (status == "running" || status == "pending"),
                               let input = stateDict["input"] as? [String: Any],
                               let questions = input["questions"] as? [[String: Any]],
                               let firstQ = questions.first {
                                let callID = json["callID"] as? String ?? ""
                                let header = firstQ["header"] as? String ?? "Question"
                                let question = firstQ["question"] as? String ?? ""
                                var options: [(String, String)] = []
                                if let opts = firstQ["options"] as? [[String: Any]] {
                                    for opt in opts {
                                        let label = opt["label"] as? String ?? ""
                                        let desc = opt["description"] as? String ?? ""
                                        options.append((label, desc))
                                    }
                                }
                                if !options.isEmpty {
                                    self.questionSessionIDByCallID[callID] = sessionID
                                    if let directory = self.fetchSessionDirectory(sessionID) {
                                        self.questionDirectoryBySessionID[sessionID] = directory
                                    }
                                    pendingQuestion = QuestionChoice(requestID: self.questionRequestsByCallID[callID], callID: callID, header: header, question: question, options: options)
                                }
                            }
                        }
                    }
                }
                sqlite3_finalize(stmt)
            }
        }
        
        DispatchQueue.main.async {
            if let q = pendingQuestion {
                if !self.answeredQuestionCallIDs.contains(q.callID), self.displayedQuestionCallID != q.callID {
                    self.showChoiceChips(questions: [q])
                }
            } else {
                self.hideChoiceChips()
            }
        }
    }
    
    func showChoiceChips(questions: [QuestionChoice]) {
        hideChoiceChips()
        displayedQuestionCallID = questions.first?.callID
        if let question = questions.first, question.requestID == nil {
            refreshQuestionRequestMap(sessionID: questionSessionIDByCallID[question.callID] ?? selectedSessionID ?? "", callID: question.callID)
        }
        
        guard let screen = NSScreen.main, let activeQuestion = questions.first else { return }
        let activeCallID = questions.first?.callID
        let barFrame = overlayWindow.frame
        let chipHeight: CGFloat = 28
        let chipPadding: CGFloat = 12
        let chipGap: CGFloat = 8
        let titleHeight: CGFloat = 48
        let containerHeight: CGFloat = titleHeight + chipHeight + 22
        
        // Calculate total width needed
        var totalWidth: CGFloat = 0
        var chipData: [(String, CGFloat)] = []
        for q in questions {
            for opt in q.options {
                let text = opt.label
                let font = NSFont.systemFont(ofSize: 12, weight: .medium)
                let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
                let chipWidth = textWidth + chipPadding * 2 + 16
                chipData.append((text, chipWidth))
                totalWidth += chipWidth + chipGap
            }
        }
        totalWidth -= chipGap // remove last gap
        
        let titleWidth = min(max((activeQuestion.question as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold)]).width + 44, 260), screen.visibleFrame.width - 40)
        let containerWidth = min(max(totalWidth + 24, titleWidth), screen.visibleFrame.width - 40)
        let containerX = barFrame.midX - containerWidth / 2
        let containerY = barFrame.maxY + 8
        
        // Create container window for chips
        let containerRect = NSRect(x: containerX, y: containerY, width: containerWidth, height: containerHeight)
        let containerWin = NSWindow(contentRect: containerRect, styleMask: [.borderless], backing: .buffered, defer: false)
        containerWin.isOpaque = false
        containerWin.backgroundColor = .clear
        containerWin.level = .floating
        containerWin.ignoresMouseEvents = false
        containerWin.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true
        containerWin.contentView = visualEffect

        let headerLabel = NSTextField(labelWithString: activeQuestion.header)
        headerLabel.frame = NSRect(x: 14, y: containerHeight - 26, width: containerWidth - 28, height: 16)
        headerLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        headerLabel.textColor = .secondaryLabelColor
        headerLabel.maximumNumberOfLines = 1
        headerLabel.lineBreakMode = .byTruncatingTail
        visualEffect.addSubview(headerLabel)

        let questionLabel = NSTextField(labelWithString: activeQuestion.question)
        questionLabel.frame = NSRect(x: 14, y: containerHeight - 47, width: containerWidth - 28, height: 18)
        questionLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        questionLabel.textColor = .labelColor
        questionLabel.maximumNumberOfLines = 1
        questionLabel.lineBreakMode = .byTruncatingMiddle
        questionLabel.toolTip = activeQuestion.question
        visualEffect.addSubview(questionLabel)
        
        // Add chips
        var xOffset: CGFloat = 12
        let state = indicatorView.currentState
        for (text, width) in chipData {
            let chipFrame = NSRect(x: xOffset, y: 10, width: width, height: chipHeight)
            let chip = NSButton(frame: chipFrame)
            chip.title = text
            chip.bezelStyle = .rounded
            chip.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            chip.contentTintColor = state.baseColor
            chip.wantsLayer = true
            chip.layer?.cornerRadius = 6
            chip.layer?.backgroundColor = state.baseColor.withAlphaComponent(0.15).cgColor
            chip.target = self
            chip.action = #selector(choiceChipClicked(_:))
            chip.identifier = NSUserInterfaceItemIdentifier(activeCallID ?? "")
            
            // Bounce animation
            chip.alphaValue = 0
            chip.frame.origin.y -= 20
            
            visualEffect.addSubview(chip)
            choiceChipViews.append(chip)
            
            xOffset += width + chipGap
        }
        
        containerWin.alphaValue = 0
        containerWin.orderFrontRegardless()
        choiceContainerWindow = containerWin
        
        // Animate in with bounce
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            containerWin.animator().alphaValue = 1.0
            for chip in choiceChipViews {
                chip.animator().alphaValue = 1.0
                chip.animator().frame.origin.y += 20
            }
        }) {
            // Bounce effect
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                for chip in self.choiceChipViews {
                    chip.animator().frame.origin.y -= 4
                }
            }) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.15
                    for chip in self.choiceChipViews {
                        chip.animator().frame.origin.y += 4
                    }
                })
            }
        }
    }
    
    func hideChoiceChips() {
        for chip in choiceChipViews {
            chip.removeFromSuperview()
        }
        choiceChipViews.removeAll()
        choiceContainerWindow?.orderOut(nil)
        choiceContainerWindow = nil
        displayedQuestionCallID = nil
    }
    
    @objc func choiceChipClicked(_ sender: NSButton) {
        let text = sender.title
        if let callID = sender.identifier?.rawValue, !callID.isEmpty {
            answeredQuestionCallIDs.insert(callID)
            sender.layer?.backgroundColor = NSColor.systemCyan.withAlphaComponent(0.25).cgColor
            sender.title = "提交中..."
            self.submitQuestionAnswer(callID: callID, answer: text) { [weak sender] result in
                guard let sender = sender else { return }
                switch result {
                case .submitted:
                    sender.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.3).cgColor
                    sender.title = "已提交"
                case .copied:
                    sender.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.3).cgColor
                    sender.title = "已复制"
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.hideChoiceChips()
        }
    }

    func refreshQuestionRequestMap(sessionID: String, callID: String) {
        guard !sessionID.isEmpty, !callID.isEmpty else { return }
        questionSessionIDByCallID[callID] = sessionID
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let requestID = self.findQuestionRequestID(sessionID: sessionID, callID: callID) else { return }
            DispatchQueue.main.async {
                self.questionRequestsByCallID[callID] = requestID
            }
        }
    }

    func submitQuestionAnswer(callID: String, answer: String, completion: @escaping (QuestionSubmitResult) -> Void) {
        let sessionID = questionSessionIDByCallID[callID] ?? selectedSessionID ?? ""
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let requestID = self.questionRequestsByCallID[callID] ?? self.findQuestionRequestID(sessionID: sessionID, callID: callID)
            guard let requestID = requestID, self.replyToQuestion(sessionID: sessionID, requestID: requestID, answer: answer) else {
                DispatchQueue.main.async {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(answer, forType: .string)
                    completion(.copied)
                }
                return
            }
            DispatchQueue.main.async {
                self.questionRequestsByCallID[callID] = requestID
                completion(.submitted)
            }
        }
    }

    func findQuestionRequestID(sessionID: String, callID: String) -> String? {
        let directory = questionDirectoryBySessionID[sessionID] ?? fetchSessionDirectory(sessionID)
        for baseURL in discoverOpencodeBaseURLs() {
            if let requestID = fetchQuestionRequestID(baseURL: baseURL.url, auth: baseURL.auth, directory: directory, sessionID: sessionID, callID: callID, path: "/api/session/\(sessionID)/question") {
                return requestID
            }
            if let requestID = fetchQuestionRequestID(baseURL: baseURL.url, auth: baseURL.auth, directory: directory, sessionID: sessionID, callID: callID, path: "/api/question/request") {
                return requestID
            }
            if let requestID = fetchQuestionRequestID(baseURL: baseURL.url, auth: baseURL.auth, directory: directory, sessionID: sessionID, callID: callID, path: "/question") {
                return requestID
            }
        }
        return nil
    }

    func fetchQuestionRequestID(baseURL: URL, auth: String?, directory: String?, sessionID: String, callID: String, path: String) -> String? {
        guard let url = questionURL(baseURL: baseURL, path: path, directory: directory) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 0.8
        applyQuestionHeaders(to: &request, auth: auth, directory: directory)
        guard let data = synchronousData(for: request), let requests = parseQuestionRequests(data) else { return nil }
        let matching = requests.first { req in
            guard (req["sessionID"] as? String) == sessionID else { return false }
            let tool = req["tool"] as? [String: Any]
            return tool?["callID"] as? String == callID || tool?["id"] as? String == callID
        } ?? requests.first { ($0["sessionID"] as? String) == sessionID }
        return matching?["id"] as? String
    }

    func replyToQuestion(sessionID: String, requestID: String, answer: String) -> Bool {
        let directory = questionDirectoryBySessionID[sessionID] ?? fetchSessionDirectory(sessionID)
        for baseURL in discoverOpencodeBaseURLs() {
            let paths = [
                "/api/session/\(sessionID)/question/\(requestID)/reply",
                "/question/\(requestID)/reply"
            ]
            for path in paths {
                guard let url = questionURL(baseURL: baseURL.url, path: path, directory: directory) else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 1.5
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                applyQuestionHeaders(to: &request, auth: baseURL.auth, directory: directory)
                request.httpBody = try? JSONSerialization.data(withJSONObject: ["answers": [[answer]]])
                if let (_, response) = synchronousDataAndResponse(for: request), let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    return true
                }
            }
        }
        return false
    }

    func parseQuestionRequests(_ data: Data) -> [[String: Any]]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let array = json as? [[String: Any]] { return array }
        if let dict = json as? [String: Any] {
            if let array = dict["data"] as? [[String: Any]] { return array }
            if let locationData = dict["data"] as? [String: Any], let array = locationData["data"] as? [[String: Any]] { return array }
        }
        return nil
    }

    func questionURL(baseURL: URL, path: String, directory: String?) -> URL? {
        guard let rawURL = URL(string: path, relativeTo: baseURL), var components = URLComponents(url: rawURL, resolvingAgainstBaseURL: true) else { return nil }
        if let directory = directory, !directory.isEmpty {
            var items = components.queryItems ?? []
            if !items.contains(where: { $0.name == "directory" }) {
                items.append(URLQueryItem(name: "directory", value: directory))
            }
            components.queryItems = items
        }
        return components.url
    }

    func applyQuestionHeaders(to request: inout URLRequest, auth: String?, directory: String?) {
        if let auth = auth {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        if let directory = directory?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            request.setValue(directory, forHTTPHeaderField: "x-opencode-directory")
        }
    }

    func fetchSessionDirectory(_ sessionID: String) -> String? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_close(db) }
        let query = "SELECT directory FROM session WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (sessionID as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW, let ptr = sqlite3_column_text(stmt, 0) else { return nil }
        return String(cString: ptr)
    }

    func synchronousData(for request: URLRequest) -> Data? {
        return synchronousDataAndResponse(for: request)?.0
    }

    func synchronousDataAndResponse(for request: URLRequest) -> (Data, URLResponse)? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (Data, URLResponse)?
        let config = URLSessionConfiguration.ephemeral
        config.connectionProxyDictionary = [:]
        URLSession(configuration: config).dataTask(with: request) { data, response, _ in
            if let data = data, let response = response {
                result = (data, response)
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + (request.timeoutInterval + 0.5))
        return result
    }

    func discoverOpencodeBaseURLs() -> [(url: URL, auth: String?)] {
        var entries = discoverRegisteredOpencodeService()
        var ports = [4096]
        ports.append(contentsOf: discoverOpencodeListeningPorts())
        var seen = Set<Int>()
        entries.append(contentsOf: ports.compactMap { port in
            guard seen.insert(port).inserted else { return nil }
            guard let url = URL(string: "http://127.0.0.1:\(port)") else { return nil }
            return (url: url, auth: nil)
        })
        return entries
    }

    func discoverRegisteredOpencodeService() -> [(url: URL, auth: String?)] {
        let paths = [
            NSString(string: "~/.local/state/opencode/service.json").expandingTildeInPath,
            NSString(string: "~/.config/opencode/service.json").expandingTildeInPath
        ]
        return paths.compactMap { path in
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rawURL = json["url"] as? String,
                  let url = URL(string: rawURL) else { return nil }
            let password = json["password"] as? String
            let username = json["username"] as? String ?? "opencode"
            let auth: String?
            if let password = password {
                let token = "\(username):\(password)".data(using: .utf8)?.base64EncodedString()
                auth = token.map { "Basic \($0)" }
            } else {
                auth = nil
            }
            return (url: url, auth: auth)
        }
    }

    func discoverOpencodeListeningPorts() -> [Int] {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-nP", "-a", "-c", "opencode", "-iTCP", "-sTCP:LISTEN"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return []
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        let pattern = #":(\d+) \(LISTEN\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(output.startIndex..<output.endIndex, in: output)
        return regex.matches(in: output, range: range).compactMap { match in
            guard let portRange = Range(match.range(at: 1), in: output) else { return nil }
            return Int(output[portRange])
        }
    }

    func isAPIServiceRunning() -> Bool {
        if let process = apiServiceProcess, process.isRunning {
            return true
        }
        return usableAPIServiceURL() != nil
    }

    func apiServiceStatusText() -> String {
        if let service = discoverRegisteredOpencodeService().first {
            return "API 服务: \(service.url.absoluteString)"
        }
        if let url = usableAPIServiceURL() {
            return "API 服务: \(url.absoluteString)"
        }
        return apiServiceStatusMessage
    }

    func usableAPIServiceURL() -> URL? {
        let directory = selectedSessionID.flatMap { fetchSessionDirectory($0) }
        return discoverOpencodeBaseURLs().first { service in
            isUsableAPIService(url: service.url, auth: service.auth, directory: directory)
        }?.url
    }

    func isUsableAPIService(url: URL, auth: String?, directory: String?) -> Bool {
        guard let endpoint = questionURL(baseURL: url, path: "/question", directory: directory) else { return false }
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 0.3
        applyQuestionHeaders(to: &request, auth: auth, directory: directory)
        guard let (_, response) = synchronousDataAndResponse(for: request), let http = response as? HTTPURLResponse else { return false }
        return (200...299).contains(http.statusCode)
    }

    func isPortListening(_ port: Int) -> Bool {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-nP", "-iTCP:\(port)", "-sTCP:LISTEN"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    func startAPIService() {
        guard !isAPIServiceRunning() else {
            apiServiceStatusMessage = apiServiceStatusText()
            refreshSessionsList()
            return
        }

        let process = Process()
        process.launchPath = NSString(string: "~/.opencode/bin/opencode").expandingTildeInPath
        process.arguments = ["serve", "--port", "0", "--hostname", "127.0.0.1"]
        process.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            apiServiceProcess = process
            apiServiceStatusMessage = "API 服务启动中..."
            waitForAPIServiceRegistration()
        } catch {
            apiServiceStatusMessage = "API 服务启动失败: \(error.localizedDescription)"
        }
        refreshSessionsList()
    }

    func stopAPIService() {
        if let process = apiServiceProcess, process.isRunning {
            process.terminate()
        }
        apiServiceProcess = nil
        apiServiceStatusMessage = "API 服务已停止"
        refreshSessionsList()
    }

    func waitForAPIServiceRegistration() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            for _ in 0..<50 {
                if let url = self?.usableAPIServiceURL() {
                    DispatchQueue.main.async {
                        self?.apiServiceStatusMessage = "API 服务: \(url.absoluteString)"
                        self?.refreshSessionsList()
                    }
                    return
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            DispatchQueue.main.async {
                self?.apiServiceStatusMessage = "API 服务已启动，但未发现 service.json"
                self?.refreshSessionsList()
            }
        }
    }
}

// MARK: - Main Application Entry
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
