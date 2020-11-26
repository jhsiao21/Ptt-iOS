//
//  APIClientTest.swift
//  PttTests
//
//  Created by Anson on 2020/11/19.
//  Copyright © 2020 Ptt. All rights reserved.
//

import XCTest
@testable import Ptt

final class APIClientTest: XCTestCase {
    
    func testNetworkError() {
        let dataTask = MockURLSessionDataTask()
        let info = [NSLocalizedDescriptionKey: "Network error"]
        let unknowError = NSError(domain: "term.ptt.cc", code: 404, userInfo: info)
        let session = MockURLSession(mockDataTask: dataTask, fakeData: nil, error: unknowError)
        let client = APIClient(session: session)
        
        client.getNewPostlist(board: "abc", page: 1) { (result) in
            switch (result) {
            case .failure(let error):
                XCTAssertTrue(error.message == "Network error")
            case .success(_):
                XCTAssert(false)
            }
        }
    }
    
    func testHttpResponseError() {
        let dataTask = MockURLSessionDataTask()
        let statusCode = 404
        let session = MockURLSession(mockDataTask: dataTask, fakeData: Data(), error: nil, statusCode: statusCode)
        let client = APIClient(session: session)
        
        client.getNewPostlist(board: "abc", page: 1) { (result) in
            switch (result) {
            case .failure(let error):
                let msg = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
                XCTAssert(error.message == msg)
            case .success(_):
                XCTAssert(false)
            }
        }
    }
    
    func testNoDataError() {
        let dataTask = MockURLSessionDataTask()
        let session = MockURLSession(mockDataTask: dataTask, fakeData: nil, error: nil)
        let client = APIClient(session: session)
        
        client.getNewPostlist(board: "abc", page: 1) { (result) in
            switch (result) {
            case .failure(let error):
                XCTAssert(error.message == "No data")
            case .success(_):
                XCTAssert(false)
            }
        }
    }
    
    func testNewPostlistSuccess() {
        guard let path = Bundle(for: type(of: self)).path(forResource: "NewPostlist", ofType: "json") else {
            fatalError("NewPostlist.json not found")
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        
        let dataTask = MockURLSessionDataTask()
        let session = MockURLSession(mockDataTask: dataTask, fakeData: data, error: nil)
        let client = APIClient(session: session)
        
        client.getNewPostlist(board:"MyBoard", page: 1) { (result) in
            switch (result) {
            case .failure(_):
                XCTAssert(false)
            case .success(let board):
                XCTAssert(board.page == 1)
                XCTAssert(board.boardInfo.name == "MyBoard")
                XCTAssert(board.boardInfo.nuser == "21471")
                XCTAssert(board.postList.count == 2)
                XCTAssert(board.postList[0].title == "Re: [問卦] 這是測試嗎")
            }
        }
    }
    
    func testGetPostSuccess() {
        guard let path = Bundle(for: type(of: self)).path(forResource: "GetPost", ofType: "json") else {
            fatalError("GetPost.json not found")
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        
        let dataTask = MockURLSessionDataTask()
        let session = MockURLSession(mockDataTask: dataTask, fakeData: data, error: nil)
        let client = APIClient(session: session)
        
        client.getPost(board: "MyBoard", filename: "M.392837.A.F25") { (result) in
            switch (result) {
                case .failure(_):
                    XCTAssert(false)
                case .success(let post):
                    guard let fullPost = post as? APIModel.FullPost else {
                        fatalError()
                    }
                    XCTAssert(post.author == "user3")
                    XCTAssert(post.date == "Thu Nov 19 21:20:42 2020")
                    XCTAssert(post.category == "問卦")
                    XCTAssert(post.titleWithoutCategory == "有沒有問卦的八卦")
                    XCTAssert(fullPost.comments.count == 2)
                    XCTAssert(fullPost.comments[1].content == ": 叫學長啦")
            }
        }
    }
}
