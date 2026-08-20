//
//  TabbarView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

struct TabbarView: View {
    
    @State private var activeTab: CustomTab = .home
    
    var body: some View {
        
    TabView(selection: $activeTab) {
        Tab.init(value: .home) {
            HomeView(viewModel: HomeViewModel())
                .customTabBarSafeArea()
              
        }
        Tab.init(value: .houseHold) {
            HouseholdView(viewModel: HouseholdViewModel())
                .customTabBarSafeArea()

        }
        Tab.init(value: .chorsese) {
            ChoresView()
                .customTabBarSafeArea()
            

        } 
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
        CustomTabBarView()
            .padding(.horizontal, 20)
    }
    }
    
    @ViewBuilder func CustomTabBarView() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GeometryReader { geometry in
//                        CustomTabBar(
//                            size: geometry.size,
//                            activeTab: $activeTab) { tab in
//                                VStack{
//                                    Image(systemName: tab.symbol)
//                                        .font(.title3)
//
//                                    Text(tab.rawValue)
//                                        .font(.system(size: 10))
//                                        .fontWeight(.medium)
//                                }
//                                .symbolVariant(.fill)
//                                .frame(maxWidth: .infinity)
//                            }
//                            .glassEffect(.regular.interactive(), in: .capsule)
                    
                    
                    //type 2
                    CustomTabBar2(size: geometry.size, activeTab: $activeTab)
                        .overlay{
                            HStack(spacing: 0){
                                ForEach(CustomTab.allCases, id: \.rawValue) { tab in
                                    VStack{
                                        Image(systemName: tab.symbol)
                                            .font(.title3)
                                        
                                        Text(tab.rawValue)
                                            .font(.system(size: 10))
                                            .fontWeight(.medium)
                                    }
                                    .symbolVariant(.fill)
                                    .foregroundStyle(activeTab == tab ? .blue : .primary)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                
                
                ZStack{
                    ForEach(CustomTab.allCases, id: \.rawValue) { tab in
                        Image(systemName: tab.actionSymol)
                            .font(.system(size: 22, weight: .medium))
                            .blurFade(activeTab == tab)
                        
                    }
                }
                .frame(width: 55, height: 55)
                .glassEffect(.regular.interactive(), in: .capsule)
                .animation(.smooth(duration: 0.55, extraBounce: 0), value: activeTab)
                
            }
        }
        .frame(height: 55)
    }
}







enum CustomTab: String, CaseIterable {
    case home = "Home"
    case houseHold = "HouseHold"
    case chorsese = "Chorses"
    
    
    var symbol: String {
        switch self {
        case .home: return "house"
        case .houseHold: return "creditcard.fill"
        case .chorsese: return "checklist"
        }
    }
    
    var actionSymol: String {
        switch self {
        case .home: return "xmark"
        case .houseHold: return "plus"
        case .chorsese: return "person.crop.circle.badge"
        }
    }
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
    
    
}

#Preview {
    TabbarView()
}
