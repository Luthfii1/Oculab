//
//  TestPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation
import Alamofire

class TestPresenter: ObservableObject {
    @Published var posts: [Post] = []

    func fetchPosts() {
        AF.request("https://jsonplaceholder.typicode.com/posts")
            .responseDecodable(of: [Post].self) { response in
                switch response.result {
                case .success(let posts):
                    self.posts = posts
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
    }
}
