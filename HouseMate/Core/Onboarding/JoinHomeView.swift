//
//  JoinHomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 18/08/2026.
//

import SwiftUI

@Observable
class JoinHomeViewModel {
    var inviteCode: String = ""
}

struct JoinHomeView: View {
    
    @State var viewModel: JoinHomeViewModel
    @FocusState private var isCodeFocused: Bool
    
    private let codeLength = 6
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    .blue,
                    .teal,
                    .blue.opacity(0.08),
                    .blue.opacity(0.002),
                    .black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                pictures
                header
                    .padding(.horizontal, 24)
              
                
                inviteCodeSection
                    .padding(.horizontal, 24)
                
                
                Spacer()
                
                joinButton
                    .padding(.horizontal, 24)
                    .padding(.top, 70)
            }
            .padding(.top, 70)
            .padding(.bottom, 140)
                    }
        .onAppear {
            isCodeFocused = true
        }
    }
    
    
    
    
    private var header: some View {
        VStack(spacing: 8) {
            
            Text("Join a home")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter the invite code shared by\none of your housemates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var pictures: some View {
        GeometryReader { geo in
            Image("house3")
                .resizable()
                .scaledToFill()
                .frame(
                    width: geo.size.width,
                    height: geo.size.height
                )
                .clipped()
        }
        .frame(height: 400)
    }
    
    
    private var inviteCodeSection: some View {
        VStack(spacing: 14) {
            
            Text("Invite code")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack {
                
                TextField("", text: $viewModel.inviteCode)
                    .focused($isCodeFocused)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .opacity(0.001)
                    .onChange(of: viewModel.inviteCode) { _, newValue in
                        formatCode(newValue)
                    }
                
                HStack(spacing: 10) {
                    
                    ForEach(0..<codeLength, id: \.self) { index in
                        
                        Text(character(at: index))
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(width: 45, height: 55)
                            .glassEffect()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isCodeFocused = true
                }
            }
        }
    }
    
    
    private var joinButton: some View {
        Button {
            // Join home
        } label: {
            HStack(spacing: 8) {
                
                Text("Join home")
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassEffect()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.inviteCode.count != codeLength)
        .opacity(
            viewModel.inviteCode.count == codeLength
            ? 1
            : 0.5
        )
    }
    
    
    private func character(at index: Int) -> String {
        guard index < viewModel.inviteCode.count else {
            return ""
        }
        
        let stringIndex = viewModel.inviteCode.index(
            viewModel.inviteCode.startIndex,
            offsetBy: index
        )
        
        return String(viewModel.inviteCode[stringIndex])
    }
    
    
    private func formatCode(_ value: String) {
        
        let formatted = value
            .uppercased()
            .filter {
                $0.isLetter || $0.isNumber
            }
        
        viewModel.inviteCode = String(
            formatted.prefix(codeLength)
        )
    }
}

#Preview {
    JoinHomeView(
        viewModel: JoinHomeViewModel()
    )
}
