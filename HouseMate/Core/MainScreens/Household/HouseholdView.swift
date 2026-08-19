//
//  HouseholdView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

@Observable
class HouseholdViewModel {
    
    init() {
        
    }
    
    
    
    
}





struct HouseholdView: View {
    
    @State var viewModel: HouseholdViewModel
    var body: some View {
        Text("Household!")
    }
}

#Preview {
    HouseholdView(viewModel: HouseholdViewModel())
}
