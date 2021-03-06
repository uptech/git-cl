import XCTest
import Foundation
@testable import GitChangelog

final class GitCLTests: XCTestCase {
    func testRegex() throws {
        let changelogPattern = #"\[changelog\]"#
        let regexPattern = #"(added|changed|deprecated|removed|fixed|security)(?-i):\w?(.*)"#
        
        let body = """
        This is a commit Summary

        This is the message
        [CHANGELOG]
        added: ONE THING
        ADDED: Another Thing
        Added: Seomthing
        """
        
        var changelogKey = "[changelog]"
        if let changelogRange = body.range(of: changelogPattern, options: [.regularExpression, .caseInsensitive]) {
            changelogKey = String(body[changelogRange])
        }
        
        let changelogBody = body
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: changelogKey)
            .dropFirst()
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive])

        var changelogEntries: [String] = []

        let nsrange = NSRange(changelogBody.startIndex..<changelogBody.endIndex, in: changelogBody)
        regex.enumerateMatches(in: changelogBody, options: [], range: nsrange) { match, _, stop in
            guard let match = match else { return }

            if match.numberOfRanges == 3 {
                guard let firstCaptureRange = Range(match.range(at: 1), in: changelogBody),
                    let secondCaptureRange = Range(match.range(at: 2), in: changelogBody) else { return }

                let category = changelogBody[firstCaptureRange].trimmingCharacters(in: .whitespacesAndNewlines)
                let message = changelogBody[secondCaptureRange].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch category.lowercased() {
                case "added":
                    changelogEntries.append("added: \(message)")
                case "changed":
                    changelogEntries.append("changed: \(message)")
                case "deprecated":
                    changelogEntries.append("deprecated: \(message)")
                case "removed":
                    changelogEntries.append("removed: \(message)")
                case "fixed":
                    changelogEntries.append("fixed: \(message)")
                case "security":
                    changelogEntries.append("security: \(message)")
                default:
                    return
                }
            }
        }
        
        XCTAssertEqual(changelogEntries.count, 3)
    }

    func testRepositoryURLtoCompareBaseURL() {
        // Valid GitHub SSH repository url
        XCTAssertEqual(compareURL(URL(string: "git@github.com:uptech/git-cl.git")!, fromSha: "b547cc9", toSha: "64454ee")!.absoluteString, "https://github.com/uptech/git-cl/compare/b547cc9...64454ee")

        // Valid GitHub HTTPS repository url
        XCTAssertEqual(compareURL(URL(string: "https://github.com/uptech/git-cl.git")!, fromSha: "b547cc9", toSha: "64454ee")!.absoluteString, "https://github.com/uptech/git-cl/compare/b547cc9...64454ee")

        // Valid Bitbucket SSH repository url
        XCTAssertEqual(compareURL(URL(string: "git@bitbucket.org:uptechworks/test_uptech_repo.git")!, fromSha: "7f6fe26", toSha: "ac19790")!.absoluteString, "https://bitbucket.org/uptechworks/test_uptech_repo/branches/compare/ac19790%0D7f6fe26")

        // Valid Bitbucket HTTPS repository url
        XCTAssertEqual(compareURL(URL(string: "https://drewdeponte@bitbucket.org/uptechworks/test_uptech_repo.git")!, fromSha: "7f6fe26", toSha: "ac19790")!.absoluteString, "https://bitbucket.org/uptechworks/test_uptech_repo/branches/compare/ac19790%0D7f6fe26")

        // Unknown Host
        XCTAssertNil(compareURL(URL(string: "https://drewdeponte@bitaoeuaoeuaeuaueaoueubucket.org/uptechworks/test_uptech_repo.git")!, fromSha: "aoeuaoe", toSha: "aoeuaoe"))
    }

    static var allTests = [
        ("testRegex", testRegex),
        ("testRepositoryURLtoCompareBaseURL", testRepositoryURLtoCompareBaseURL),
    ]
}
