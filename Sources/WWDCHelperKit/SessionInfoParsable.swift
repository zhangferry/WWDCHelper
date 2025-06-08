//
//  SessionInfoParsable.swift
//  WWDCHelperKit
//
//  Created by kingcos on 07/09/2017.
//
//

import Foundation

public enum SessionInfoType {
    case subtitleIndexURLPrefix
    case resources
    case sessionsInfo
}

public protocol SessionInfoParsable {
    func parseSubtitleIndexURLPrefix(in content: String) -> String
    func parseResourceURLs(in content: String) -> [String]
    func parseSessionsInfo(in content: String) -> [String : String]
}

public protocol RegexSessionInfoParsable: SessionInfoParsable {
    var patterns: [SessionInfoType : String] { get }
}

public extension RegexSessionInfoParsable {
    func parseSubtitleIndexURLPrefix(in content: String) -> String {
        let nsStr = NSString(string: content)
        let regex = try! NSRegularExpression(pattern: patterns[.subtitleIndexURLPrefix]!)
        let range = content.wholeNSRange
        let matches = regex.matches(in: content, range: range)
        
        var result = ""
        for match in matches {
            let firstRange = match.range(at: 1)
            result = nsStr.substring(with: firstRange)
        }
        
        return result
    }
    
    func parseResourceURLs(in content: String) -> [String] {
        let nsStr = NSString(string: content)
        let regex = try! NSRegularExpression(pattern: patterns[.resources]!, options: .dotMatchesLineSeparators)
        let range = content.wholeNSRange
        let matches = regex.matches(in: content, range: range)
        
        var result = [String]()
        for match in matches {
            let firstRange = match.range(at: 1)
//            let secondRange = match.range(at: 3)
//            let thirdRange = match.range(at: 5)
            
            result.append(nsStr.substring(with: firstRange))
//            result.append(nsStr.substring(with: secondRange))
//            result.append(nsStr.substring(with: thirdRange))
        }
        
        return result
    }
    
    func parseSessionsInfo(in content: String) -> [String : String] {
        let nsStr = NSString(string: content)
        let regex = try! NSRegularExpression(pattern: patterns[.sessionsInfo]!, options: .dotMatchesLineSeparators)
        let range = content.wholeNSRange
        let matches = regex.matches(in: content, range: range)
        
        var result = [String : String]()
        for match in matches {
            let firstRange = match.range(at: 1)
            let secondRange = match.range(at: 2)
            result[nsStr.substring(with: firstRange)] = nsStr.substring(with: secondRange)
        }
        
        return result
    }
}
