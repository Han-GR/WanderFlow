import SwiftUI

private struct TextInputTuningModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.none)
            .keyboardType(.default)
            .submitLabel(.done)
    }
}

private struct SearchInputTuningModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.none)
    }
}

private struct NumericInputTuningModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.none)
    }
}

extension View {
    func tunedTextInput() -> some View {
        modifier(TextInputTuningModifier())
    }
    
    func tunedSearchInput() -> some View {
        modifier(SearchInputTuningModifier())
    }
    
    func tunedNumericInput() -> some View {
        modifier(NumericInputTuningModifier())
    }
}
