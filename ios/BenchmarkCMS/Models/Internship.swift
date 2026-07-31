import Foundation
import SwiftData

/// An internship opportunity shared with students.
@Model
final class Internship {
    var title: String
    var company: String
    var location: String
    var summary: String
    var bodyText: String
    var applicationURL: String
    var imageURL: String
    var deadline: Date
    var postedAt: Date
    var updatedAt: Date
    var isRemote: Bool
    var isPaid: Bool
    var isPublished: Bool
    var category: String

    @Relationship(deleteRule: .nullify)
    var author: AppUser?

    init(
        title: String = "",
        company: String = "",
        location: String = "",
        summary: String = "",
        bodyText: String = "",
        applicationURL: String = "",
        imageURL: String = "",
        deadline: Date = Date(timeIntervalSinceNow: 30 * 86_400),
        isRemote: Bool = false,
        isPaid: Bool = true,
        isPublished: Bool = false,
        category: String = "Engineering",
        author: AppUser? = nil
    ) {
        self.title = title
        self.company = company
        self.location = location
        self.summary = summary
        self.bodyText = bodyText
        self.applicationURL = applicationURL
        self.imageURL = imageURL
        self.deadline = deadline
        self.postedAt = .now
        self.updatedAt = .now
        self.isRemote = isRemote
        self.isPaid = isPaid
        self.isPublished = isPublished
        self.category = category
        self.author = author
    }

    var isExpired: Bool { deadline <= .now }

    var daysUntilDeadline: Int {
        Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0
    }

    var deadlineLabel: String {
        if isExpired { return "Closed" }
        let days = daysUntilDeadline
        if days == 0 { return "Closes today" }
        if days == 1 { return "Closes tomorrow" }
        return "Closes in \(days) days"
    }

    var statusBadge: String {
        if !isPublished { return "Draft" }
        if isExpired { return "Closed" }
        return "Open"
    }
}
