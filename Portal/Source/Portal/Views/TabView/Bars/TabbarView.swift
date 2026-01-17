//
//  TabbarView.swift
//  feather
//
//  Created by samara on 23.03.2025.
//

import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .sources
	@AppStorage("Feather.userInterfaceStyle") private var uiStyleRaw: Int = UIUserInterfaceStyle.unspecified.rawValue

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						Label(tab.title, systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
		.onAppear(perform: updateTabBarAppearance)
		.onChange(of: uiStyleRaw) { _ in
			updateTabBarAppearance()
		}
	}

	private func updateTabBarAppearance() {
		guard let style = UIUserInterfaceStyle(rawValue: uiStyleRaw) else { return }
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
			windowScene.windows.forEach { window in
				window.overrideUserInterfaceStyle = style
			}
		}
		let appearance = UITabBarAppearance()
		appearance.configureWithDefaultBackground()
		UITabBar.appearance().standardAppearance = appearance
		if #available(iOS 15.0, *) {
			UITabBar.appearance().scrollEdgeAppearance = appearance
		}
	}
}
