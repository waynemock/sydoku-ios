import SwiftUI

/// A generic, reusable toast notification view that can slide in from any edge.
///
/// `ToastView` displays a temporary notification that slides in from a specified edge,
/// remains visible for a duration, and then slides back out. It supports custom content,
/// colors, and positioning.
///
/// Example usage:
/// ```swift
/// @State private var showToast = false
///
/// ToastView(
///     isPresented: $showToast,
///     edge: .top,
///     offset: 80
/// ) {
///     HStack(spacing: 8) {
///         Image(systemName: "checkmark.circle.fill")
///         Text("Success!")
///     }
/// }
/// ```
struct ToastView<Content: View>: View {
    /// Whether the toast is currently presented.
    @Binding var isPresented: Bool
    
    /// The edge from which the toast slides in.
    let edge: Edge
    
    /// The distance from the edge (for top/bottom: vertical offset; for leading/trailing: horizontal offset).
    let offset: CGFloat
    
    /// The duration (in seconds) the toast remains visible before auto-dismissing.
    /// Set to `nil` to disable auto-dismiss.
    let duration: TimeInterval?
    
    /// The content of the toast.
    let content: Content
    
    /// The alignment of the toast within its container.
    private var alignment: Alignment {
        switch edge {
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
    
    /// The transition animation based on the edge.
    private var transition: AnyTransition {
        .move(edge: edge).combined(with: .opacity)
    }
    
    /// Creates a new toast view.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control the visibility of the toast.
    ///   - edge: The edge from which the toast slides in (default: `.top`).
    ///   - offset: The distance from the edge in points (default: `80`).
    ///   - duration: How long the toast remains visible before auto-dismissing. Pass `nil` to disable auto-dismiss (default: `2.0`).
    ///   - content: A view builder that creates the content of the toast.
    init(
        isPresented: Binding<Bool>,
        edge: Edge = .top,
        offset: CGFloat = 20,
        duration: TimeInterval? = 3.0,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.edge = edge
        self.offset = offset
        self.duration = duration
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: alignment) {
            if isPresented {
                toastContent
                    .transition(transition)
                    .onAppear {
                        guard let duration = duration else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .allowsHitTesting(false)
    }
    
    /// The positioned toast content based on the edge.
    @ViewBuilder
    private var toastContent: some View {
        switch edge {
        case .top:
            VStack {
                content
                Spacer()
            }
            .padding(.top, offset)
            
        case .bottom:
            VStack {
                Spacer()
                content
            }
            .padding(.bottom, offset)
            
        case .leading:
            HStack {
                content
                Spacer()
            }
            .padding(.leading, offset)
            
        case .trailing:
            HStack {
                Spacer()
                content
            }
            .padding(.trailing, offset)
        }
    }
}

// MARK: - Toast Modifier

/// A view modifier that adds a toast notification to any view.
struct ToastModifier<ToastContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let edge: Edge
    let offset: CGFloat
    let duration: TimeInterval?
    let toastContent: ToastContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ToastView(
                isPresented: $isPresented,
                edge: edge,
                offset: offset,
                duration: duration
            ) {
                toastContent
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents a toast notification over this view.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control the visibility of the toast.
    ///   - edge: The edge from which the toast slides in (default: `.top`).
    ///   - offset: The distance from the edge in points (default: `80`).
    ///   - duration: How long the toast remains visible before auto-dismissing. Pass `nil` to disable auto-dismiss (default: `2.0`).
    ///   - content: A view builder that creates the content of the toast.
    /// - Returns: A view with the toast overlay.
    func toast<Content: View>(
        isPresented: Binding<Bool>,
        edge: Edge = .top,
        offset: CGFloat = 20,
        duration: TimeInterval? = 3.0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            edge: edge,
            offset: offset,
            duration: duration,
            toastContent: content()
        ))
    }
}

// MARK: - Predefined Toast Styles

extension ToastView where Content == AnyView {
    /// Creates a toast with a message and optional icon.
    ///
    /// - Parameters:
    ///   - isPresented: Binding to control the visibility of the toast.
    ///   - message: The text message to display.
    ///   - systemImage: Optional SF Symbol name for an icon.
    ///   - backgroundColor: The background color of the toast.
    ///   - foregroundColor: The text and icon color.
    ///   - edge: The edge from which the toast slides in.
    ///   - offset: The distance from the edge in points.
    ///   - duration: How long the toast remains visible before auto-dismissing.
    static func message(
        isPresented: Binding<Bool>,
        message: String,
        systemImage: String? = nil,
        backgroundColor: Color,
        foregroundColor: Color = .white,
        edge: Edge = .top,
        offset: CGFloat = 20,
        duration: TimeInterval? = 3.0
    ) -> ToastView<AnyView> {
        ToastView(
            isPresented: isPresented,
            edge: edge,
            offset: offset,
            duration: duration
        ) {
            AnyView(
                HStack(spacing: 8) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .font(.title3)
                    }
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
                .shadow(radius: 8)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    struct ToastPreview: View {
        @State private var showTopToast = false
        @State private var showBottomToast = false
        @State private var showLeadingToast = false
        @State private var showTrailingToast = false
        @Environment(\.theme) var theme
        
        var body: some View {
            VStack(spacing: 20) {
                Button("Show Top Toast") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showTopToast = true
                    }
                }
                
                Button("Show Bottom Toast") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showBottomToast = true
                    }
                }
                
                Button("Show Leading Toast") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showLeadingToast = true
                    }
                }
                
                Button("Show Trailing Toast") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showTrailingToast = true
                    }
                }
            }
            .toast(isPresented: $showTopToast, edge: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Success from Top!")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.green))
                .shadow(radius: 8)
            }
            .toast(isPresented: $showBottomToast, edge: .bottom) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                    Text("Info from Bottom!")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.blue))
                .shadow(radius: 8)
            }
            .toast(isPresented: $showLeadingToast, edge: .leading, offset: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title3)
                    Text("From Leading!")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.orange))
                .shadow(radius: 8)
            }
            .toast(isPresented: $showTrailingToast, edge: .trailing, offset: 20) {
                HStack(spacing: 8) {
                    Text("From Trailing!")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.purple))
                .shadow(radius: 8)
            }
        }
    }
    
    return ToastPreview()
        .environment(\.theme, Theme())
}
