//
//  Test.swift
//  WWDCHelper
//
//  Created by zhangferry on 2025/6/8.
//

import Testing
import PathKit
@testable import WWDCHelperKit

struct WWDCParseTests {

    @Test func testParseSessionsInfo() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let html = """
<a href="/videos/play/wwdc2024/10069/" class="vc-card tile ...">
    <div class="vc-card__content">
        <h5 class="vc-card__title">Broadcast updates to your Live Activities</h5>
    </div>
</a>
<a href="/videos/play/wwdc2024/10070/" class="vc-card tile ...">
    <div class="vc-card__content">
        <h5 class="vc-card__title">What's new in SwiftData</h5>
    </div>
</a>
"""
        let parse = WWDCParser.shared
        
        let res = parse.parseSessionsInfo(in: html)
        print(res)
    }

}
