//
//  WWDCHelper.swift
//  WWDCHelperKit
//
//  Created by kingcos on 06/09/2017.
//
//

import Foundation
import PathKit
import Rainbow
import WWDCWebVTTToSRTHelperKit

public enum WWDCYear: String {
    case wwdc2024 = "wwdc2024"
    case wwdc2019 = "wwdc2019"
    case wwdc2018 = "wwdc2018"
    case wwdc2017 = "wwdc2017"
    case wwdc2016 = "wwdc2016"
    case wwdc2015 = "wwdc2015"
    case wwdc2014 = "wwdc2014"
    case wwdc2013 = "wwdc2013"
    case wwdc2012 = "wwdc2012"
    case unknown
    
    init(_ value: String?) {
        guard let value = value else {
            self = .wwdc2024
            return
        }
        
        switch value.lowercased() {
        case "wwdc2024", "2024":
            self = .wwdc2024
        case "wwdc2019", "2019":
            self = .wwdc2019
        case "wwdc2018", "2018":
            self = .wwdc2018
        case "wwdc2017", "2017":
            self = .wwdc2017
        case "wwdc2016", "2016":
            self = .wwdc2016
        case "wwdc2015", "2015":
            self = .wwdc2015
        case "wwdc2014", "2014":
            self = .wwdc2014
        case "wwdc2013", "2013":
            self = .wwdc2013
        case "wwdc2012", "2012":
            self = .wwdc2012
        default:
            self = .unknown
        }
    }
}

public enum SubtitleLanguage: String {
    case eng = "eng"
    case chs = "zho"
    case jpn = "jpn"
    case empty
    case unknown
    
    init(_ value: String?) {
        guard let value = value else {
            self = .empty
            return
        }
        
        switch value {
        case "eng":
            self = .eng
        case "chs":
            self = .chs
        case "jpn":
            self = .jpn
        default:
            self = .unknown
        }
    }
}

public enum HelperError: Error {
    case unknownYear
    case unknownSubtitleLanguage
    case unknownSessionID
    case subtitlePathNotExist
}

public struct WWDCHelper {
    public let year: WWDCYear
    public let sessionIDs: [String]?
    
    public let subtitleLanguage: SubtitleLanguage
    public let subtitlePath: Path
    public let isSubtitleForSDVideo: Bool
    
    let srtHelper = WWDCWebVTTToSRTHelper()
    var sessionsInfo = [String : String]()
    
    public init(year: String? = nil,
                sessionIDs: [String]? = nil,
                subtitleLanguage: String? = nil,
                subtitlePath: String? = nil,
                isSubtitleForSDVideo: Bool = false) {
        self.year = WWDCYear(year)
        self.sessionIDs = sessionIDs
        self.subtitleLanguage = SubtitleLanguage(subtitleLanguage)
        self.subtitlePath = Path(subtitlePath ?? ".").absolute()
        self.isSubtitleForSDVideo = isSubtitleForSDVideo
    }
}

extension WWDCHelper {
    public mutating func enterHelper() throws {
        guard year != .unknown else { throw HelperError.unknownYear }
        guard subtitleLanguage != .unknown else { throw HelperError.unknownSubtitleLanguage }
        
        let sessions = try getSessions(by: sessionIDs,
                                       with: WWDCParser.shared).sorted { $0.id < $1.id }
        
        if subtitleLanguage != .empty {
            if !subtitlePath.exists {
                throw HelperError.subtitlePathNotExist
            } else {
                try downloadData(sessions, with: WWDCParser.shared)
            }
        } else {
            _ = sessions.map { $0.output(year) }
        }
    }
    
    public func downloadData(_ sessions: [WWDCSession], with parser: RegexSessionInfoParsable) throws {
        print("Start downloading...")
        
        for session in sessions {
            var filename = "\(session.id)"
            if isSubtitleForSDVideo {
                filename += "_sd_"
            } else {
                filename += "_hd_"
            }
            
            filename += session.title.lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "")
            filename = filename + "." + subtitleLanguage.rawValue + ".srt"
            
            let path = subtitlePath + filename
            
            guard !FileManager.default.fileExists(atPath: path.string) else {
                print("\(filename) already exists, skip to download.")
                continue
            }
            
            guard let urls = getWebVTTURLs(with: getResourceURLs(by: session.id, with: parser), and: parser)
                else { continue }
            
            let content = urls
                .map { url -> [String] in
                    let content = Network.shared.fetchContent(of: url)
                    if content.contains("WEBVTT") {
                        return content.components(separatedBy: "\n")
                    } else {
                        return []
                    }
                }
            let strArr = content.flatMap { $0.map { $0 } }
            
            if strArr.isEmpty {
                // Apple maybe upload empty content...
                print("\(filename) downloaded error.".red.bold)
            } else {
                guard let result = srtHelper.parse(strArr),
                    let data = result.data(using: .utf8) else { return }
                
                print(filename, "is downloading...")
                
                try data.write(to: path.url)
            }
        }
        print("Download successfully.".green.bold)
    }
}

extension WWDCHelper {
    public mutating func getSessions(by ids: [String]? = nil, with parser: RegexSessionInfoParsable) throws -> [WWDCSession] {
        if sessionsInfo.isEmpty {
            sessionsInfo = getSessionsInfo(with: parser)
        }
        let sessionIDs = ids ?? sessionsInfo.map { $0.0 }
        
        var sessions = [WWDCSession]()
        for sessionID in sessionIDs {
            guard let session = try getSession(by: sessionID, with: parser) else { continue }
            sessions.append(session)
        }
        
        return sessions
    }
    
    mutating func getSession(by id: String, with parser: RegexSessionInfoParsable) throws -> WWDCSession? {
        if sessionsInfo.isEmpty {
            sessionsInfo = getSessionsInfo(with: parser)
        }
        guard let title = sessionsInfo[id] else { throw HelperError.unknownSessionID }
        let resources = getResourceURLs(by: id, with: parser)
        let url = getSubtitleIndexURL(with: resources, and: parser)
        
        return WWDCSession(id, title, resources, url)
    }
}

extension WWDCHelper {
    func getSessionsInfo(with parser: RegexSessionInfoParsable) -> [String : String] {
        let url = "https://developer.apple.com/videos/\(year.rawValue)/"
        let content = Network.shared.fetchContent(of: url)
        return parser.parseSessionsInfo(in: content)
    }
    
    func getResourceURLs(by id: String, with parser: RegexSessionInfoParsable) -> [String] {
        let url = "https://developer.apple.com/videos/play/\(year.rawValue)/\(id)/"
        let content = Network.shared.fetchContent(of: url)
        return parser.parseResourceURLs(in: content)
    }
    
    func getSubtitleIndexURLPrefix(with resources: [String], and parser: RegexSessionInfoParsable) -> String? {
        if resources.isEmpty {
            return nil
        }
        var url = parser.parseSubtitleIndexURLPrefix(in: resources[0])
        /// 移除多余的downloads路径
        if url.hasSuffix("downloads") {
            url = url.replacingOccurrences(of: "/downloads", with: "")
        }
        return url
    }
    
    func getSubtitleIndexURL(with resources: [String], and parser: RegexSessionInfoParsable) -> String? {
        guard let prefix = getSubtitleIndexURLPrefix(with: resources, and: parser) else { return nil }
        return prefix + "/subtitles/eng/prog_index.m3u8"
    }
    
    func getWebVTTURLs(with resources: [String], and parser: RegexSessionInfoParsable) -> [String]? {
        guard let urlPrefix = getSubtitleIndexURLPrefix(with: resources, and: parser),
            let url = getSubtitleIndexURL(with: resources, and: parser) else { return nil }
        let content = Network.shared.fetchContent(of: url)
        return content
            .components(separatedBy: "\n")
            .filter { $0.hasSuffix(".webvtt") }
            .map {
                urlPrefix + "/subtitles/\(subtitleLanguage.rawValue)/\($0)"
            }
    }
}
