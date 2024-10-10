//
//  TestPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Alamofire
import Foundation

class TestPresenter: ObservableObject {
    @Published var posts: [TestingEntity] = []

    func fetchPosts() {
        AF.request("https://jsonplaceholder.typicode.com/posts")
            .responseDecodable(of: [TestingEntity].self) { response in
                switch response.result {
                case let .success(posts):
                    self.posts = posts
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
    }
}
