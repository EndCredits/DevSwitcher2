//
//  CompatibilityExtensions.swift
//  DevSwitcher2
//
//  Created for macOS version compatibility
//

import Foundation
import AppKit
import SwiftUI

// MARK: - NSApplication Compatibility Extension
extension NSApplication {
    /// 兼容性activate方法，支持macOS 12.0+
    func activateCompat() {
        if #available(macOS 14.0, *) {
            self.activate()
        } else {
            self.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - macOS Version Utilities
struct MacOSVersion {
    static let current = ProcessInfo.processInfo.operatingSystemVersion
    
    static var isMontereyOrLater: Bool {
        return current.majorVersion >= 12
    }
    
    static var isVenturaOrLater: Bool {
        return current.majorVersion >= 13
    }
    
    static var isSonomaOrLater: Bool {
        return current.majorVersion >= 14
    }
    
    static var isTahoeOrLater: Bool {
        return current.majorVersion >= 26
    }
    
    static var displayString: String {
        return "\(current.majorVersion).\(current.minorVersion).\(current.patchVersion)"
    }
}

// MARK: - Liquid Glass Compatibility Extensions
enum AdaptiveGlassVariant {
    case regular
    case clear
}

enum AdaptiveMaterialFallback {
    case ultraThin
    case thin
    case regular
    case clear

    @ViewBuilder
    func fillView<S: Shape>(in shape: S) -> some View {
        switch self {
        case .ultraThin:
            shape.fill(.ultraThinMaterial)
        case .thin:
            shape.fill(.thinMaterial)
        case .regular:
            shape.fill(.regularMaterial)
        case .clear:
            shape.fill(Color.clear)
        }
    }
}

struct AdaptiveGlassContainer<Content: View>: View {
    let spacing: CGFloat?
    let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

extension View {
    /// Applies macOS 26+ Liquid Glass effect with graceful fallback to SwiftUI Material on macOS 12-15.
    @ViewBuilder
    func adaptiveGlass<S: Shape>(
        variant: AdaptiveGlassVariant = .regular,
        tint: Color? = nil,
        interactive: Bool = false,
        in shape: S,
        fallbackMaterial: AdaptiveMaterialFallback = .regular,
        fallbackStrokeColor: Color? = nil,
        fallbackStrokeWidth: CGFloat = 1
    ) -> some View {
        if #available(macOS 26.0, *) {
            let baseGlass: Glass = (variant == .regular) ? .regular : .clear
            let tintedGlass = tint != nil ? baseGlass.tint(tint) : baseGlass
            let finalGlass = interactive ? tintedGlass.interactive(true) : tintedGlass
            self.glassEffect(finalGlass, in: shape)
        } else {
            self
                .background(
                    ZStack {
                        fallbackMaterial.fillView(in: shape)
                        if let tint = tint {
                            shape.fill(tint)
                        }
                    }
                )
                .overlay(
                    Group {
                        if let strokeColor = fallbackStrokeColor {
                            shape.stroke(strokeColor, lineWidth: fallbackStrokeWidth)
                        }
                    }
                )
        }
    }

    /// Applies `.glassEffectID` on macOS 26+ for smooth Liquid Glass morphing transitions.
    @ViewBuilder
    func adaptiveGlassID<ID: Hashable & Sendable>(_ id: ID?, in namespace: Namespace.ID) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// Applies `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)` on macOS 26+, falling back to `.bordered` / `.borderedProminent`.
    @ViewBuilder
    func adaptiveGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }
}
