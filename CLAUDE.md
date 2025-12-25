# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Literature** is a mobile social media app (iOS & Android) for sharing and discovering poems, stories, and jokes. Built with Flutter and Firebase, it features vertical-scrolling feeds, Instagram-style stories (24-hour expiry), and a strict monochrome design system.

**Taglines**: "Where words come alive" | "Share your story, one swipe at a time" | "Express. Connect. Inspire."

## Mandatory Technical Requirements

- **Platform**: Flutter (iOS & Android)
- **State Management**: BLoC pattern (required, not optional)
- **Backend**: Firebase only (Auth, Firestore, Storage, Cloud Functions)
- **NO push notifications**: No FCM, in-app notifications only
- **Compliance**: Must be App Store and Play Store compliant
- **Codebase**: Modular architecture for easy maintenance

## State Management Rules (BLoC)

- Use `flutter_bloc` package
- Organize BLoCs by feature domain: `auth_bloc/`, `post_bloc/`, `story_bloc/`, `messaging_bloc/`, `profile_bloc/`, etc.
- Follow strict event-driven architecture:
  - UI dispatches events (e.g., `PostCreated`, `StoryViewed`)
  - BLoC processes logic and emits states
  - UI reacts to state changes only
- Keep business logic OUT of widgets - belongs in BLoCs
- Use `provider` or `riverpod` alongside BLoC for dependency injection if needed

## Firebase Architecture

### Firestore Collections (Exact Structure)

**users/**
```
{userId}
  - username (string)
  - email (string)
  - bio (string)
  - profileImageUrl (string)
  - followersCount (number)
  - followingCount (number)
  - hasActiveStory (boolean) - updated by Cloud Function
  - createdAt (timestamp)
```

**posts/**
```
{postId}
  - authorId (string)
  - content (string)
  - category (string: 'poem' | 'story' | 'joke' | 'other')
  - likesCount (number)
  - commentsCount (number)
  - sharesCount (number)
  - favoritesCount (number)
  - trendingScore (number) - calculated by Cloud Function
  - createdAt (timestamp)
```

**drafts/**
```
{draftId}
  - authorId (string)
  - content (string)
  - category (string)
  - createdAt (timestamp)
  - updatedAt (timestamp)
```

**stories/** (24-hour expiry)
```
{storyId}
  - authorId (string)
  - type (string: 'image' | 'video' | 'text')
  - mediaUrl (string) - for image/video
  - textContent (string) - for text stories
  - backgroundColor (string) - for text stories (black or white only)
  - duration (number) - default 5s for images, video length for videos
  - viewsCount (number)
  - createdAt (timestamp)
  - expiresAt (timestamp) - createdAt + 24 hours
```

**storyViews/**
```
{storyId}_views/{viewerId}
  - viewedAt (timestamp)
  - viewerUsername (string)
  - viewerProfileImage (string)
```

**storyReactions/**
```
{storyId}_{userId}
  - reactionType (string: 'heart' | 'laugh' | 'fire' | etc.)
  - createdAt (timestamp)
```

**comments/**
```
{commentId}
  - postId (string)
  - authorId (string)
  - content (string)
  - parentCommentId (string, nullable) - for nested comments
  - createdAt (timestamp)
```

**likes/, favorites/, shares/** - Use composite keys
```
{userId}_{postId}
  - createdAt (timestamp)
```

**follows/** - Use composite keys
```
{followerId}_{followingId}
  - createdAt (timestamp)
```

**conversations/**
```
{conversationId}
  - participants (array: [userId1, userId2])
  - lastMessage (string)
  - updatedAt (timestamp)
```

**messages/**
```
{conversationId}/messages/{messageId}
  - senderId (string)
  - content (string)
  - isRead (boolean)
  - timestamp (timestamp)
  - replyToStoryId (string, optional) - when replying to a story
```

**notifications/** (In-app only)
```
{userId}/notifications/{notificationId}
  - type (string: 'follow' | 'like' | 'comment' | 'message' | 'story_view' | 'story_reaction')
  - fromUserId (string)
  - postId (string, optional)
  - storyId (string, optional)
  - isRead (boolean)
  - createdAt (timestamp)
```

### Firebase Storage Structure

```
/profile_images/{userId}/
  - Profile pictures

/stories/{userId}/{storyId}.jpg|mp4
  - Story media files (24h temporary)

/post_media/{postId}/
  - Future: post attachments if needed
```

### Cloud Functions (Required)

1. **onPostCreate** - Update trending scores, send notifications
2. **onLike/Comment** - Create notification documents
3. **onFollow** - Create notification document
4. **onStoryCreate** - Update user's `hasActiveStory` field to `true`
5. **onStoryView** - Increment view count, create view record in `storyViews/`
6. **cleanupExpiredStories** - Scheduled (hourly):
   - Delete stories where `expiresAt < now()`
   - Delete associated media from Storage
   - Update user's `hasActiveStory` to `false` if no active stories remain
7. **calculateTrendingScore** - Scheduled (daily or hourly):
   - Formula: `(likesCount * weight1) + (commentsCount * weight2) + (sharesCount * weight3) - (ageInHours * decayFactor)`

## Feature Implementation Rules

### Phase 1: MVP - Core Features

**Authentication**:
- Email/password signup/login via Firebase Auth
- Profile creation: username, bio, profile picture
- No social login in MVP

**Content Creation**:
- Rich text editor with formatting toolbar
- Category selector: Poem / Story / Joke / Other
- Save as draft → Edit draft → Publish workflow
- Published posts move from `drafts/` to `posts/` collection
- Users can delete their own posts only

**Stories Feature** (Instagram-style):
- Upload image/video stories OR create text-only stories
- 24-hour auto-expiry enforced by `expiresAt` timestamp
- Story viewer: tap left (previous), tap right (next), hold (pause), swipe down (exit)
- Story ring indicators: unseen = 2px black ring, seen = 2px gray-300 ring
- Delete own stories only
- Text stories: black or white background only, text auto-inverts for contrast

**Vertical Scrolling Feed**:
- Full-screen post display (one post per screen)
- Swipe down to next post with snap-to-place animation
- Auto-hide UI (header, interaction bar) on scroll
- Show UI on tap/pause

### Phase 2: Social Interactions

**Follow System**:
- Follow/unfollow users
- Display followers/following counts
- **Mutual follow detection required** for messaging eligibility

**Post Interactions**:
- Like (heart icon) - toggle on/off
- Comment (nested comments support via `parentCommentId`)
- Favorite/Bookmark (save for later viewing)
- Share (copy link, share to external apps via `share_plus`)
- Display interaction counts

**Story Interactions**:
- View count (who viewed your story)
- React with emoji (heart, laugh, fire, etc.)
- Reply to stories → Converts to DM **only if mutual follows**, otherwise show "Follow to reply" message

**Messaging** (Mutual Follows Only):
- Direct messages between mutual followers ONLY
- Real-time chat with Firestore listeners
- Message read status (`isRead` field)
- Text-based only in MVP
- Story replies include `replyToStoryId` field

### Phase 3: Discovery & Engagement

**Search**:
- Search users by username/name
- Search posts by keywords, category, or hashtags
- Filter by content type (poems/stories/jokes)

**Trending Section**:
- Algorithm weights: likes, comments, shares, recency
- Time decay factor reduces score over time
- Separate tab or filter in main feed
- Updated by `calculateTrendingScore` Cloud Function

**Notifications** (In-App Only):
- NO push notifications (no FCM)
- In-app notification center accessible from bottom nav
- Types: new follower, like, comment, new message, story view, story reaction
- Unread badge counter
- Mark as read functionality

## Design System Rules (STRICT - NO EXCEPTIONS)

### Design Philosophy
- **Content-first**: Writing > UI. UI must disappear.
- **Monochrome by default**: Black, white, grayscale only. NO accent colors.
- **High contrast**: Accessibility is non-negotiable (≥4.5:1 ratio).
- **Motion with restraint**: Only when it adds meaning.
- **Consistent primitives**: No one-off styles.

### Color System (STRICT)

**Core Palette** (ONLY these colors allowed):
```dart
black: #000000       // Primary text, icons
white: #FFFFFF       // Backgrounds
gray-900: #111111    // Headers, dividers
gray-700: #3A3A3A    // Secondary text
gray-500: #7A7A7A    // Meta text, timestamps
gray-300: #D1D1D1    // Borders
gray-100: #F4F4F4    // Surface backgrounds
```

**Usage Rules**:
- Primary action → Black background + White text
- Secondary action → White background + Black border/text
- Disabled → Gray-300 background + Gray-500 text
- Error → Black text + underline (NO red; use copy + icon)
- **NO accent colors anywhere** - reactions use icons, not color

### Typography Rules

**Font Stack**:
- Primary (Body & UI): **Inter** (fallback: system-ui)
- Secondary (Content/Poems): **Playfair Display** (serif, user-selectable in settings)

**Type Scale**:
```dart
display:  32px / 600 / 1.25  // Titles, Profile names
h1:       24px / 600 / 1.3   // Section headers
h2:       20px / 500 / 1.35  // Card titles
body-lg:  18px / 400 / 1.6   // Poems, stories
body:     16px / 400 / 1.6   // Default text
body-sm:  14px / 400 / 1.5   // Meta
caption:  12px / 400 / 1.4   // Timestamps
```

**Rules**:
- NO text below 12px
- Poems default to `body-lg`
- Jokes default to `body`

### Spacing System (8-pt Grid)

All spacing derives from 8px:
```dart
xs:   4px
sm:   8px
md:   16px
lg:   24px
xl:   32px
2xl:  48px
```

**Usage**:
- Screen padding: `md`
- Card padding: `md`
- Section gap: `lg`
- Feed item gap: `xl`

### Corner Radius

Minimal rounding, avoid "bubble UI":
```dart
none: 0
sm:   4px   // Buttons
md:   8px   // Posts/cards, Images/videos
lg:   12px
full: 999px // Story avatars only
```

### Elevation & Borders

**No shadows unless necessary**:
- Default border: 1px solid gray-300
- Active/Focused border: 1px solid black
- Modals/bottom sheets only: `0px 4px 12px rgba(0,0,0,0.08)`

### Button Specifications

**Primary Button**:
- Background: Black
- Text: White, 16px / 500
- Radius: `sm` (4px)
- Height: 48px

**Secondary Button**:
- Background: White
- Border: 1px black
- Text: Black

**Text Button**:
- No background
- Black text
- Underline on hover/press

**No gradients. No icons in buttons unless necessary.**

### Input & Editor Specs

**Text Fields**:
- Background: White
- Border: 1px gray-300
- Focus: 1px black
- Radius: `sm`
- Padding: `sm` vertical, `md` horizontal

**Rich Text Editor**:
- Toolbar: icons only, monochrome
- Active state: black underline
- Editor background: white
- Placeholder: gray-500

### Feed & Card Design

**Post Card**:
- Background: White
- Padding: `md`
- Radius: `md`
- Divider below content: gray-300

**Interaction Bar**:
- Icons only (like, comment, bookmark, share)
- Display counts in `caption` size
- Active state: bold icon, NOT color change

### Stories UI

**Story Ring**:
- Unseen: 2px black ring
- Seen: 2px gray-300 ring

**Story Viewer**:
- Background: Black
- Text: White
- Controls: 80% white opacity
- Progress bar: white / gray

**Text Stories**:
- Backgrounds: black or white ONLY
- Text auto-inverts for contrast

### Icon Rules

- **Style**: Outlined only
- **Stroke width**: 1.5–2px
- **Color**: Black / White only
- **Library**: lucide or material symbols outlined
- **NO filled icons** except active states

### Motion & Animation

**Durations**:
```dart
Tap feedback:      100ms
Screen transition: 200ms
Story progress:    linear (no easing)
Modal open:        250ms
```

**Easing**:
- `ease-out` for entrances
- `ease-in` for exits
- **NO bounce. NO overshoot.**

### Dark Mode (Default Mode)

Dark mode is the **default**. Exact inversion:

| Light Mode       | Dark Mode           |
|------------------|---------------------|
| White bg         | Black bg            |
| Black text       | White text          |
| Gray-300 borders | Gray-700 borders    |

No reinterpretation - exact color inversion only.

### Accessibility Requirements

- Contrast ratio ≥ 4.5:1
- Dynamic font scaling supported
- Haptics for primary actions
- Tap targets ≥ 44px
- Screen reader support

### Design Debt Kill Switches

**FORBIDDEN**:
- Custom colors per feature
- New fonts without system approval
- Feature-specific UI hacks
- If it needs color to explain → UX is broken, redesign it

## Navigation Structure

**Bottom Navigation Bar** (5 tabs):
1. **Home (Feed)** - Story bar at top, vertical scrolling feed below
2. **Search** - Users & Content search with filters
3. **Create Post (+)** - Modal: choose "Post" or "Story"
4. **Notifications** - In-app notification center (NO push)
5. **Profile** - My profile page

## User Flows

### Story Creation Flow
```
Tap "Create Post" (+)
  ↓
[Content Type?]
  ├─ Post (Poem/Story/Joke) → Existing flow
  └─ Story → Story Creator
      ↓
  [Story Type?]
      ├─ Camera/Gallery → Select Image/Video → Preview
      └─ Text Story → Rich text editor with backgrounds (black/white only)
      ↓
  Add Text/Stickers/Filters (optional)
      ↓
  [Action?]
      ├─ Post Story → Upload to Storage → Create story document in Firestore
      └─ Cancel → Discard
```

### Story Viewing Flow
```
Home Feed → Horizontal Story Bar (top section)
  ↓
[Circular Profile Icons]
  ├─ Own Story: + icon if no story, profile ring if posted
  ├─ Following Users: gradient ring (unseen) or gray ring (seen)
  └─ Tap Story Icon
      ↓
  Full-Screen Story Viewer
      ├─ Tap Left → Previous story/user
      ├─ Tap Right → Next story/user
      ├─ Hold Screen → Pause
      ├─ Swipe Down → Exit viewer
      ├─ Tap Heart → Quick reaction
      ├─ Tap Reply → Open message if mutual, else "Follow to reply"
      └─ View Counter (own stories only)
```

## Required Flutter Packages

```yaml
dependencies:
  # Firebase
  firebase_auth: latest
  cloud_firestore: latest
  firebase_storage: latest

  # State Management
  flutter_bloc: latest

  # UI & Media
  cached_network_image: latest
  image_picker: latest
  video_player: latest
  story_view: latest  # or custom implementation

  # Social Features
  share_plus: latest
  flutter_mentions: latest

  # Utilities
  timeago: latest
```

**DO NOT USE**:
- `firebase_messaging` - No push notifications
- `provider` as state management - Use BLoC

## Development Priorities

### Phase 1 (MVP):
1. User Authentication
2. Content Creation & Management
3. Stories Feature
4. Vertical Scrolling Feed

### Phase 2:
5. Follow System
6. Post Interactions
7. Story Interactions
8. Messaging (Mutual Follows Only)

### Phase 3:
9. Search Functionality
10. Trending Section
11. Notifications (In-App)

## Key Implementation Notes

- **Story expiry**: Enforce 24-hour expiry via `expiresAt` timestamp + hourly Cloud Function cleanup
- **Mutual follows**: Check both `follows/{userA}_{userB}` AND `follows/{userB}_{userA}` exist before allowing DMs
- **Trending**: Use weighted formula with time decay, recalculate periodically
- **Story replies**: Only create DM if mutual follow exists, otherwise show error
- **No push notifications**: All notifications are in-app only via `notifications/` collection
- **Modular structure**: Organize by feature (auth/, posts/, stories/, messaging/, etc.)
- **Composite keys**: Use `{id1}_{id2}` format for many-to-many relationships (likes, follows, etc.)
