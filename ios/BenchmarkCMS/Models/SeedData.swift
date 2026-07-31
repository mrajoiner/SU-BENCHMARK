import Foundation
import SwiftData

/// Seeds demo users, the category navigation, site settings, and sample content
/// so every role has something meaningful to work with on first launch.
enum SeedData {
    /// Updates previously-seeded stores that still carry the old masthead copy.
    private static func migrateBranding(context: ModelContext) {
        guard let settings = (try? context.fetch(FetchDescriptor<SiteSettings>()))?.first else { return }
        var changed = false
        if settings.siteTitle == "Southern University Benchmark" {
            settings.siteTitle = "Benchmark"
            changed = true
        }
        if settings.tagline == "News & stories from the College of Sciences and Engineering" {
            settings.tagline = "Showcasing Southern University's excellence to the world."
            changed = true
        }
        if changed {
            settings.updatedAt = .now
            try? context.save()
        }
    }

    /// Replaces all seed images with photos featuring African American people,
    /// matching the HBCU context of Southern University. Also fixes any
    /// previously-known broken (404) or duplicate URLs in older stores.
    ///
    /// The map includes every original URL AND every intermediate replacement
    /// from prior migrations, so stores at any version converge to the same
    /// final set of images. Idempotent — already-migrated URLs are not in the
    /// map and won't be touched.
    private static func migrateImagesIfNeeded(context: ModelContext) {
        let posts = (try? context.fetch(FetchDescriptor<Post>())) ?? []
        let internships = (try? context.fetch(FetchDescriptor<Internship>())) ?? []
        var changed = false

        // Comprehensive old → new mapping. Every old seed URL maps to a
        // verified Unsplash photo featuring African American people.
        let imageMigration: [String: String] = [
            // Post images — originals
            "https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1683121441862-6655883f6f26?w=1200&q=80",
            "https://images.unsplash.com/photo-1579154204601-01588f351e67?w=1200&q=80": "https://images.unsplash.com/photo-1650295894392-7fea9aa5a5a1?w=1200&q=80",
            "https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=1200&q=80": "https://images.unsplash.com/photo-1573164574397-dd250bc8a598?w=1200&q=80",
            "https://images.unsplash.com/photo-1537318096810-9ac7f37a6bf5?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1661666787648-3ca0b992f231?w=1200&q=80",
            "https://images.unsplash.com/photo-1589156280159-27698a70f29e?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1663032618920-6cc64f857e65?w=1200&q=80",
            "https://images.unsplash.com/photo-1551836022-deb4988cc6c0?w=1200&q=80": "https://images.unsplash.com/photo-1653566031535-bcf33e1c2893?w=1200&q=80",
            "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=1200&q=80": "https://images.unsplash.com/photo-1594750852517-f37738fa2384?w=1200&q=80",
            "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=1200&q=80": "https://images.unsplash.com/photo-1739298061740-5ed03045b280?w=1200&q=80",
            "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1200&q=80": "https://images.unsplash.com/photo-1583911860345-9ae84483d7af?w=1200&q=80",
            "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1707155465527-c5a2935b21cc?w=1200&q=80",
            "https://images.unsplash.com/photo-1573164713988-8665fc963095?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1707155466125-a7943a37e8f9?w=1200&q=80",
            "https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1723809616710-32afb9dcd0ef?w=1200&q=80",
            "https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1663047123207-700b30db6c5a?w=1200&q=80",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1661331617718-e99db3b0e64f?w=1200&q=80",
            "https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1683141136472-bd21514555a2?w=1200&q=80",
            "https://images.unsplash.com/photo-1556761175-b413da4baf72?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1661950149025-d14cfbf034e8?w=1200&q=80",
            // Post images — old broken-URL intermediates (already replaced
            // in prior migrations, but mapped here for completeness)
            "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1200&q=80": "https://images.unsplash.com/photo-1594750852517-f37738fa2384?w=1200&q=80",
            "https://images.unsplash.com/photo-1507668077129-56e32806f5cf?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1663047123207-700b30db6c5a?w=1200&q=80",
            // Internship images — originals
            "https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1664299932474-bf48fd8f69fd?w=1200&q=80",
            "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1663047716627-e0b6c878761e?w=1200&q=80",
            "https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1683134022335-921a23ff37a3?w=1200&q=80",
            "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1767693153003-77a0ce8d1ce6?w=1200&q=80",
            "https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1683121354992-8320a2c82d49?w=1200&q=80",
            "https://images.unsplash.com/photo-1542435503-956c469947f6?w=1200&q=80": "https://images.unsplash.com/photo-1753545975907-dcb51efdd0d5?w=1200&q=80",
            "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1683121131650-0812edec7ed6?w=1200&q=80",
            // Internship images — old broken-URL intermediates
            "https://images.unsplash.com/photo-1521791136064-7986c5920216?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1664299932474-bf48fd8f69fd?w=1200&q=80",
            "https://images.unsplash.com/photo-1562774035-b90858418b09?w=1200&q=80": "https://plus.unsplash.com/premium_photo-1683121354992-8320a2c82d49?w=1200&q=80",
        ]

        for post in posts {
            var urlsChanged = false
            post.imageURLs = post.imageURLs.map { url in
                if let replacement = imageMigration[url] {
                    urlsChanged = true
                    return replacement
                }
                return url
            }
            if urlsChanged { changed = true }
        }

        for internship in internships {
            if let replacement = imageMigration[internship.imageURL] {
                internship.imageURL = replacement
                changed = true
            }
            if internship.imageURL.isEmpty && internship.company == "Boston Dynamics" {
                internship.imageURL = "https://plus.unsplash.com/premium_photo-1683121131650-0812edec7ed6?w=1200&q=80"
                changed = true
            }
        }

        if changed { try? context.save() }
    }

    /// Adds SEAS section content from subenchmark.blooksy.com to existing stores
    /// that were seeded before the SEAS articles were available.
    private static func seedSEASContentIfNeeded(context: ModelContext) {
        let existingPosts = (try? context.fetch(FetchDescriptor<Post>())) ?? []
        let hasSEASContent = existingPosts.contains { $0.category?.name == "SEAS" }
        guard !hasSEASContent else { return }

        let users = (try? context.fetch(FetchDescriptor<AppUser>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<PostCategory>())) ?? []
        let seasCategory = categories.first { $0.name == "SEAS" }
        let lealon = users.first { $0.username == "lealon" }
        let paisley = users.first { $0.username == "paisley" }
        let admin = users.first { $0.username == "ajoiner" }

        guard seasCategory != nil else { return }

        let day: TimeInterval = 86_400

        func seasPost(
            title: String,
            summary: String,
            body: String,
            image: String,
            author: AppUser?,
            daysAgo: Double,
            ctaText: String = "",
            ctaURL: String = ""
        ) -> Post {
            let post = Post(
                title: title,
                summary: summary,
                bodyText: body,
                imageURLs: [image],
                ctaText: ctaText,
                ctaURL: ctaURL,
                publishDate: Date(timeIntervalSinceNow: -daysAgo * day),
                status: .published,
                author: author,
                category: seasCategory
            )
            post.publishedAt = post.publishDate
            return post
        }

        let seasPosts: [Post] = [
            seasPost(
                title: "SEAS: The #1 Producer of Black Engineers",
                summary: "The Southern University Engineering Alumni Society is on a mission to restore SU's engineering program to national preeminence by 2031.",
                body: "The Southern University Engineering Alumni Society (SEAS) is leading a bold initiative to reestablish Southern University's Engineering Program as the premier producer of Black engineers in the nation.\n\nThe numbers tell a story of ambition: SEAS has set a goal to become the #1 producer of Black engineers by 2031, with an interim objective to double the current number of engineering graduates by 2027.\n\nExcellence. Pride. Tradition. These are the values that drive SEAS and every alum who gives back to make the vision a reality.\n\nAreas of Impact\n\nSEAS focuses its efforts across five strategic pillars:\n\n1. Recruiting — Attracting the next generation of talented students to Southern's engineering programs.\n2. Scholarship — Supporting students financially so they can focus on their education and graduate on time.\n3. Engagement & Outreach — Keeping alumni connected and active in the life of the college.\n4. Partnerships — Building bridges between the university and industry leaders.\n5. Fundraising — Securing the resources needed to invest in faculty, facilities, and student success.\n\nThe roadmap to 2031 is ambitious but achievable. With the collective power of Southern University alumni, SEAS is building a pipeline that will transform the landscape of engineering for generations to come.",
                image: "https://images.unsplash.com/photo-1594750852517-f37738fa2384?w=1200&q=80",
                author: admin,
                daysAgo: 20,
                ctaText: "Join SEAS",
                ctaURL: "https://subenchmark.blooksy.com/seas"
            ),
            seasPost(
                title: "Jaguars Making a Difference: Alumni Leading in Industry",
                summary: "From NASA to Microsoft to MIT, SEAS alumni are carrying the Southern University legacy into the highest levels of science and engineering.",
                body: "Southern University engineering alumni are making their mark across the country — and the world. The SEAS alumni spotlight series, Jaguars Making a Difference, highlights graduates who exemplify the excellence, pride, and tradition of SU's engineering program.\n\nDr. Keisha Williams — NASA Systems Engineer\n\n\"SU prepared me to solve problems at the highest level,\" says Dr. Williams, who works on guidance systems for NASA's deep-space missions. Her journey from the Bluff to the Johnson Space Center is a testament to the foundation Southern provides.\n\nMicrosoft Software Architect\n\nA former SU computer science graduate now shapes the architecture of cloud services used by millions. \"The mentorship I received here changed the trajectory of my career,\" he reflects. Today he mentors SU interns at Microsoft's Redmond campus.\n\nDr. Aaliyah Brooks — Professor, MIT\n\n\"I returned to academia because SU showed me the power of research,\" says Dr. Brooks, now a professor at the Massachusetts Institute of Technology. Her work in computational biology bridges engineering and medicine, and she collaborates with SU faculty on joint publications.\n\nThese stories represent just a fraction of the impact Southern University engineering alumni are having. SEAS is committed to amplifying these voices and building the networks that help the next generation follow in their footsteps.",
                image: "https://images.unsplash.com/photo-1739298061740-5ed03045b280?w=1200&q=80",
                author: lealon,
                daysAgo: 18,
                ctaText: "Nominate an Alum",
                ctaURL: "https://subenchmark.blooksy.com/nominate"
            ),
            seasPost(
                title: "Research That Drives Impact: AI, Energy, Security, and Biomedicine",
                summary: "Southern University faculty and students are tackling real-world challenges across four frontier research areas.",
                body: "Research at the College of Sciences and Engineering isn't confined to the lab — it addresses real-world challenges that shape communities and industries.\n\nArtificial Intelligence\n\nFaculty and students are advancing machine learning, computer vision, and natural language processing. From automated crop analysis for Louisiana agriculture to AI-driven tutoring systems, SU researchers are putting intelligent systems to work.\n\nRenewable Energy\n\nThe renewable energy focus spans solar optimization, next-generation battery systems, and sustainable power grid design. SU's partnership with Entergy gives students hands-on access to utility-grade hardware and live substation data.\n\nCybersecurity\n\nSecuring critical infrastructure is a national priority, and SU is contributing. The cybersecurity program — recently designated a National Center of Academic Excellence — focuses on network defense, threat analysis, and secure systems design.\n\nBiomedical Research\n\nAt the intersection of engineering and medicine, SU researchers are exploring health informatics and computational biology. Collaborations with LSU Health Sciences Center open pathways for students interested in medical technology and bioinformatics.\n\nThese four areas represent the frontier of engineering research at Southern University — and they're producing graduates ready to lead in each field.",
                image: "https://images.unsplash.com/photo-1583911860345-9ae84483d7af?w=1200&q=80",
                author: paisley,
                daysAgo: 14
            ),
            seasPost(
                title: "Partnering With Industry Leaders: From Classroom to Career",
                summary: "Corporate partnerships with companies like Northrop Grumman provide internships, research funding, and direct career pathways for SU engineering students.",
                body: "The College of Sciences and Engineering has built a network of industry partnerships that transforms the student experience from day one. These collaborations provide internships, research funding, and direct classroom-to-career pathways.\n\nNorthrop Grumman: A Strategic Partnership\n\nNorthrop Grumman's partnership with SU includes sponsored capstone projects, a dedicated scholarship pipeline, and guaranteed interview slots for graduating seniors. The aerospace and defense giant has hired dozens of SU engineering alumni over the past decade.\n\nBeyond Northrop Grumman, the college maintains active partnerships with IBM, NASA Michoud, Entergy, Dow, and the Louisiana Department of Transportation. These relationships ensure that SU students graduate with real-world experience and professional networks already in place.\n\n\"Our industry partners don't just write checks — they sit on our advisory board, guest-lecture in our courses, and mentor our students,\" said Dean Patricia Lofton. \"That's what makes the pipeline model work.\"\n\nFor students, the impact is tangible: internships lead to return offers, capstone projects become portfolios, and mentorship relationships last well beyond graduation.",
                image: "https://plus.unsplash.com/premium_photo-1707155465527-c5a2935b21cc?w=1200&q=80",
                author: lealon,
                daysAgo: 10,
                ctaText: "Become a Partner",
                ctaURL: "https://subenchmark.blooksy.com/partners"
            ),
            seasPost(
                title: "Engineering Career Fair: February 15",
                summary: "Connect with top employers including NASA, IBM, Entergy, and Northrop Grumman. 10:00 AM – 2:00 PM in the Smith-Brown Memorial Union.",
                body: "The Engineering Career Fair returns Friday, February 15 from 10:00 AM to 2:00 PM in the Smith-Brown Memorial Union Ballroom.\n\nThis is the premier recruiting event of the spring semester for engineering and computer science students. Registered employers include NASA Michoud, IBM, Entergy, Dow, Northrop Grumman, and the Louisiana Department of Transportation.\n\nStudents should bring printed resumes and dress professionally. A resume review station opens at 9:00 AM outside the ballroom, staffed by SEAS alumni volunteers.\n\nSEAS members will also host an informal meet-and-greet with recruiters from 9:30 to 9:50 AM — a great opportunity to make connections before the doors open.",
                image: "https://plus.unsplash.com/premium_photo-1707155466125-a7943a37e8f9?w=1200&q=80",
                author: paisley,
                daysAgo: 6,
                ctaText: "Register to Attend",
                ctaURL: "https://subenchmark.blooksy.com/career-fair"
            ),
            seasPost(
                title: "SEAS Alumni Networking Night: March 22",
                summary: "Reconnect with fellow Jaguars and meet current students at this evening of networking, mentorship, and celebration. 5:30 PM – 8:00 PM.",
                body: "The Southern University Engineering Alumni Society invites all engineering and CS alumni to SEAS Alumni Networking Night on Saturday, March 22 from 5:30 PM to 8:00 PM.\n\nThe evening features:\n\n• A keynote address by a distinguished SEAS alum\n• Small-group mentorship circles pairing alumni with current students\n• An industry panel on career pathways in engineering\n• Heavy hors d'oeuvres and cocktails\n\nThis is one of SEAS's flagship events of the year — a chance to reconnect with old friends, meet the next generation of SU engineers, and strengthen the network that makes Southern University's engineering alumni community so powerful.\n\nLocation: Royal Cotillion Ballroom, Smith-Brown Memorial Union.",
                image: "https://plus.unsplash.com/premium_photo-1723809616710-32afb9dcd0ef?w=1200&q=80",
                author: admin,
                daysAgo: 4,
                ctaText: "RSVP Now",
                ctaURL: "https://subenchmark.blooksy.com/seas-networking"
            ),
            seasPost(
                title: "Research Symposium 2026: April 10",
                summary: "A full day of faculty and student research presentations across AI, energy, cybersecurity, and biomedical engineering. 9:00 AM – 4:00 PM.",
                body: "The annual Research Symposium returns Thursday, April 10 from 9:00 AM to 4:00 PM in the College of Sciences and Engineering building.\n\nThe symposium showcases the breadth of research happening across the college, with poster sessions, oral presentations, and live demonstrations in four tracks:\n\n• Artificial Intelligence & Machine Learning\n• Renewable Energy & Power Systems\n• Cybersecurity & Network Defense\n• Biomedical Engineering & Health Informatics\n\nA highlight of the day is the student poster competition, where undergraduate and graduate researchers present their work to a panel of industry judges. Cash prizes are awarded for the top three posters.\n\nThe symposium is free and open to the public. Lunch is provided for registered attendees.\n\nWhether you're a student looking to present, an alum interested in the latest research, or an industry partner scouting talent, the Research Symposium is the best single-day look at what's happening in SU engineering.",
                image: "https://plus.unsplash.com/premium_photo-1663047123207-700b30db6c5a?w=1200&q=80",
                author: paisley,
                daysAgo: 3,
                ctaText: "Register to Attend",
                ctaURL: "https://subenchmark.blooksy.com/symposium"
            ),
        ]

        seasPosts.forEach { context.insert($0) }
        try? context.save()
    }

    /// Adds the Publisher role users and the eryll admin account to existing
    /// stores that were seeded before the four-role system was introduced.
    /// Also migrates old `.approved` scheduled posts to `.published`.
    private static func migrateToFourRoles(context: ModelContext) {
        let existingUsers = (try? context.fetch(FetchDescriptor<AppUser>())) ?? []
        var changed = false

        // Add eryll admin if missing, or update the name if it was seeded
        // before the full name was added.
        if let existingEryll = existingUsers.first(where: { $0.username == "eryll" }) {
            if existingEryll.fullName != "Eryll Cawed" {
                existingEryll.fullName = "Eryll Cawed"
                if existingEryll.email.isEmpty { existingEryll.email = "eryll@blooksy.com" }
                changed = true
            }
        } else {
            let eryll = AppUser(
                username: "eryll",
                fullName: "Eryll Cawed",
                title: "Administrator",
                role: .admin,
                email: "eryll@blooksy.com"
            )
            context.insert(eryll)
            changed = true
        }

        // Add Lee Hampton (publisher) if missing
        if !existingUsers.contains(where: { $0.username == "lhampton" }) {
            let lee = AppUser(
                username: "lhampton",
                fullName: "Lee Hampton",
                title: "Publisher & Contributor",
                role: .publisher
            )
            context.insert(lee)
            changed = true
        }

        // Add Regina Lacy (publisher) if missing
        if !existingUsers.contains(where: { $0.username == "rlacy" }) {
            let regina = AppUser(
                username: "rlacy",
                fullName: "Regina Lacy",
                title: "Publisher & Contributor",
                role: .publisher
            )
            context.insert(regina)
            changed = true
        }

        // Give Anthony Joiner his email if missing
        if let ajoiner = existingUsers.first(where: { $0.username == "ajoiner" }),
           ajoiner.email.isEmpty {
            ajoiner.email = "ajoiner@subenchmark.blooksy.com"
            changed = true
        }

        // Migrate old `.approved` scheduled posts to `.published`.
        // In the old two-step model, `.approved` meant "live on the publish date."
        // Now `.approved` means "approved, waiting for a publisher" and only
        // `.published` is live. Old approved posts with past publish dates
        // need to become `.published` so they stay on the site.
        let posts = (try? context.fetch(FetchDescriptor<Post>())) ?? []
        for post in posts {
            if post.status == .approved && post.publishDate <= .now {
                post.status = .published
                changed = true
            }
        }

        if changed { try? context.save() }
    }

    static func seedIfNeeded(context: ModelContext) {
        let existingUsers = (try? context.fetch(FetchDescriptor<AppUser>())) ?? []
        let hasCurrentSeed = existingUsers.contains { $0.username == "lealon" && $0.fullName == "Lealon Martin" }
        let hasNewAdmin = existingUsers.contains { $0.username == "ajoiner" }
        let hasFourRoles = existingUsers.contains { $0.username == "eryll" }
        if !existingUsers.isEmpty && hasCurrentSeed && hasNewAdmin {
            migrateBranding(context: context)
            seedSEASContentIfNeeded(context: context)
            migrateImagesIfNeeded(context: context)
            if !hasFourRoles {
                migrateToFourRoles(context: context)
            }
            return
        }

        if !existingUsers.isEmpty {
            // Old demo data — wipe and reseed with the current roster.
            try? context.delete(model: Post.self)
            try? context.delete(model: PostCategory.self)
            try? context.delete(model: SiteSettings.self)
            try? context.delete(model: AppUser.self)
            try? context.delete(model: Internship.self)
        }

        // Users — four roles with granular permissions.
        // Approver: review submitted content, approve or reject.
        // Publisher: publish approved content, schedule, unpublish.
        // Admin: full access to everything.
        let lealon = AppUser(
            username: "lealon",
            fullName: "Dr. Lealon Martin",
            title: "Approver & Contributor",
            role: .approver
        )
        let paisley = AppUser(
            username: "paisley",
            fullName: "Paisley Martin",
            title: "Approver & Contributor",
            role: .approver
        )
        let lee = AppUser(
            username: "lhampton",
            fullName: "Lee Hampton",
            title: "Publisher & Contributor",
            role: .publisher
        )
        let regina = AppUser(
            username: "rlacy",
            fullName: "Regina Lacy",
            title: "Publisher & Contributor",
            role: .publisher
        )
        let admin = AppUser(
            username: "ajoiner",
            fullName: "Anthony Joiner",
            title: "Digital Platforms Administrator",
            role: .admin,
            email: "ajoiner@subenchmark.blooksy.com"
        )
        let eryll = AppUser(
            username: "eryll",
            fullName: "Eryll Cawed",
            title: "Administrator",
            role: .admin,
            email: "eryll@blooksy.com"
        )
        [lealon, paisley, lee, regina, admin, eryll].forEach { context.insert($0) }

        // Categories (site top navigation order)
        let names: [(String, String)] = [
            ("CSE News", "Computer Science & Engineering headlines"),
            ("SEAS", "School of Engineering & Applied Sciences"),
            ("Research", "Faculty and student research highlights"),
            ("Alumni Spotlight", "Where Jaguars land after graduation"),
            ("Industry Partnerships", "Corporate and agency collaborations"),
            ("Student Spotlight", "Outstanding student achievements"),
            ("Upcoming Events", "Lectures, fairs and campus events"),
        ]
        var categories: [String: PostCategory] = [:]
        for (index, entry) in names.enumerated() {
            let category = PostCategory(name: entry.0, details: entry.1, sortOrder: index)
            context.insert(category)
            categories[entry.0] = category
        }

        context.insert(SiteSettings())

        let day: TimeInterval = 86_400

        func publishedPost(
            title: String,
            summary: String,
            body: String,
            image: String,
            video: String = "",
            category: String,
            author: AppUser,
            daysAgo: Double,
            ctaText: String = "",
            ctaURL: String = ""
        ) -> Post {
            let post = Post(
                title: title,
                summary: summary,
                bodyText: body,
                imageURLs: [image],
                videoURL: video,
                ctaText: ctaText,
                ctaURL: ctaURL,
                publishDate: Date(timeIntervalSinceNow: -daysAgo * day),
                status: .published,
                author: author,
                category: categories[category]
            )
            post.publishedAt = post.publishDate
            return post
        }

        // Every image below is unique — no two articles share the same photo.
        let posts: [Post] = [
            publishedPost(
                title: "Jaguar Robotics Takes First at Regional Design Challenge",
                summary: "The SU robotics team out-engineered 22 universities with an autonomous rover built in one semester.",
                body: "The Southern University robotics team claimed first place at the Gulf Coast Regional Design Challenge this weekend, edging out 22 competing programs.\n\nTheir rover, nicknamed \"Bayou One,\" completed the autonomous navigation course in a record 4 minutes 12 seconds. The team of nine undergraduates spent the fall semester designing the chassis, drive train, and vision stack from scratch.\n\n\"Every subsystem was student-built,\" said faculty advisor Dr. Renee Caldwell. \"That is what made this win special.\"\n\nThe team advances to the national finals in Atlanta this spring.",
                image: "https://plus.unsplash.com/premium_photo-1683121441862-6655883f6f26?w=1200&q=80",
                category: "CSE News",
                author: lealon,
                daysAgo: 2,
                ctaText: "Support the Robotics Program",
                ctaURL: "https://subenchmark.blooksy.com/give"
            ),
            publishedPost(
                title: "NSF Awards $2.4M for Coastal Resilience Research",
                summary: "A cross-disciplinary team will model levee performance under extreme weather across South Louisiana.",
                body: "The National Science Foundation has awarded Southern University a $2.4 million grant to study coastal infrastructure resilience.\n\nThe three-year project pairs civil engineering faculty with computer science researchers to build digital twins of levee systems across South Louisiana. Graduate assistantships funded by the grant will support twelve students.\n\nPrincipal investigator Dr. Harold Simmons said the work will directly inform parish-level emergency planning.",
                image: "https://images.unsplash.com/photo-1650295894392-7fea9aa5a5a1?w=1200&q=80",
                category: "Research",
                author: paisley,
                daysAgo: 5
            ),
            publishedPost(
                title: "From the Bluff to Silicon Valley: Chelsea Dumas '18",
                summary: "The computer science alumna now leads a platform reliability team at a major cloud provider.",
                body: "When Chelsea Dumas graduated in 2018, she had two job offers and a plan. Six years later she manages a platform reliability engineering team of fourteen in Sunnyvale.\n\n\"Everything I learned about grit, I learned on the Bluff,\" Dumas said during her campus visit last week, where she met with the ACM student chapter and reviewed resumes for graduating seniors.\n\nDumas credits the CS department's systems track and her co-op rotation for her fast start.",
                image: "https://images.unsplash.com/photo-1573164574397-dd250bc8a598?w=1200&q=80",
                category: "Alumni Spotlight",
                author: lealon,
                daysAgo: 8,
                ctaText: "Nominate an Alum",
                ctaURL: "https://subenchmark.blooksy.com/nominate"
            ),
            publishedPost(
                title: "SEAS Partners with Entergy on Grid Modernization Lab",
                summary: "A new on-campus lab gives students hands-on experience with smart-grid hardware and utility data.",
                body: "The School of Engineering and Applied Sciences has signed a five-year partnership with Entergy to open a Grid Modernization Laboratory on campus.\n\nThe lab features utility-grade switchgear, phasor measurement units, and a live data feed from regional substations. Up to 40 students per semester will complete practicum hours in the facility.\n\n\"This is the pipeline model working exactly as intended,\" said Dean Patricia Lofton.",
                image: "https://plus.unsplash.com/premium_photo-1661666787648-3ca0b992f231?w=1200&q=80",
                category: "Industry Partnerships",
                author: paisley,
                daysAgo: 12
            ),
            publishedPost(
                title: "Senior Amara Fields Named Goldwater Scholar",
                summary: "The chemistry and computer science double major is SU's third Goldwater recipient in five years.",
                body: "Senior Amara Fields has been named a 2026 Goldwater Scholar, the nation's premier undergraduate award in the natural sciences, mathematics, and engineering.\n\nFields' research applies machine learning to predict catalyst performance for green hydrogen production. She plans to pursue a Ph.D. in computational chemistry.\n\nShe is Southern's third Goldwater recipient in five years.",
                image: "https://plus.unsplash.com/premium_photo-1663032618920-6cc64f857e65?w=1200&q=80",
                category: "Student Spotlight",
                author: lealon,
                daysAgo: 15
            ),
            publishedPost(
                title: "Spring Career & Internship Fair: February 12",
                summary: "More than 60 employers will recruit in the Smith-Brown Memorial Union. Professional dress required.",
                body: "The Spring Career & Internship Fair returns Thursday, February 12 from 9 a.m. to 2 p.m. in the Smith-Brown Memorial Union Ballroom.\n\nMore than 60 employers are registered, including NASA Michoud, IBM, Entergy, Dow, and the Louisiana Department of Transportation.\n\nStudents should bring printed resumes and dress professionally. A resume review station opens at 8 a.m. outside the ballroom.",
                image: "https://images.unsplash.com/photo-1653566031535-bcf33e1c2893?w=1200&q=80",
                video: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                category: "Upcoming Events",
                author: paisley,
                daysAgo: 1,
                ctaText: "Register to Attend",
                ctaURL: "https://subenchmark.blooksy.com/career-fair"
            ),
            // SEAS section content from subenchmark.blooksy.com
            publishedPost(
                title: "SEAS: The #1 Producer of Black Engineers",
                summary: "The Southern University Engineering Alumni Society is on a mission to restore SU's engineering program to national preeminence by 2031.",
                body: "The Southern University Engineering Alumni Society (SEAS) is leading a bold initiative to reestablish Southern University's Engineering Program as the premier producer of Black engineers in the nation.\n\nThe numbers tell a story of ambition: SEAS has set a goal to become the #1 producer of Black engineers by 2031, with an interim objective to double the current number of engineering graduates by 2027.\n\nExcellence. Pride. Tradition. These are the values that drive SEAS and every alum who gives back to make the vision a reality.\n\nAreas of Impact\n\nSEAS focuses its efforts across five strategic pillars:\n\n1. Recruiting — Attracting the next generation of talented students to Southern's engineering programs.\n2. Scholarship — Supporting students financially so they can focus on their education and graduate on time.\n3. Engagement & Outreach — Keeping alumni connected and active in the life of the college.\n4. Partnerships — Building bridges between the university and industry leaders.\n5. Fundraising — Securing the resources needed to invest in faculty, facilities, and student success.\n\nThe roadmap to 2031 is ambitious but achievable. With the collective power of Southern University alumni, SEAS is building a pipeline that will transform the landscape of engineering for generations to come.",
                image: "https://images.unsplash.com/photo-1594750852517-f37738fa2384?w=1200&q=80",
                category: "SEAS",
                author: admin,
                daysAgo: 20,
                ctaText: "Join SEAS",
                ctaURL: "https://subenchmark.blooksy.com/seas"
            ),
            publishedPost(
                title: "Jaguars Making a Difference: Alumni Leading in Industry",
                summary: "From NASA to Microsoft to MIT, SEAS alumni are carrying the Southern University legacy into the highest levels of science and engineering.",
                body: "Southern University engineering alumni are making their mark across the country — and the world. The SEAS alumni spotlight series, Jaguars Making a Difference, highlights graduates who exemplify the excellence, pride, and tradition of SU's engineering program.\n\nDr. Keisha Williams — NASA Systems Engineer\n\n\"SU prepared me to solve problems at the highest level,\" says Dr. Williams, who works on guidance systems for NASA's deep-space missions. Her journey from the Bluff to the Johnson Space Center is a testament to the foundation Southern provides.\n\nMicrosoft Software Architect\n\nA former SU computer science graduate now shapes the architecture of cloud services used by millions. \"The mentorship I received here changed the trajectory of my career,\" he reflects. Today he mentors SU interns at Microsoft's Redmond campus.\n\nDr. Aaliyah Brooks — Professor, MIT\n\n\"I returned to academia because SU showed me the power of research,\" says Dr. Brooks, now a professor at the Massachusetts Institute of Technology. Her work in computational biology bridges engineering and medicine, and she collaborates with SU faculty on joint publications.\n\nThese stories represent just a fraction of the impact Southern University engineering alumni are having. SEAS is committed to amplifying these voices and building the networks that help the next generation follow in their footsteps.",
                image: "https://images.unsplash.com/photo-1739298061740-5ed03045b280?w=1200&q=80",
                category: "SEAS",
                author: lealon,
                daysAgo: 18,
                ctaText: "Nominate an Alum",
                ctaURL: "https://subenchmark.blooksy.com/nominate"
            ),
            publishedPost(
                title: "Research That Drives Impact: AI, Energy, Security, and Biomedicine",
                summary: "Southern University faculty and students are tackling real-world challenges across four frontier research areas.",
                body: "Research at the College of Sciences and Engineering isn't confined to the lab — it addresses real-world challenges that shape communities and industries.\n\nArtificial Intelligence\n\nFaculty and students are advancing machine learning, computer vision, and natural language processing. From automated crop analysis for Louisiana agriculture to AI-driven tutoring systems, SU researchers are putting intelligent systems to work.\n\nRenewable Energy\n\nThe renewable energy focus spans solar optimization, next-generation battery systems, and sustainable power grid design. SU's partnership with Entergy gives students hands-on access to utility-grade hardware and live substation data.\n\nCybersecurity\n\nSecuring critical infrastructure is a national priority, and SU is contributing. The cybersecurity program — recently designated a National Center of Academic Excellence — focuses on network defense, threat analysis, and secure systems design.\n\nBiomedical Research\n\nAt the intersection of engineering and medicine, SU researchers are exploring health informatics and computational biology. Collaborations with LSU Health Sciences Center open pathways for students interested in medical technology and bioinformatics.\n\nThese four areas represent the frontier of engineering research at Southern University — and they're producing graduates ready to lead in each field.",
                image: "https://images.unsplash.com/photo-1583911860345-9ae84483d7af?w=1200&q=80",
                category: "SEAS",
                author: paisley,
                daysAgo: 14
            ),
            publishedPost(
                title: "Partnering With Industry Leaders: From Classroom to Career",
                summary: "Corporate partnerships with companies like Northrop Grumman provide internships, research funding, and direct career pathways for SU engineering students.",
                body: "The College of Sciences and Engineering has built a network of industry partnerships that transforms the student experience from day one. These collaborations provide internships, research funding, and direct classroom-to-career pathways.\n\nNorthrop Grumman: A Strategic Partnership\n\nNorthrop Grumman's partnership with SU includes sponsored capstone projects, a dedicated scholarship pipeline, and guaranteed interview slots for graduating seniors. The aerospace and defense giant has hired dozens of SU engineering alumni over the past decade.\n\nBeyond Northrop Grumman, the college maintains active partnerships with IBM, NASA Michoud, Entergy, Dow, and the Louisiana Department of Transportation. These relationships ensure that SU students graduate with real-world experience and professional networks already in place.\n\n\"Our industry partners don't just write checks — they sit on our advisory board, guest-lecture in our courses, and mentor our students,\" said Dean Patricia Lofton. \"That's what makes the pipeline model work.\"\n\nFor students, the impact is tangible: internships lead to return offers, capstone projects become portfolios, and mentorship relationships last well beyond graduation.",
                image: "https://plus.unsplash.com/premium_photo-1707155465527-c5a2935b21cc?w=1200&q=80",
                category: "SEAS",
                author: lealon,
                daysAgo: 10,
                ctaText: "Become a Partner",
                ctaURL: "https://subenchmark.blooksy.com/partners"
            ),
            publishedPost(
                title: "Engineering Career Fair: February 15",
                summary: "Connect with top employers including NASA, IBM, Entergy, and Northrop Grumman. 10:00 AM – 2:00 PM in the Smith-Brown Memorial Union.",
                body: "The Engineering Career Fair returns Friday, February 15 from 10:00 AM to 2:00 PM in the Smith-Brown Memorial Union Ballroom.\n\nThis is the premier recruiting event of the spring semester for engineering and computer science students. Registered employers include NASA Michoud, IBM, Entergy, Dow, Northrop Grumman, and the Louisiana Department of Transportation.\n\nStudents should bring printed resumes and dress professionally. A resume review station opens at 9:00 AM outside the ballroom, staffed by SEAS alumni volunteers.\n\nSEAS members will also host an informal meet-and-greet with recruiters from 9:30 to 9:50 AM — a great opportunity to make connections before the doors open.",
                image: "https://plus.unsplash.com/premium_photo-1707155466125-a7943a37e8f9?w=1200&q=80",
                category: "SEAS",
                author: paisley,
                daysAgo: 6,
                ctaText: "Register to Attend",
                ctaURL: "https://subenchmark.blooksy.com/career-fair"
            ),
            publishedPost(
                title: "SEAS Alumni Networking Night: March 22",
                summary: "Reconnect with fellow Jaguars and meet current students at this evening of networking, mentorship, and celebration. 5:30 PM – 8:00 PM.",
                body: "The Southern University Engineering Alumni Society invites all engineering and CS alumni to SEAS Alumni Networking Night on Saturday, March 22 from 5:30 PM to 8:00 PM.\n\nThe evening features:\n\n• A keynote address by a distinguished SEAS alum\n• Small-group mentorship circles pairing alumni with current students\n• An industry panel on career pathways in engineering\n• Heavy hors d'oeuvres and cocktails\n\nThis is one of SEAS's flagship events of the year — a chance to reconnect with old friends, meet the next generation of SU engineers, and strengthen the network that makes Southern University's engineering alumni community so powerful.\n\nLocation: Royal Cotillion Ballroom, Smith-Brown Memorial Union.",
                image: "https://plus.unsplash.com/premium_photo-1723809616710-32afb9dcd0ef?w=1200&q=80",
                category: "SEAS",
                author: admin,
                daysAgo: 4,
                ctaText: "RSVP Now",
                ctaURL: "https://subenchmark.blooksy.com/seas-networking"
            ),
            publishedPost(
                title: "Research Symposium 2026: April 10",
                summary: "A full day of faculty and student research presentations across AI, energy, cybersecurity, and biomedical engineering. 9:00 AM – 4:00 PM.",
                body: "The annual Research Symposium returns Thursday, April 10 from 9:00 AM to 4:00 PM in the College of Sciences and Engineering building.\n\nThe symposium showcases the breadth of research happening across the college, with poster sessions, oral presentations, and live demonstrations in four tracks:\n\n• Artificial Intelligence & Machine Learning\n• Renewable Energy & Power Systems\n• Cybersecurity & Network Defense\n• Biomedical Engineering & Health Informatics\n\nA highlight of the day is the student poster competition, where undergraduate and graduate researchers present their work to a panel of industry judges. Cash prizes are awarded for the top three posters.\n\nThe symposium is free and open to the public. Lunch is provided for registered attendees.\n\nWhether you're a student looking to present, an alum interested in the latest research, or an industry partner scouting talent, the Research Symposium is the best single-day look at what's happening in SU engineering.",
                image: "https://plus.unsplash.com/premium_photo-1663047123207-700b30db6c5a?w=1200&q=80",
                category: "SEAS",
                author: paisley,
                daysAgo: 3,
                ctaText: "Register to Attend",
                ctaURL: "https://subenchmark.blooksy.com/symposium"
            ),
        ]
        posts.forEach { context.insert($0) }

        // Workflow demo content
        let submitted = Post(
            title: "Cybersecurity Club Hosts First Capture-the-Flag Night",
            summary: "Forty students competed in a five-hour CTF covering web exploitation, forensics, and cryptography.",
            bodyText: "The newly chartered Cybersecurity Club hosted its first Capture-the-Flag night on Friday in Pinchback Hall.\n\nForty students competed across beginner and advanced brackets. The winning team, \"Jag Shells,\" solved 19 of 24 challenges.\n\nThe club plans a second event in April with sponsored prizes.",
            imageURLs: ["https://plus.unsplash.com/premium_photo-1661331617718-e99db3b0e64f?w=1200&q=80"],
            notes: "Photos approved by the club president. Please review the third paragraph for accuracy.",
            status: .submitted,
            author: lealon,
            category: categories["CSE News"]
        )
        submitted.submittedAt = Date(timeIntervalSinceNow: -0.5 * day)

        let changes = Post(
            title: "Math Department Colloquium Series Returns",
            summary: "Weekly talks resume this month in Higgins Hall.",
            bodyText: "The mathematics colloquium series resumes this month with weekly talks evry Friday at 3 p.m. in Higgins Hall room 221.",
            imageURLs: [],
            status: .changesRequested,
            author: lealon,
            category: categories["Upcoming Events"]
        )
        changes.reviewFeedback = "Please add the full speaker lineup and a hero image before resubmitting. Also fix the typo in the first paragraph."

        let draft = Post(
            title: "Women in STEM Mentorship Program Opens Applications",
            summary: "Pairs first-year students with faculty and industry mentors.",
            bodyText: "Applications are now open for the Women in STEM mentorship program...",
            status: .draft,
            author: lealon,
            category: categories["Student Spotlight"]
        )

        let scheduled = Post(
            title: "Engineering Week 2026: Full Schedule Announced",
            summary: "Seven days of competitions, demos, and the annual gala — schedule inside.",
            bodyText: "Engineering Week returns March 2-8 with daily competitions, industry demos, the egg-drop classic, and the annual awards gala at the Royal Cotillion Ballroom.\n\nAll events are free for students with a valid ID.",
            imageURLs: ["https://plus.unsplash.com/premium_photo-1683141136472-bd21514555a2?w=1200&q=80"],
            publishDate: Date(timeIntervalSinceNow: 5 * day),
            status: .published,
            author: paisley,
            category: categories["Upcoming Events"]
        )

        // An approved post waiting for a publisher — demonstrates the
        // three-step workflow: Submitted → Approved → Published.
        let approved = Post(
            title: "SU Delegation Attends National Society of Black Engineers Convention",
            summary: "Twelve students networked with recruiters and competed in the hackathon at NSBE 51 in Chicago.",
            bodyText: "Twelve Southern University engineering students traveled to Chicago for the 51st Annual National Society of Black Engineers Convention.\n\nThe delegation participated in the career fair, attended technical workshops, and competed in the Tesla Hackathon. Senior Marcus Reed placed in the top 15 of 200 participants.\n\n\"The energy at NSBE is like nothing else,\" said chapter president Jasmine Thomas. \"You walk in and see 10,000 Black engineers — it changes how you see your future.\"\n\nTravel was funded by SEAS and the Student Government Association.",
            imageURLs: ["https://plus.unsplash.com/premium_photo-1661950149025-d14cfbf034e8?w=1200&q=80"],
            notes: "Group photo provided by Jasmine Thomas. Ready to publish.",
            status: .approved,
            author: lealon,
            category: categories["Student Spotlight"]
        )
        approved.submittedAt = Date(timeIntervalSinceNow: -1.5 * day)

        [submitted, changes, draft, approved, scheduled].forEach { context.insert($0) }

        seedInternships(context: context, authors: [lealon, paisley, lee, regina, admin, eryll])

        try? context.save()
    }

    /// Seeds sample internship listings so the board isn't empty on first launch.
    private static func seedInternships(context: ModelContext, authors: [AppUser]) {
        let lealon = authors.first { $0.username == "lealon" }
        let paisley = authors.first { $0.username == "paisley" }
        let admin = authors.first { $0.username == "ajoiner" }

        // Every image below is unique — no two internships share the same photo.
        let internships: [Internship] = [
            Internship(
                title: "Software Engineering Intern – Summer 2026",
                company: "IBM",
                location: "Austin, TX",
                summary: "Join the cloud platform team building developer tools used by Fortune 500 companies.",
                bodyText: "IBM's Cloud Platform division is seeking summer interns for a 12-week software engineering program. You'll work on real production code, pair with senior engineers, and present a capstone project at summer's end.\n\nQualifications:\n• Currently enrolled in CS, CE, or related major\n• Familiar with Java, Python, or Go\n• Interest in distributed systems\n\nHousing stipend provided for non-local interns.",
                applicationURL: "https://careers.ibm.com/internships",
                imageURL: "https://plus.unsplash.com/premium_photo-1664299932474-bf48fd8f69fd?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: 21 * 86_400),
                isRemote: false,
                isPaid: true,
                isPublished: true,
                category: "Software Engineering",
                author: lealon
            ),
            Internship(
                title: "Data Science Intern – Climate Research Lab",
                company: "NASA Michoud",
                location: "New Orleans, LA",
                summary: "Apply ML to satellite imagery data tracking Gulf Coast wetland loss.",
                bodyText: "NASA's Michoud Assembly Facility is offering a paid data science internship in its Earth Science group. Interns will build machine learning pipelines to classify wetland change from Landsat imagery.\n\nThis is a rare opportunity to work with NASA researchers while staying close to campus. Weekly seminars and mentorship included.\n\nQualifications:\n• Python, NumPy, basic PyTorch or TensorFlow\n• Coursework in statistics or machine learning\n• Rising junior or senior",
                applicationURL: "https://intern.nasa.gov/",
                imageURL: "https://plus.unsplash.com/premium_photo-1663047716627-e0b6c878761e?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: 14 * 86_400),
                isRemote: false,
                isPaid: true,
                isPublished: true,
                category: "Data Science",
                author: paisley
            ),
            Internship(
                title: "Power Systems Engineering Co-op",
                company: "Entergy",
                location: "Baton Rouge, LA",
                summary: "Six-month co-op rotating through grid operations, protection, and planning teams.",
                bodyText: "Entergy's Grid Modernization group is hiring a co-op student for a six-month rotation starting in June. You'll cycle through three teams:\n\n1. Grid Operations – real-time monitoring and event response\n2. Protection & Controls – relay coordination and fault analysis\n3. System Planning – load forecasting and capital project modeling\n\nOpen to EE and CE majors with a 3.0+ GPA. Previous Entergy lab students strongly encouraged to apply.",
                applicationURL: "https://careers.entergy.com/",
                imageURL: "https://plus.unsplash.com/premium_photo-1683134022335-921a23ff37a3?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: 35 * 86_400),
                isRemote: false,
                isPaid: true,
                isPublished: true,
                category: "Electrical Engineering",
                author: lealon
            ),
            Internship(
                title: "Cybersecurity Intern – Threat Analysis",
                company: "Dow Inc.",
                location: "Remote",
                summary: "Remote summer role on the SOC team monitoring industrial control systems.",
                bodyText: "Dow's Global Cybersecurity team is offering a fully remote internship focused on OT/ICS threat monitoring. Interns will shadow analysts, learn SIEM workflows, and contribute to incident response runbooks.\n\nQualifications:\n• Security+ or equivalent coursework\n• Familiarity with Linux command line\n• Interest in industrial control system security\n\nFlexible start date. 40 hours/week for 10 weeks.",
                applicationURL: "https://www.dow.com/en-us/careers",
                imageURL: "https://plus.unsplash.com/premium_photo-1767693153003-77a0ce8d1ce6?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: 10 * 86_400),
                isRemote: true,
                isPaid: true,
                isPublished: true,
                category: "Cybersecurity",
                author: paisley
            ),
            Internship(
                title: "Research Assistant – NSF Coastal Resilience Grant",
                company: "Southern University",
                location: "Baton Rouge, LA",
                summary: "Graduate assistantship funded by the $2.4M NSF grant. Tuition waiver plus stipend.",
                bodyText: "The Civil Engineering department is recruiting two graduate research assistants for the NSF-funded coastal resilience project. Assistants will model levee performance under extreme weather using digital twin simulations.\n\nIncludes full tuition waiver and a $24,000 annual stipend. Must be admitted to or currently enrolled in the MS Civil Engineering program.\n\nContact Dr. Harold Simmons for application details.",
                applicationURL: "mailto:harold.simmons@sus.edu",
                imageURL: "https://plus.unsplash.com/premium_photo-1683121354992-8320a2c82d49?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: 45 * 86_400),
                isRemote: false,
                isPaid: true,
                isPublished: true,
                category: "Research",
                author: admin
            ),
            Internship(
                title: "Frontend Developer Intern – EdTech Startup",
                company: "Blooksy",
                location: "Remote",
                summary: "Build React Native mobile features for a growing education platform.",
                bodyText: "Blooksy is hiring a frontend development intern to work on our mobile publishing platform. You'll ship features that real users interact with daily.\n\nTech stack: React Native, TypeScript, Tailwind. Mentorship from senior engineers. Potential for full-time offer after graduation.\n\nQualifications:\n• JavaScript/TypeScript fundamentals\n• Some React or React Native exposure\n• Portfolio or GitHub project to share",
                applicationURL: "https://blooksy.com/careers",
                imageURL: "https://images.unsplash.com/photo-1753545975907-dcb51efdd0d5?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: -2 * 86_400),
                isRemote: true,
                isPaid: true,
                isPublished: true,
                category: "Software Engineering",
                author: lealon
            ),
            Internship(
                title: "Mechanical Design Intern – Robotics",
                company: "Boston Dynamics",
                location: "Waltham, MA",
                summary: "Help design and prototype components for next-generation legged robots.",
                bodyText: "Boston Dynamics is seeking a mechanical engineering intern for the Spot/Atlas design team. Interns work on real subsystems — from bracket design to actuator testing.\n\nQualifications:\n• SolidWorks or Fusion 360 proficiency\n• Coursework in kinematics and dynamics\n• Hands-on fabrication experience preferred\n\nRelocation assistance provided. 16-week co-op or 12-week summer term available.",
                applicationURL: "https://www.bostondynamics.com/careers",
                imageURL: "https://plus.unsplash.com/premium_photo-1683121131650-0812edec7ed6?w=1200&q=80",
                deadline: Date(timeIntervalSinceNow: 7 * 86_400),
                isRemote: false,
                isPaid: true,
                isPublished: false,
                category: "Mechanical Engineering",
                author: admin
            ),
        ]

        internships.forEach { context.insert($0) }
    }
}
