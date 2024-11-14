//
//  RouterView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct RouterView<Content: View>: View {
    @EnvironmentObject var router: Router // Use shared router instance
    private let content: Content

    // Initialize with a content closure
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: Router.Route.self) { route in
                    router.view(for: route)
                }
        }
    }
}
