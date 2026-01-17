//
//  SigningOptionsSharedView.swift
//  Feather
//
//  Created by samara on 15.04.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SigningOptionsView: View {
	@Binding var options: Options
	var temporaryOptions: Options?
	
	// MARK: Body
	var body: some View {
		if (temporaryOptions == nil) {
			NBSection(.localized("Protection")) {
				_toggle(
					.localized("PPQ Protection"),
					systemImage: "shield",
					isOn: $options.ppqProtection,
					temporaryValue: temporaryOptions?.ppqProtection
				)
			}
		}
		
		NBSection(.localized("General")) {
			Self.picker(
				.localized("Appearance"),
				systemImage: "paintpalette",
				selection: $options.appAppearance,
				values: Options.AppAppearance.allCases
			)
			
			Self.picker(
				.localized("Minimum Requirement"),
				systemImage: "ruler",
				selection: $options.minimumAppRequirement,
				values: Options.MinimumAppRequirement.allCases
			)
		}
		
		Section {
			Self.picker(
				.localized("Signing Type"),
				systemImage: "signature",
				selection: $options.signingOption,
				values: Options.SigningOption.allCases
			)
		}
		
		NBSection(.localized("App Features")) {
			_toggle(
				.localized("File Sharing"),
				systemImage: "folder.badge.person.crop",
				isOn: $options.fileSharing,
				temporaryValue: temporaryOptions?.fileSharing
			)
			
			_toggle(
				.localized("iTunes File Sharing"),
				systemImage: "music.note.list",
				isOn: $options.itunesFileSharing,
				temporaryValue: temporaryOptions?.itunesFileSharing
			)
			
			_toggle(
				.localized("Pro Motion"),
				systemImage: "speedometer",
				isOn: $options.proMotion,
				temporaryValue: temporaryOptions?.proMotion
			)
			
			_toggle(
				.localized("Game Mode"),
				systemImage: "gamecontroller",
				isOn: $options.gameMode,
				temporaryValue: temporaryOptions?.gameMode
			)
			
			_toggle(
				.localized("iPad Fullscreen"),
				systemImage: "ipad.landscape",
				isOn: $options.ipadFullscreen,
				temporaryValue: temporaryOptions?.ipadFullscreen
			)
		}
		
		NBSection(.localized("Removal")) {
			_toggle(
				.localized("Remove URL Scheme"),
				systemImage: "ellipsis.curlybraces",
				isOn: $options.removeURLScheme,
				temporaryValue: temporaryOptions?.removeURLScheme
			)
			
			_toggle(
				.localized("Remove Provisioning"),
				systemImage: "doc.badge.gearshape",
				isOn: $options.removeProvisioning,
				temporaryValue: temporaryOptions?.removeProvisioning
			)
		}
		
		Section {
			_toggle(
				.localized("Force Localize"),
				systemImage: "character.bubble",
				isOn: $options.changeLanguageFilesForCustomDisplayName,
				temporaryValue: temporaryOptions?.changeLanguageFilesForCustomDisplayName
			)
		}
		
		NBSection(.localized("Post Signing")) {
            _toggle(
                .localized("Install After Signing"),
                systemImage: "arrow.down.circle",
                isOn: $options.post_installAppAfterSigned,
                temporaryValue: temporaryOptions?.post_installAppAfterSigned
            )
			_toggle(
				.localized("Delete After Signing"),
				systemImage: "trash",
				isOn: $options.post_deleteAppAfterSigned,
				temporaryValue: temporaryOptions?.post_deleteAppAfterSigned
			)
		}
		
		NBSection(.localized("Experiments")) {
			_toggle(
				.localized("Replace Substrate with ElleKit"),
				systemImage: "pencil",
				isOn: $options.experiment_replaceSubstrateWithEllekit,
				temporaryValue: temporaryOptions?.experiment_replaceSubstrateWithEllekit
			)
			
			_toggle(
				.localized("Enable Liquid Glass"),
				systemImage: "26.circle",
				isOn: $options.experiment_supportLiquidGlass,
				temporaryValue: temporaryOptions?.experiment_supportLiquidGlass
			)
		}
	}
	
	@ViewBuilder
	static func picker<SelectionValue: Hashable, T: Hashable & LocalizedDescribable>(
		_ title: String,
		systemImage: String,
		selection: Binding<SelectionValue>,
		values: [T]
	) -> some View {
		Picker(selection: selection) {
			ForEach(values, id: \.self) { value in
				Text(value.localizedDescription)
			}
		} label: {
			Label(title, systemImage: systemImage)
		}
	}
	
	@ViewBuilder
	private func _toggle(
		_ title: String,
		systemImage: String,
		isOn: Binding<Bool>,
		temporaryValue: Bool? = nil
	) -> some View {
		Toggle(isOn: isOn) {
			Label {
				if let tempValue = temporaryValue, tempValue != isOn.wrappedValue {
					Text(title).bold()
				} else {
					Text(title)
				}
			} icon: {
				Image(systemName: systemImage)
			}
		}
	}
}
