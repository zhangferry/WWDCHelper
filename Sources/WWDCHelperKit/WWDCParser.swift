//
//  WWDCParser.swift
//  WWDCHelper
//
//  Created by kingcos on 2018/8/22.
//

import Foundation

public class WWDCParser: RegexSessionInfoParsable {
    public static let shared = WWDCParser()
    
    private init() {}
    
    public let patterns: [SessionInfoType : String] = [
        .subtitleIndexURLPrefix: "(http.*)\\/.*_hd",
        .resources: #"<li class="download">[\s\S]*?<a href="(https://devstreaming-cdn\.apple\.com/videos/wwdc/2024/[0-9]+/.*?\.mp4\?dl=1)">"#,
        .sessionsInfo: "<a href=\"\\/videos\\/play\\/[\\w-]+\\/([0-9]+)\\/\"[^>]*?>.*?<h5 class=\"vc-card__title\">(.*?)<\\/h5>"
    ]
}
