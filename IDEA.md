Literature App - Feature Planning & User FlowCore Features (Updated Priority Order)Phase 1: MVP - Core Content & Auth

User Authentication

Email/password signup/login
Profile creation (username, bio, profile picture)
Firebase Authentication



Content Creation & Management

Create posts (poem/story/joke/other - category selector)
Rich text editor with formatting options
Save as draft (Firestore collection: drafts)
Edit drafts before publishing
Publish to main feed (move to posts collection)
Delete own posts



Stories Feature ⭐ NEW

Upload image/video stories (24-hour expiry)
Text-only stories option
View stories in circular profile icons (Instagram-style)
Story viewer with tap-to-next, hold-to-pause
Story ring indicator (seen/unseen)
Delete own stories



Vertical Scrolling Feed

Full-screen post display (one post per screen)
Swipe down to next post with snap-to-place
Auto-hide UI elements (header, interaction bar) on scroll
Show UI on tap/pause


Phase 2: Social Interactions

Follow System

Follow/unfollow users
Following/followers count
Mutual follow detection for messaging eligibility



Post Interactions

Like (heart icon)
Comment (nested comments support)
Favorite/Bookmark (save for later)
Share (copy link, share to external apps)
Interaction counts displayed



Story Interactions

View count (who viewed your story)
React to stories (heart/emoji quick reactions)
Reply to stories (converts to DM if mutual follows)



Messaging (Mutual Follows Only)

Direct messages between mutual followers
Real-time chat with Firebase Firestore
Message read status
Simple text-based (can expand with media later)


Phase 3: Discovery & Engagement

Search Functionality

Search users by username/name
Search posts by keywords, category, or hashtags
Filter by content type (poems/stories/jokes)



Trending Section

Algorithm based on:

Like count (weighted)
Comment count (weighted)
Share count (weighted)
Recency (time decay factor)


Separate tab or filter in main feed
Updates periodically (Firebase Cloud Functions)



Notifications (In-App Only)

No push notifications (removed FCM)
In-app notification center:

New follower
Like on your post
Comment on your post
New message (if mutual)
Story views/reactions


Unread badge counter
Mark as read functionality


Updated User Flow DiagramsMain Navigation Structure
Bottom Navigation Bar:
├─ Home (Feed) - Shows story bar at top
├─ Search (Users & Content)
├─ Create Post (+) - Now has Story option
├─ Notifications (In-app only)
└─ Profile (My Profile)Stories Creation Flow ⭐ NEW
Tap "Create Post" (+)
    ↓
[Content Type?]
    ├─ Post (Poem/Story/Joke) → [Existing flow]
    └─ Story → Story Creator
        ↓
    [Story Type?]
        ├─ Camera/Gallery → Select Image/Video → Preview
        └─ Text Story → Rich text editor with backgrounds
        ↓
    Add Text/Stickers/Filters (optional)
        ↓
    [Action?]
        ├─ Post Story → Upload to Firebase Storage → Create story document
        └─ Cancel → DiscardStories Viewing Flow ⭐ NEW
Home Feed (Top Section)
    ↓
Horizontal Story Bar (Circular Profile Icons)
    ├─ Own Story (+ icon if no story, profile ring if posted)
    ├─ Following Users' Stories (unseen = gradient ring, seen = gray ring)
    └─ Tap Story Icon
        ↓
    Full-Screen Story Viewer
        ├─ Tap Left Side → Previous story/user
        ├─ Tap Right Side → Next story/user
        ├─ Hold Screen → Pause
        ├─ Swipe Down → Exit viewer
        ├─ Tap Heart → Quick reaction
        ├─ Tap Reply → Open message (if mutual) or show "Follow to reply"
        └─ View Counter (for own stories)Updated Feed Interaction Flow
Home Feed
    ↓
[Top Section] Story Bar (horizontal scroll)
    ↓
[Main Section] Vertical Post Feed (same as before)
    ↓
[User Action?]
    ├─ Swipe Down → Load next post
    ├─ Tap Story → Open story viewer
    └─ [All previous interactions remain same]Updated Firebase ArchitectureFirestore Collections
users/
├─ {userId}
    ├─ username, email, bio, profileImageUrl
    ├─ followersCount, followingCount
    ├─ hasActiveStory (boolean) ⭐ NEW
    ├─ createdAt

posts/
├─ {postId}
    ├─ authorId, content, category (poem/story/joke)
    ├─ likesCount, commentsCount, sharesCount, favoritesCount
    ├─ createdAt, trendingScore

stories/ ⭐ NEW
├─ {storyId}
    ├─ authorId
    ├─ type: 'image' | 'video' | 'text'
    ├─ mediaUrl (for image/video) or textContent + backgroundColor (for text)
    ├─ duration (in seconds, default 5 for images, video length for videos)
    ├─ viewsCount
    ├─ createdAt
    ├─ expiresAt (createdAt + 24 hours)

storyViews/ ⭐ NEW
├─ {storyId}_views/
    └─ {viewerId}
        ├─ viewedAt
        ├─ viewerUsername, viewerProfileImage

storyReactions/ ⭐ NEW
├─ {storyId}_{userId}
    ├─ reactionType (heart, laugh, fire, etc.)
    ├─ createdAt

drafts/
├─ {draftId}
    ├─ authorId, content, category
    ├─ createdAt, updatedAt

comments/
├─ {commentId}
    ├─ postId, authorId, content, parentCommentId
    ├─ createdAt

likes/, favorites/, shares/
├─ {userId}_{postId}

follows/
├─ {followerId}_{followingId}

conversations/
├─ {conversationId}
    ├─ participants: [userId1, userId2]
    ├─ lastMessage, updatedAt

messages/
├─ {conversationId}/messages/{messageId}
    ├─ senderId, content, isRead, timestamp
    ├─ replyToStoryId (optional) ⭐ NEW

notifications/
├─ {userId}/notifications/{notificationId}
    ├─ type (follow, like, comment, message, story_view, story_reaction) ⭐ UPDATED
    ├─ fromUserId, postId/storyId (if applicable)
    ├─ isRead, createdAtFirebase Storage

/profile_images/{userId}/ - Profile pictures
/stories/{userId}/{storyId}.jpg|mp4 ⭐ NEW - Story media files
/post_media/{postId}/ - Future post attachments
Cloud Functions (Updated)

onPostCreate → Update trending scores, send notifications
onLike/Comment → Create notification document
onFollow → Create notification document
onStoryCreate → Update user's hasActiveStory field ⭐ NEW
onStoryView → Increment view count, create view record ⭐ NEW
cleanupExpiredStories → Scheduled function (runs hourly) ⭐ NEW

Delete stories where expiresAt < now()
Delete associated media from Storage
Update user's hasActiveStory field


calculateTrendingScore → Scheduled function (daily/hourly)
Technical Implementation NotesUpdated Flutter Packages

firebase_auth - Authentication
cloud_firestore - Database
firebase_storage - Profile images & story media
firebase_messaging - REMOVED (no push notifications)
provider or riverpod - State management
cached_network_image - Image caching
image_picker - Camera/gallery access ⭐ NEW
video_player - Story video playback ⭐ NEW
flutter_mentions - @mentions in comments
share_plus - Native sharing
timeago - Relative timestamps
story_view or custom implementation - Story viewer UI ⭐ NEW