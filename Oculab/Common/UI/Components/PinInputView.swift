//
//  PinInputView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import SwiftUI

// MARK: - PIN Input View Component
struct PinInputView: View {
    @Binding var pin: String
    let maxLength: Int
    let isSecure: Bool
    let onComplete: ((String) -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        pin: Binding<String>,
        maxLength: Int = AppConstants.pinLength,
        isSecure: Bool = true,
        onComplete: ((String) -> Void)? = nil
    ) {
        self._pin = pin
        self.maxLength = maxLength
        self.isSecure = isSecure
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // PIN display dots
            pinDisplayView
            
            // Hidden text field for input
            hiddenTextField
        }
        .onTapGesture {
            isFocused = true
        }
        .onChange(of: pin) { _, newValue in
            if newValue.count == maxLength {
                onComplete?(newValue)
            }
        }
    }
    
    // MARK: - View Components
    private var pinDisplayView: some View {
        HStack(spacing: 16) {
            ForEach(0..<maxLength, id: \.self) { index in
                pinDotView(for: index)
            }
        }
    }
    
    private func pinDotView(for index: Int) -> some View {
        Circle()
            .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 16, height: 16)
            .scaleEffect(index < pin.count ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: pin.count)
    }
    
    private var hiddenTextField: some View {
        TextField(AppValue.empty, text: $pin)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .opacity(0)
            .frame(width: 1, height: 1)
            .onChange(of: pin) { _, newValue in
                // Limit input to maxLength and numbers only
                let filtered = String(newValue.prefix(maxLength).filter { $0.isNumber })
                if filtered != newValue {
                    pin = filtered
                }
            }
    }
}

// MARK: - PIN Number Pad Component
struct PinNumberPadView: View {
    @Binding var pin: String
    let maxLength: Int
    let onComplete: ((String) -> Void)?
    
    init(
        pin: Binding<String>,
        maxLength: Int = AppConstants.pinLength,
        onComplete: ((String) -> Void)? = nil
    ) {
        self._pin = pin
        self.maxLength = maxLength
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Number grid
            ForEach(AppConstants.pinNumbers, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { number in
                        numberButton(number)
                    }
                }
            }
            
            // Bottom row with 0 and delete
            HStack(spacing: 24) {
                // Empty space
                Color.clear
                    .frame(width: 60, height: 60)
                
                // Zero button
                numberButton("0")
                
                // Delete button
                deleteButton
            }
        }
    }
    
    // MARK: - Button Components
    private func numberButton(_ number: String) -> some View {
        Button(action: { addNumber(number) }) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(pin.count >= maxLength)
    }
    
    private var deleteButton: some View {
        Button(action: deleteLastNumber) {
            Image(systemName: AppIcon.deleteLeft)
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(pin.isEmpty)
    }
    
    // MARK: - Actions
    private func addNumber(_ number: String) {
        guard pin.count < maxLength else { return }
        
        pin += number
        
        if pin.count == maxLength {
            onComplete?(pin)
        }
    }
    
    private func deleteLastNumber() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }
}

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        PinInputView(
            pin: .constant("12"),
            onComplete: { pin in
                print("PIN completed: \(pin)")
            }
        )
        
        Divider()
        
        PinNumberPadView(
            pin: .constant("123"),
            onComplete: { pin in
                print("PIN completed: \(pin)")
            }
        )
    }
    .padding()
}
