Literature App — Design System (Monochrome)
1. Design Philosophy

Content-first: Writing > UI. UI must disappear.

Monochrome by default: Black, white, grayscale only.

High contrast: Accessibility is non-negotiable.

Motion with restraint: Only when it adds meaning.

Consistent primitives: No one-off styles.

2. Color System (Strict Black & White)
Core Palette
Token	Value	Usage
black	#000000	Primary text, icons
white	#FFFFFF	Backgrounds
gray-900	#111111	Headers, dividers
gray-700	#3A3A3A	Secondary text
gray-500	#7A7A7A	Meta text, timestamps
gray-300	#D1D1D1	Borders
gray-100	#F4F4F4	Surface backgrounds
Semantic Usage

Primary Action → Black background + White text

Secondary Action → White background + Black border/text

Disabled → Gray-300 background + Gray-500 text

Error → Black text + underline (no red; use copy + icon)

No accent colors. Reactions use icons, not color.

3. Typography
Font Stack (Serious + Literary)

Primary (Body & UI):

Inter (fallback: system-ui)

Secondary (Content / Poems):

Playfair Display (serif, optional per post)

Users can choose Sans or Serif reading mode in settings.

Type Scale
Token	Size	Weight	Line Height	Usage
display	32	600	1.25	Titles, Profile names
h1	24	600	1.3	Section headers
h2	20	500	1.35	Card titles
body-lg	18	400	1.6	Poems, stories
body	16	400	1.6	Default text
body-sm	14	400	1.5	Meta
caption	12	400	1.4	Timestamps

Rules

No text below 12px.

Poems default to body-lg.

Jokes default to body.

4. Spacing System (8-pt Grid)

All spacing derives from 8px.

Token	Value
xs	4
sm	8
md	16
lg	24
xl	32
2xl	48

Usage

Screen padding: md

Card padding: md

Section gap: lg

Feed item gap: xl

5. Corner Radius

Minimal rounding. Avoid “bubble UI”.

Token	Radius
none	0
sm	4
md	8
lg	12
full	999 (stories only)

Rules

Posts/cards: md

Buttons: sm

Story avatars: full

Images/videos: md

6. Elevation & Borders

No shadows unless necessary.

Borders

Default: 1px solid gray-300

Active/Focused: 1px solid black

Elevation

Feed: none

Modals / Bottom sheets: subtle shadow

0px 4px 12px rgba(0,0,0,0.08)

7. Buttons
Primary Button

Background: Black

Text: White

Radius: sm

Height: 48px

Font: 16 / 500

Secondary Button

Background: White

Border: 1px black

Text: Black

Text Button

No background

Black text

Underline on hover/press

No gradients. No icons unless necessary.

8. Inputs & Editor
Text Fields

Background: White

Border: 1px gray-300

Focus: 1px black

Radius: sm

Padding: sm vertical, md horizontal

Rich Text Editor

Toolbar: icons only, monochrome

Active state: black underline

Editor background: white

Placeholder: gray-500

9. Feed & Cards
Post Card

Background: White

Padding: md

Radius: md

Divider below content: gray-300

Interaction Bar

Icons only (like, comment, bookmark)

Count in caption

Active state: bold icon, not color

10. Stories UI
Story Ring

Unseen: 2px black ring

Seen: 2px gray-300 ring

Story Viewer

Background: Black

Text: White

Controls: 80% white opacity

Progress bar: white / gray

Text Stories

Backgrounds: black or white only

Text auto-inverts for contrast

11. Icons

Style: Outlined

Stroke width: 1.5–2px

Color: Black / White only

Library: lucide or material symbols outlined

No filled icons except active states.

12. Motion & Animation
Durations
Type	Duration
Tap feedback	100ms
Screen transition	200ms
Story progress	linear
Modal open	250ms
Easing

ease-out for entrances

ease-in for exits

No bounce. No overshoot.

13. Accessibility Rules

Contrast ratio ≥ 4.5:1

Dynamic font scaling supported

Haptics for primary actions

Tap targets ≥ 44px

14. Dark Mode

Default mode = Dark

Light Mode	Dark Mode
White bg	Black bg
Black text	White text
Gray borders	Gray-700 borders

Exact inversion. No reinterpretation.

15. Design Debt Kill Switches

No custom colors per feature

No new fonts without system approval

No feature-specific UI hacks

If it needs color to explain → UX is broken