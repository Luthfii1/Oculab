//
//  TestView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 04/10/24.
//

import SwiftUI

struct TestView: View {
    @ObservedObject var viewModel = TestPresenter()

    var body: some View {
        List(viewModel.posts) { post in
            VStack(alignment: .leading) {
                Text(post.title)
                    .font(.headline)
                Text(post.body)
                    .font(.subheadline)
            }
        }
        .onAppear(perform: viewModel.fetchPosts)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
