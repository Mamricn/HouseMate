//
//  SelectView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

@Observable
class SelectViewModel {
    
}




struct SelectView: View {
    
    @State var viewModel: SelectViewModel
    
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
                
                picture
                
                
                text
                buttons
            }
            .padding(.horizontal, 10)
        }
    }
    private var picture: some View {
        GeometryReader{ geo in
            
            Image("house2")
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width * 0.80)
                .position(
                    x: geo.size.width * 0.50,
                    y: geo.size.height * 0.50
                )

            
        }
        .frame(height: 300)
    }
    
    private var text: some View {
        VStack(spacing: 8) {
            Text("Set up your home")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create a new home or join one that already exists.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    
    
    private var buttons: some View {
        VStack(spacing: 16) {

            Button {

            } label: {
                HStack(spacing: 16) {

                    Image(systemName: "house")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create a new home")
                            .font(.headline)

                        Text("Set up a home and invite others")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(15)
                .frame(maxWidth: .infinity)
                
            }
            .buttonStyle(.glass)


            Button {

            } label: {
                HStack(spacing: 16) {

                    Image(systemName: "person.2.fill")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Join a home")
                            .font(.headline)

                        Text("Join using an invite code")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(15)
                .frame(maxWidth: .infinity)
//                .glassEffect()
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    SelectView(viewModel: SelectViewModel())
}
