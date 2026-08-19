//
//  CreateHomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 18/08/2026.
//

import SwiftUI

@Observable
class CreateHomeViewModel {
    var homeName: String = ""
}

struct CreateHomeView: View {
    
    @State var viewModel: CreateHomeViewModel
    
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
                
             text
               
               picture
                
            homeName
                
                
                
                Spacer()
                
                createHome
              
            }
            .padding(.horizontal, 24)
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
    }
    
    private var text: some View {
        VStack(spacing: 8) {
            Text("Create your home")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Give your home a name. You can invite your housemates next.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    
    private var picture: some View {
        GeometryReader{ geo in
            
            Image("house4")
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width * 0.80)
                .position(
                    x: geo.size.width * 0.50,
                    y: geo.size.height * 0.50
                )

            
        }
        .frame(height: 250)
    }
    
    private var homeName: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text("Home name")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("e.g. London Flat", text: $viewModel.homeName)
                .padding()
                .glassEffect()
        }
    }
    
    private var createHome: some View {
        Button {
            
        } label: {
            Text("Create home")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .glassEffect()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.homeName.isEmpty)
        .opacity(viewModel.homeName.isEmpty ? 0.5 : 1)
    }
    
    
    
    
   
    
    
    
    
}

#Preview {
    CreateHomeView(
        viewModel: CreateHomeViewModel()
    )
}
