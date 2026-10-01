# Benchmark CMS — Requirements

Mobile-first CMS iOS app for **Southern University Benchmark** (an HBCU), with role-based content management, a public guest view, an internship board, and Benchmark visual branding.

- **Public site:** subenchmark.blooksy.com
- **Platform:** Native iOS (SwiftUI + SwiftData)
- **Tagline:** "Showcasing Southern University's excellence to the world."
- **Powered by:** the College of Sciences and Engineering (gold italics, under the "Benchmark" site title)

---

## 1. Product Principles

- **Mobile-first**, responsive, fast loading.
- **Public by default** — the app opens to the public news site; no sign-in required. Login is opt-in.
- Every screen has a **back button** returning to the previous screen.
- A pervasive **hovering home button** appears on every screen (except the landing page), returning users to the landing page.
- Every image and article must be **unique** — no duplicate images across articles or internships.

## 2. Roles & Permissions

Four roles with granular permissions:

| Role | Capabilities | Restrictions |
|---|---|---|
| **Contributor** | Create drafts, submit for approval | No approving, publishing, or admin access |
| **Approver** | Review submitted content; approve or reject with feedback notes | No publishing, no admin access |
| **Publisher** | Access approved content; publish / schedule / unpublish / republish | No approving, no admin access |
| **Administrator** | Full access — content, users, roles, categories, settings, approvals, publishing; **overrides any permission** | — |

- **Category assignment:** Admins can assign categories to user accounts. Categories determine workflow permissions and filter the editor's category picker (`assignedCategorySlugs` on the user record).

### Test Accounts

| Name | Username | Role | Email |
|---|---|---|---|
| Eryll Cawed | `eryll` | Administrator | eryll@blooksy.com |
| Anthony Joiner | `ajoiner` | Administrator | ajoiner@subenchmark.blooksy.com |
| Dr. Lealon Martin | `lealon` | Approver (& Contributor) | — |
| Paisley Martin | `paisley` | Approver (& Contributor) | — |
| Lee Hampton | `lhampton` | Publisher (& Contributor) | — |
| Regina Lacy | `rlacy` | Publisher (& Contributor) | — |

## 3. Content Workflow

```
Draft → Submitted → Approved → Published
```

- `.approved` means **"approved, waiting for a publisher"** — it is **NOT live** on the public site.
- Only `.published` is live.
- Full status set: `draft, submitted, changesRequested, rejected, approved, published, archived`.
- Scheduled posts are published with a future publish date; expired posts fall off the site automatically.
- Rich text editor with **autosave**; authentication and role-based permissions throughout.

### Submission Fields

Title, Summary, Body, Images, Video URL, Category, Author, CTA text + URL, Publish date, Expiration date, Notes, Status.

## 4. Public Site

- Top navigation built from **categories**.
- **Search** across posts.
- **Image gallery** per article; **embedded videos** (YouTube).
- **SEO-friendly URLs** — e.g. `/cse-news/robotics-team-wins`.
- Featured/latest post support, configurable in settings.
- **Internship board** with detail views (company, location, deadline, remote/paid badges, apply link).

## 5. Visual Branding

**Do NOT change app functionality, navigation, user flows, layouts, or features — visual branding only.**

### Palette

| Token | Hex | Usage |
|---|---|---|
| Primary Yellow | `#FECE34` | Buttons, CTAs, accents, progress indicators, badges, charts |
| Primary Blue | `#59B6E8` | Links, icons, interactive elements |
| Navy | `#051838` | Dark surfaces, floating home button, app icon background |
| Light Blue | `#63AEE3` | Secondary accents, illustrations |
| White | `#FFFFFF` | Main background — **always white** |

- Brand colors are used for: buttons, CTAs, nav bars, icons, cards, links, progress indicators, badges, charts, background accents, illustrations.
- **Logo variants** (512×512 PNG, alpha): Black, Lightblue, Gold, White.

### Logo Placement

Splash screen, login, onboarding, app headers, profile/about, settings, branded empty states — clean, modern, professional; **do not overuse** (e.g. no logo in the public masthead; the title text remains).

### HBCU Context

All seed imagery must feature **African American / Black people**, consistent with Southern University's community.

## 6. Data & Architecture Notes

- **Persistence:** SwiftData (`@Model`) with in-app seeding on first launch.
- Models: `AppUser`, `PostCategory`, `Post`, `SiteSettings`, `Bookmark`, `Internship`; enums `UserRole`, `PostStatus`.
- Session: `@Observable` SessionManager persisted via UserDefaults; `goHome()` resets all navigation state.
- Navigation: `MainTabView` owns a `NavigationPath` per tab; value-based `NavigationLink`s throughout.
- Images: `CachedAsyncImage` with actor-based `ImageCache` — images are **downscaled before caching**, with count/cost caps and memory-warning purge (prevents jetsam kills on long sessions).
- Video: WKWebView embed with non-persistent data store and teardown cleanup.
- Seed data: 6 users, 7 categories, 13+ articles, 7 internships; idempotent migration functions (branding, images, four-role migration) for existing stores.
- Relationship deletes must **sever inverses and delete children before parents** — `context.delete(model:)` batch deletes fail on `Post/category` (mandatory nullify inverse).

## 7. Publishing Targets

- Public site: **subenchmark.blooksy.com**
- Bundle ID: `app.rork.7vkl6jjx1xbaok9rvrqyn` · iOS deployment target 18.0
