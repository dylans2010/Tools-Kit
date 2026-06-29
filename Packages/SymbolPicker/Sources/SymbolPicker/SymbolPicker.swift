//
//  SymbolPicker.swift
//  SymbolPicker
//
//  Created by Yubo Qin on 2/14/22.
//

import SwiftUI

/// A simple and cross-platform SFSymbol picker for SwiftUI.
public struct SymbolPicker: View {

    // MARK: - Static constants

    private static var gridDimension: CGFloat {
        #if os(iOS)
        return 64
        #elseif os(tvOS)
        return 128
        #elseif os(macOS)
        return 48
        #else
        return 48
        #endif
    }

    private static var symbolSize: CGFloat {
        #if os(iOS)
        return 24
        #elseif os(tvOS)
        return 48
        #elseif os(macOS)
        return 24
        #else
        return 24
        #endif
    }

    private static var symbolCornerRadius: CGFloat {
        if #available(iOS 26, macOS 26, tvOS 26, *) {
            return 15
        } else {
        #if os(iOS)
            return 8
        #elseif os(tvOS)
            return 12
        #elseif os(macOS)
            return 8
        #else
            return 8
        #endif
        }
    }

    private static var unselectedItemBackgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return .clear
        #endif
    }

    private static var selectedItemBackgroundColor: Color {
        #if os(tvOS)
        return Color.gray.opacity(0.3)
        #else
        return Color.accentColor
        #endif
    }

    private static var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #else
        return .clear
        #endif
    }

    private static var deleteButtonTextVerticalPadding: CGFloat {
        #if os(iOS)
        return 12.0
        #else
        return 8.0
        #endif
    }

    // MARK: - Properties
    
    @Binding public var symbol: String?
    @State private var searchText = ""
    @State private var tempSymbol: String?
    @Environment(\.dismiss) private var dismiss

    private let nullable: Bool
    private let autoDismiss: Bool
    private let categories: [SymbolCategory]

    // MARK: - Init

    /// Initializes `SymbolPicker` with a string binding to the selected symbol name and default categories to display.
    ///
    /// - Parameters:
    ///   - symbol: A binding to a `String` that represents the name of the selected symbol.
    ///     When a symbol is picked, this binding is updated with the symbol's name.
    ///   - categories: An array of `SymbolCategory` that represents the categories of the symbols to be displayed.
    ///     Default is `.all`.
    public init(symbol: Binding<String>, dismissOnSelect: Bool = true, categories: [SymbolCategory] = .all) {
        self.init(
            symbol: Binding {
                return symbol.wrappedValue
            } set: { newValue in
                /// As the `nullable` is set to `false`, this can not be `nil`
                if let newValue {
                    symbol.wrappedValue = newValue
                }
            },
            nullable: false,
            dismissOnSelect: dismissOnSelect,
            categories: categories
        )
    }

    /// Initializes `SymbolPicker` with a nullable string binding to the selected symbol name and default categories to display.
    ///
    /// - Parameters:
    ///   - symbol: A binding to a `String` that represents the name of the selected symbol.
    ///     When a symbol is picked, this binding is updated with the symbol's name. When no symbol
    ///     is picked, the value will be `nil`.
    ///   - categories: An array of `SymbolCategory` that represents the categories of the symbols to be displayed.
    ///     Default is `.all`.
    public init(symbol: Binding<String?>, dismissOnSelect: Bool = true, categories: [SymbolCategory] = .all) {
        self.init(symbol: symbol, nullable: true, dismissOnSelect: dismissOnSelect, categories: categories)
    }

    /// Private designated initializer.
    private init(symbol: Binding<String?>,
                 nullable: Bool, dismissOnSelect: Bool = true, categories: [SymbolCategory] ) {
        self._symbol = symbol
        self.autoDismiss = dismissOnSelect
        self.nullable = nullable
        self.categories = categories
    }

    // MARK: - View Components

    @ViewBuilder
    private var searchableSymbolGrid: some View {
        #if os(iOS)
        symbolGrid
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        #elseif os(tvOS)
        VStack {
            TextField(LocalizedString("search_placeholder"), text: $searchText)
                .padding(.horizontal, 8)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            symbolGrid
        }

        /// `searchable` is crashing on tvOS 16. What the hell aPPLE?
        ///
        /// symbolGrid
        ///     .searchable(text: $searchText, placement: .automatic)
        #elseif os(macOS)
        VStack(spacing: 0) {
            HStack {
                TextField(LocalizedString("search_placeholder"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18.0))
                    .disableAutocorrection(true)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 16.0, height: 16.0)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            symbolGrid

            if canDeleteIcon {
                Divider()
                HStack {
                    Spacer()
                    deleteButton
                        .padding(.horizontal)
                        .padding(.vertical, 8.0)
                }
            }
        }
        #else
        symbolGrid
            .searchable(text: $searchText, placement: .automatic)
        #endif
    }

    private var symbolGrid: some View {
        ScrollView {
            #if os(tvOS) || os(watchOS)
            if canDeleteIcon {
                deleteButton
            }
            #endif

            LazyVGrid(columns: [GridItem(.adaptive(minimum: Self.gridDimension, maximum: Self.gridDimension))]) {
                ForEach(symbols.filter {
                    (categories == .all || !$0.categories.isDisjoint(with: categories))
                    && (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText))
                }) { thisSymbol in
                    Button {
                        if autoDismiss {
                            symbol = thisSymbol.name
                            dismiss()
                        } else {
                            tempSymbol = thisSymbol.name
                        }
                    } label: {
                        if (autoDismiss && thisSymbol.name == symbol) || (!autoDismiss && tempSymbol == thisSymbol.name) {
                            Image(systemName: thisSymbol.name)
                                .font(.system(size: Self.symbolSize))
                                #if os(tvOS)
                                .frame(minWidth: Self.gridDimension, minHeight: Self.gridDimension)
                                #else
                                .frame(maxWidth: .infinity, minHeight: Self.gridDimension)
                                #endif
                                .coloredBackground(Self.selectedItemBackgroundColor, cornerRadius: Self.symbolCornerRadius)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: thisSymbol.name)
                                .font(.system(size: Self.symbolSize))
                                .frame(maxWidth: .infinity, minHeight: Self.gridDimension)
                                .coloredBackground(nil, cornerRadius: Self.symbolCornerRadius)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    #if os(iOS)
                    .hoverEffect(.lift)
                    #endif
                }
            }
            .padding(.horizontal)

            #if os(iOS) || os(visionOS)
            /// Avoid last row being hidden.
            if canDeleteIcon {
                Spacer()
                    .frame(height: Self.gridDimension * 2)
            }
            #endif
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            symbol = nil
            dismiss()
        } label: {
            Label(LocalizedString("remove_symbol"), systemImage: "trash")
                #if !os(tvOS) && !os(macOS)
                .frame(maxWidth: .infinity)
                #endif
                #if !os(watchOS)
                .padding(.vertical, Self.deleteButtonTextVerticalPadding)
                #endif
                .background(Self.unselectedItemBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
        }
    }

    public var body: some View {
        #if !os(macOS)
        NavigationView {
            ZStack {
                #if os(iOS)
                Self.backgroundColor.edgesIgnoringSafeArea(.all)
                #endif
                searchableSymbolGrid

                #if os(iOS) || os(visionOS)
                if canDeleteIcon {
                    VStack {
                        Spacer()

                        deleteButton
                            .padding()
                            .background(.regularMaterial)
                    }
                }
                #endif
            }
            #if os(iOS)
            .navigationTitle("Symbol Picker")
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if !os(tvOS)
            /// tvOS can use back button on remote
            .toolbar {
                if #available(iOS 26.0, *) {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                }
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26, *) {
                        Button(LocalizedString("cancel"), systemImage: "xmark") {
                            dismiss()
                        }
                    } else {
                        Button(LocalizedString("cancel")) {
                            dismiss()
                        }
                    }
                }
                if !autoDismiss {
                    ToolbarItem(placement: .confirmationAction) {
                        if #available(iOS 26, *) {
                            Button(LocalizedString("done"), systemImage: "checkmark") {
                                symbol = tempSymbol
                                dismiss()
                            }
                            .buttonStyle(.glassProminent)
                        } else {
                            Button(LocalizedString("done")) {
                                symbol = tempSymbol
                                dismiss()
                            }
                        }
                    }
                }
            }
            #endif
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if !autoDismiss {
                tempSymbol = symbol
            }
        }
        .onChange(of: symbol) { _ in
            if !autoDismiss {
                tempSymbol = symbol
            }
        }
        #else
        searchableSymbolGrid
            .frame(width: 540, height: 340, alignment: .center)
            .background(.regularMaterial)
            .onAppear {
                if !autoDismiss {
                    tempSymbol = symbol
                }
            }
            .onChange(of: symbol) { _ in
                if !autoDismiss {
                    tempSymbol = symbol
                }
            }
        #endif
    }

    private var canDeleteIcon: Bool {
        false
    }

    private var symbols: [Symbol] {
        Symbols.shared.symbols
    }

}

private func LocalizedString(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}

// MARK: - Debug

#if DEBUG
#Preview("Normal") {
    struct Preview: View {
        @State private var symbol: String? = "square.and.arrow.up"
        var body: some View {
            SymbolPicker(symbol: $symbol)
        }
    }
    return Preview()
}

#Preview("No Autodismiss") {
    struct Preview: View {
        @State private var symbol: String = "square.and.arrow.up"
        @State private var show = false
        var body: some View {
            VStack {
                Image(systemName: symbol)
                Button("Show") { show = true }
                    .sheet(isPresented: $show) {
                        SymbolPicker(symbol: $symbol, dismissOnSelect: false)
                    }
                    .onAppear {
                        show = true
                    }
            }
        }
    }
    return Preview()
}

#Preview("Filter Example") {
    Symbols.shared.filter = { $0.contains(".circle") }
    
    struct Preview: View {
        @State private var symbol: String? = "square.and.arrow.up.circle.fill"
        var body: some View {
            SymbolPicker(symbol: $symbol)
        }
    }
    return Preview()
}

#Preview("Categories Example") {
    struct Preview: View {
        @State private var symbol: String = ""
        var body: some View {
            SymbolPicker(symbol: $symbol, categories: [.maps, .math])
        }
    }
    return Preview()
}

#endif

fileprivate extension View {
    @ViewBuilder func coloredBackground(_ color: Color?, cornerRadius: CGFloat) -> some View {
        if #available(iOS 26, macOS 26, visionOS 26, tvOS 26, *) {
#if os(visionOS)
            self
                .glassEffect(.clear.tint(color).interactive(), in: Circle())
#else
            self
                .glassEffect(.clear.tint(color).interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
#endif
        } else {
#if os(visionOS)
            self
                .background(color)
                .clipShape(Circle())
#else
            self
                .background(color)
                .cornerRadius(cornerRadius)
#endif
        }
    }
}
