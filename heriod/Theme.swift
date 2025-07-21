// Theme.swift
// Color theme based on shadcn design system
// Converted from OKLCH to hex values for iOS compatibility

import SwiftUI

struct AppTheme {
    // MARK: - Core Colors (Light Mode)
    static let background = Color(hex: "ffffff")
    static let foreground = Color(hex: "09090b")
    static let card = Color(hex: "ffffff") 
    static let cardForeground = Color(hex: "09090b")
    
    // Primary colors (rose from shadcn theme)
    static let primary = Color(hex: "e11d48")
    static let primaryForeground = Color(hex: "fdf2f8")
    
    // Secondary colors
    static let secondary = Color(hex: "f4f4f5")
    static let secondaryForeground = Color(hex: "18181b")
    
    // Muted colors
    static let muted = Color(hex: "f4f4f5")
    static let mutedForeground = Color(hex: "71717a")
    
    // Accent colors
    static let accent = Color(hex: "f4f4f5")
    static let accentForeground = Color(hex: "18181b")
    
    // Destructive
    static let destructive = Color(hex: "dc2626")
    static let destructiveForeground = Color(hex: "fef2f2")
    
    // Border and input
    static let border = Color(hex: "e4e4e7")
    static let input = Color(hex: "e4e4e7")
    static let ring = Color(hex: "e11d48")
    
    // MARK: - Dark Mode Colors
    struct Dark {
        static let background = Color(hex: "09090b")
        static let foreground = Color(hex: "fafafa") 
        static let card = Color(hex: "18181b")
        static let cardForeground = Color(hex: "fafafa")
        
        static let secondary = Color(hex: "262626")
        static let secondaryForeground = Color(hex: "fafafa")
        
        static let muted = Color(hex: "262626")
        static let mutedForeground = Color(hex: "a1a1aa")
        
        static let accent = Color(hex: "262626")
        static let accentForeground = Color(hex: "fafafa")
        
        static let destructive = Color(hex: "b91c1c")
        static let destructiveForeground = Color(hex: "fef2f2")
        
        static let border = Color(hex: "ffffff").opacity(0.1)
        static let input = Color(hex: "ffffff").opacity(0.15)
    }
    
    // MARK: - Chart Colors
    static let chart1 = Color(hex: "f97316")
    static let chart2 = Color(hex: "06b6d4") 
    static let chart3 = Color(hex: "8b5cf6")
    static let chart4 = Color(hex: "f59e0b")
    static let chart5 = Color(hex: "ef4444")
    
    // MARK: - Convenience Methods
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.background : background
    }
    
    static func foregroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.foreground : foreground
    }
    
    static func cardColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.card : card
    }
    
    static func primaryColor(for colorScheme: ColorScheme) -> Color {
        primary // Same in both modes
    }
}