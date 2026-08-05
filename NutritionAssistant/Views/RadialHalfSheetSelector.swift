//
//  RadialHalfSheetSelector.swift
//  NutritionAssistant
//
//  Created by Daniel Becker on 7/11/26.
//

import SwiftUI

struct RadialHalfSheetSelector: View {
    let title: String
    let subtitle: String
    let unit: String
    @Binding var value: Double
    let baseValue: Double
    let onDismiss: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            
            HStack(spacing: 24) {
                Button(action: { if value > 0.5 { value -= 0.5 } }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                
                HStack(alignment: .center, spacing: 8) {
                    TextField("0", value: $value, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: UIScreen.main.bounds.width / 3)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    Text(unit)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { value += 0.5 }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 24)
            
            Button("Submit") {
                onSave()
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 24)
            
            ServingSizeDial(baseSize: baseValue, currentSize: $value)
                .clipped()
        }
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Radial Dial Component
// (Included in this file so the component is fully portable!)
struct ServingSizeDial: View {
    var baseSize: Double
    @Binding var currentSize: Double
    @State private var dragStartSize: Double? = nil
    @State private var dialAnimation: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.7)
    
    var body: some View {
        let safeBase = baseSize > 0 ? baseSize : 1.0
        let rotation = -((currentSize / safeBase) - 1.0) * 45.0
        let centerI = Int(round((currentSize / safeBase - 1.0) * 8.0))
        let startI = centerI - 20
        let endI = centerI + 20
        
        GeometryReader { geo in
            let circleSize = geo.size.width * 1.5
            let centerX = geo.size.width / 2
            let centerY = circleSize / 2 + 35
            
            ZStack {
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.15), lineWidth: 45)
                    ForEach(startI..<endI, id: \.self) { i in
                        let angle = Double(i) * 5.625
                        let isFull = i % 8 == 0
                        let isHalf = i % 8 == 4 || i % 8 == -4
                        let isLabelled = isFull || isHalf
                        let tickValue = safeBase * (1.0 + (Double(i) / 8.0))
                        let tickColor = isFull ? Color.primary : Color.gray.opacity(0.4)
                        
                        if tickValue >= 0 {
                            VStack(spacing: 0) {
                                VStack(spacing: 2) {
                                    Rectangle().fill(tickColor)
                                        .frame(width: isLabelled ? (isFull ? 3 : 2) : 1.5, height: isLabelled ? 18 : 10)
                                    if isLabelled {
                                        Text(String(format: "%g", tickValue))
                                            .font(.caption).fontWeight(.bold).foregroundColor(tickColor).padding(.top, 2)
                                        let servingCount = tickValue / safeBase
                                        Text("\(String(format: "%g", servingCount)) \(servingCount == 1.0 ? "serving" : "servings")")
                                            .font(.system(size: 9)).foregroundColor(isFull ? .secondary : tickColor)
                                    }
                                }
                                .padding(6).contentShape(Rectangle()).onTapGesture {
                                    dialAnimation = .easeInOut(duration: 0.4)
                                    currentSize = tickValue
                                }
                                Spacer()
                            }
                            .frame(height: circleSize)
                            .rotationEffect(.degrees(angle))
                        }
                    }
                }
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(rotation))
                .animation(dialAnimation, value: currentSize)
                .position(x: centerX, y: centerY)
                
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .position(x: centerX, y: 15)
            }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                let dx = location.x - centerX
                let dy = location.y - centerY
                let alpha = (atan2(dy, dx) * 180 / .pi) + 90
                currentSize = max(0, round((currentSize + (safeBase * (alpha / 45.0))) * 2) / 2)
                dialAnimation = .easeInOut(duration: 0.4)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dialAnimation = .interactiveSpring(response: 0.3, dampingFraction: 0.7)
                        if dragStartSize == nil { dragStartSize = currentSize }
                        currentSize = max(0, round(((dragStartSize ?? currentSize) - (value.translation.width * 0.005 * safeBase)) * 2) / 2)
                    }
                    .onEnded { _ in dragStartSize = nil }
            )
        }
    }
}
