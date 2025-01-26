import SwiftUI

struct AppIconSelector: View {
    @StateObject var settings = AppSettings.shared
    @State private var selectedIcon: AppIcon
    
    private let iconManager = IconManager.shared
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 20)
    ]
    
    init() {
        _selectedIcon = State(initialValue: IconManager.shared.currentIcon)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(iconManager.getUnlockedIcons(usageCount: settings.totalUsageCount)) { icon in
                    AppIconSelectorView(icon: icon, isSelected: selectedIcon == icon)
                        .onTapGesture {
                            selectedIcon = icon
                            iconManager.setAppIcon(to: icon)
                        }
                }
            }
            .padding(.vertical, 5)
        }
        .padding(.horizontal)
    }
}

struct AppIconSelectorView: View {
    let icon: AppIcon
    let isSelected: Bool
    @State private var previewImage: NSImage?
    
    var body: some View {
        VStack {
            ZStack {
                if let image = previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: 66, height: 66)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 20, weight: .bold))
                        .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                        .position(x: 48, y: 48)
                }
            }
            
            Text(icon.name)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 70)
        }
        .padding(.vertical, 5)
        .onAppear {
            // 在组件出现时加载图标
            loadImage()
        }
    }
    
    private func loadImage() {
        // 确保在主线程上执行UI操作
        DispatchQueue.main.async {
            if let image = NSImage(named: icon.iconName) {
                self.previewImage = image
                print("成功加载图标: \(icon.iconName)")
            } else {
                print("无法加载图标: \(icon.iconName)")
            }
        }
    }
}

struct AppIconSelector_Previews: PreviewProvider {
    static var previews: some View {
        AppIconSelector()
            .frame(width: 300)
    }
} 