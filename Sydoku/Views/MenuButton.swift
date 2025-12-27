import SwiftUI

/// Environment key for menu dismiss action.
private struct MenuDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var dismissMenu: (() -> Void)? {
        get { self[MenuDismissKey.self] }
        set { self[MenuDismissKey.self] = newValue }
    }
}

/// Environment key for menu background color (for MenuDivider).
private struct MenuBackgroundColorKey: EnvironmentKey {
    static let defaultValue: Color = .clear
}

extension EnvironmentValues {
    var menuBackgroundColor: Color {
        get { self[MenuBackgroundColorKey.self] }
        set { self[MenuBackgroundColorKey.self] = newValue }
    }
}

/// A reusable menu button that displays a popover menu.
///
/// This component provides a consistent menu experience across the app with:
/// - Popover presentation (no timer flashing)
/// - Optional badge indicator for active filters/states
/// - Themed appearance
struct MenuButton<Content: View>: View {
    let icon: String
    let iconSize: CGFloat
    let badge: Int?
    let theme: Theme
    let backgroundColor: Color
    let onDismiss: (() -> Void)?
    @ViewBuilder let content: () -> Content
    
    @State private var isShowingMenu = false
    
    /// Creates a custom menu button.
    ///
    /// - Parameters:
    ///   - icon: The SF Symbol name for the button icon
    ///   - iconSize: The size of the icon (default: 40)
    ///   - badge: Optional badge count to display (e.g., active filter count)
    ///   - theme: The app theme for styling
    ///   - backgroundColor: Custom background color for the menu (default: theme.cellBackgroundColor)
    ///   - onDismiss: Optional callback when menu is dismissed
    ///   - content: The menu content builder
    init(
        icon: String,
        iconSize: CGFloat = 40,
        badge: Int? = nil,
        theme: Theme,
        backgroundColor: Color? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.badge = badge
        self.theme = theme
        self.backgroundColor = backgroundColor ?? theme.cellBackgroundColor
        self.onDismiss = onDismiss
        self.content = content
    }
    
    var body: some View {
        Button(action: {
            isShowingMenu = true
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(theme.primaryAccent)
                    .frame(width: 44, height: 44)
                
                // Badge indicator (if provided)
                if let badge = badge, badge > 0 {
                    // Adapt badge size and position based on icon size
                    let isSmallIcon = iconSize <= 20
                    let badgeSize: CGFloat = isSmallIcon ? 15 : 18
                    let fontSize: CGFloat = isSmallIcon ? 10 : 11
                    let xOffset: CGFloat = isSmallIcon ? -2 : 6
                    let yOffset: CGFloat = isSmallIcon ? 6 : -6
                    
                    Text("\(badge)")
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(
                            Circle()
                                .fill(theme.primaryAccent)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        )
                        .offset(x: xOffset, y: yOffset)
                        .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingMenu) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content()
                        .environment(\.menuBackgroundColor, backgroundColor)
                }
                .padding(.vertical, 8)
            }
            .frame(minWidth: 220)
            .background(backgroundColor)
            .presentationCompactAdaptation(.popover)
            .environment(\.dismissMenu) { isShowingMenu = false }
        }
        .onChange(of: isShowingMenu) { _, showing in
            if !showing {
                onDismiss?()
            }
        }
    }
}

/// A menu section with a title.
struct MenuSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            
            content()
        }
    }
}

/// A menu item button.
struct MenuItem: View {
    let icon: String?
    let title: String
    let isSelected: Bool
    let isDestructive: Bool
    let disabled: Bool
    let dismissOnTap: Bool
    let action: () -> Void
    
    @Environment(\.theme) var theme
    @Environment(\.dismissMenu) private var dismissMenu
    
    init(
        icon: String? = nil,
        title: String,
        isSelected: Bool = false,
        isDestructive: Bool = false,
        disabled: Bool = false,
        dismissOnTap: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.isDestructive = isDestructive
        self.disabled = disabled
        self.dismissOnTap = dismissOnTap
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
            if dismissOnTap {
                dismissMenu?()
            }
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                        .frame(width: 24)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.primaryAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
    
    private var iconColor: Color {
        if disabled {
            return theme.secondaryText.opacity(0.5)
        } else if isDestructive {
            return .red
        } else {
            return theme.primaryAccent
        }
    }
    
    private var textColor: Color {
        if disabled {
            return theme.secondaryText.opacity(0.5)
        } else if isDestructive {
            return .red
        } else {
            return theme.primaryText
        }
    }
}

/// A menu divider.
struct MenuDivider: View {
    @Environment(\.menuBackgroundColor) private var menuBackgroundColor
    
    var body: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1.5)
            .padding(.vertical, 6)
    }
    
    /// Returns a contrasting color based on the menu's background color luminance.
    private var dividerColor: Color {
        // Determine if the background is light or dark based on luminance
        let isLight = menuBackgroundColor.isLight
        
        // Return contrasting color: dark divider for light backgrounds, light divider for dark backgrounds
        return isLight ? Color.black.opacity(0.15) : Color.white.opacity(0.2)
    }
}

#Preview("Menu Button") {
    VStack(spacing: 40) {
        // Without badge
        MenuButton(
            icon: "line.3.horizontal.decrease.circle",
            iconSize: 20,
            badge: nil,
            theme: Theme()
        ) {
            MenuSection(title: "Options") {
                MenuItem(title: "Option 1", action: {})
                MenuItem(title: "Option 2", isSelected: true, action: {})
                MenuItem(title: "Option 3", action: {})
            }
        }
        
        // With badge
        MenuButton(
            icon: "line.3.horizontal.decrease.circle",
            iconSize: 20,
            badge: 3,
            theme: Theme()
        ) {
            MenuSection(title: "Filters") {
                MenuItem(title: "Filter 1", isSelected: true, action: {})
                MenuItem(title: "Filter 2", isSelected: true, action: {})
                MenuItem(title: "Filter 3", isSelected: true, action: {})
            }
            
            MenuDivider()
            
            MenuSection(title: nil) {
                MenuItem(
                    icon: "xmark.circle",
                    title: "Clear All",
                    isDestructive: true,
                    action: {}
                )
            }
        }
        
        // High badge count
        MenuButton(
            icon: "line.3.horizontal.decrease.circle",
            iconSize: 20,
            badge: 9,
            theme: Theme()
        ) {
            MenuSection(title: "Many Filters") {
                MenuItem(title: "Item 1", isSelected: true, action: {})
                MenuItem(title: "Item 2", isSelected: true, action: {})
                MenuItem(title: "Item 3", isSelected: true, action: {})
            }
        }
    }
    .padding()
    .environment(\.theme, Theme())
}

