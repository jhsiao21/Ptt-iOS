//
//  APIClientTest.swift
//  PttTests
//
//  Created by Anson on 2020/11/19.
//  Copyright © 2020 Ptt. All rights reserved.
//

@testable import Ptt
import XCTest

final class APIClientTest: XCTestCase {
    private var urlSession: MockURLSessionV2!
    private var apiClient: APIClientProtocol!
    private lazy var manager = APITestClient()

    override func setUp() async throws {
        urlSession = MockURLSessionV2()
        apiClient = APIClient(session: urlSession)
    }

    override func tearDown() {
        urlSession = nil
        apiClient = nil
    }
    
    func testNetworkError() {
        let dataTask = MockURLSessionDataTask()
        let info = [NSLocalizedDescriptionKey: "Network error"]
        let unknowError = NSError(domain: "term.ptt.cc", code: 404, userInfo: info)
        let session = MockURLSession(mockDataTask: dataTask, fakeData: nil, error: unknowError)
        let client = APIClient(session: session)

        client.getBoardArticles(of: .legacy(boardName: "abc", page: 1)) { result in
            switch result {
            case .failure(let error):
                XCTAssertTrue(error.message == "Network error")
            case .success:
                XCTAssert(false)
            }
        }
    }

    func testHttpResponseError() {
        let dataTask = MockURLSessionDataTask()
        let statusCode = 404
        let session = MockURLSession(mockDataTask: dataTask, fakeData: Data(), error: nil, statusCode: statusCode)
        let client = APIClient(session: session)

        client.getBoardArticles(of: .legacy(boardName: "abc", page: 1)) { result in
            switch result {
            case .failure(let error):
                let msg = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
                XCTAssert(error.message == msg)
            case .success:
                XCTAssert(false)
            }
        }
    }

    func testNoDataError() {
        let dataTask = MockURLSessionDataTask()
        let session = MockURLSession(mockDataTask: dataTask, fakeData: nil, error: nil)
        let client = APIClient(session: session)

        client.getBoardArticles(of: .legacy(boardName: "abc", page: 1)) { result in
            switch result {
            case .failure(let error):
                XCTAssert(error.message == "Data doesn't exist")
            case .success:
                XCTAssert(false)
            }
        }
    }

    func testLoginSuccess() {
        let client = manager.login()
        client.login(account: "asd", password: "123") { result in
            switch result {
            case .failure:
                XCTAssert(false)
            case .success(let token):
                XCTAssert(token.access_token == "fake token")
                XCTAssert(token.token_type == "fake type")
            }
        }
    }

    func testGetBoardArticlesSuccess() {
        let client = manager.newArticleClient()

        client.getBoardArticles(of: .legacy(boardName: "MyBoard", page: 1)) { result in
            switch result {
            case .failure:
                XCTAssert(false)
            case .success(let board):
                XCTAssert(board.page == 1)
//                XCTAssert(board.boardInfo.name == "MyBoard")
//                XCTAssert(board.boardInfo.nuser == "21471")
                XCTAssert(board.articleList.count == 2)
                XCTAssert(board.articleList[0].title == "Re: [問卦] 這是測試嗎")
            }
        }
    }

    func testGetArticleSuccess() {
        let client = manager.getArticleClient()
        client.getArticle(of: .legacy(boardName: "MyBoard", filename: "M.392837.A.F25")) { result in
            switch result {
                case .failure:
                    XCTAssert(false)
                case .success(let article):
                    guard let fullArticle = article as? APIModel.FullArticle else {
                        fatalError()
                    }
                    XCTAssert(article.author == "user3")
                    XCTAssert(article.date == "Thu Nov 19 21:20:42 2020")
                    XCTAssert(article.category == "問卦")
                    XCTAssert(article.titleWithoutCategory == "有沒有問卦的八卦")
                    XCTAssert(fullArticle.comments.count == 2)
                    XCTAssert(fullArticle.comments[1].content == ": 叫學長啦")
            }
        }
    }
    
    func testBoardListSuccess_with_english_keyword() {
        let startIdx = "\(Int.random(in: 0...99))"
        let max = Int.random(in: 0...99)
        urlSession.stub { path, headers, queryItem, requestBody, completion in
            XCTAssertEqual(path, "/api/boards/autocomplete")
            XCTAssertEqual(headers["Authorization"], "bearer theToken")
            for item in queryItem {
                if item.name == "brdname" {
                    XCTAssertEqual(item.value, "stup")
                } else if item.name == "start_idx" {
                    XCTAssertEqual(item.value, startIdx)
                } else if item.name == "limit" {
                    XCTAssertEqual(item.value, "\(max)")
                }
            }
            completion(.success(BoardListFakeData.successData))
        }
        apiClient.getBoardList(token: "theToken", keyword: "stup", startIdx: startIdx, max: max) { result in
            switch result {
            case .failure:
                XCTFail("Shouldn't fail")
            case .success(let list):
                XCTAssert(list.next_idx == "")
                XCTAssert(list.list.count == 6)
                let info = list.list[0]
                XCTAssert(info.bid == "6_ALLPOST")
                XCTAssert(info.brdname == "ALLPOST")
                XCTAssert(info.title == "跨板式LOCAL新文章")
                XCTAssert(info.flag == 32)
                XCTAssert(info.nuser == 0)
            }
        }
    }

    func testBoardListSuccess_with_chinese_keyword() {
        let startIdx = "\(Int.random(in: 0...99))"
        let max = Int.random(in: 0...99)
        urlSession.stub { path, headers, queryItem, requestBody, completion in
            XCTAssertEqual(path, "/api/boards/byclass")
            for item in queryItem {
                if item.name == "keyword" {
                    XCTAssertEqual(item.value, "笨")
                } else if item.name == "start_idx" {
                    XCTAssertEqual(item.value, startIdx)
                } else if item.name == "limit" {
                    XCTAssertEqual(item.value, "\(max)")
                }
            }
            completion(.success(BoardListFakeData.successData))
        }
        apiClient.getBoardList(token: "theToken", keyword: "笨", startIdx: startIdx, max: max) { result in
            switch result {
            case .failure:
                XCTFail("Shouldn't fail")
            case .success(let list):
                XCTAssert(list.next_idx == "")
                XCTAssert(list.list.count == 6)
            }
        }
    }

    func testBoardListSuccess_with_japanese_keyword() {
        let startIdx = "\(Int.random(in: 0...99))"
        let max = Int.random(in: 0...99)
        urlSession.stub { path, headers, queryItem, requestBody, completion in
            XCTAssertEqual(path, "/api/boards")
            for item in queryItem {
                if item.name == "keyword" {
                    XCTAssertEqual(item.value, "ごじゅうおん")
                } else if item.name == "start_idx" {
                    XCTAssertEqual(item.value, startIdx)
                } else if item.name == "limit" {
                    XCTAssertEqual(item.value, "\(max)")
                }
            }
            completion(.success(BoardListFakeData.successData))
        }
        apiClient.getBoardList(token: "theToken", keyword: "ごじゅうおん", startIdx: startIdx, max: max) { result in
            switch result {
            case .failure:
                XCTFail("Shouldn't fail")
            case .success(let list):
                XCTAssert(list.next_idx == "")
                XCTAssert(list.list.count == 6)
            }
        }
    }

    func testGetFavoritesBoards() {
        let client = manager.getFavoritesBoards()

        client.getFavoritesBoards(startIndex: 0, limit: 0) { result in
            switch result {
            case .failure:
                XCTFail("Shouldn't failed")
            case .success(let response):
                XCTAssertEqual(response.next_idx, "")
                let list = response.list
                XCTAssertEqual(list.count, 2)
                XCTAssertEqual(list[0].title, "站長好!")
            }
        }
    }
}
