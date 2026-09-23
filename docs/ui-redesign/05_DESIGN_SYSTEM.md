# Design System

## Direction
Operational, calm, trustworthy and mobile-first.

The worker may use the app while moving or actively executing a mission. Priorities:
- fast status recognition
- one obvious primary action
- low cognitive load
- strong contrast
- large touch targets
- readable Arabic
- clear "action required" vs "waiting"
- discoverable support/SOS

## Existing brand anchors
Current ThemeData:
- Primary `#1E2A7B`
- Secondary `#6C63FF`
- Accent/container `#2EC4B6`
- Error `#D92341`
- Typeface `Cairo`

Retain deep-blue brand recognition while simplifying surrounding surfaces.

## Proposed tokens

### Brand
- primary.900 `#1E2A7B`
- primary.700 `#28399B`
- primary.100 `#E9ECF8`
- accent `#2EC4B6`
- secondary `#6C63FF`

### Neutral
- 0 `#FFFFFF`
- 50 `#F8FAFC`
- 100 `#F1F5F9`
- 200 `#E2E8F0`
- 500 `#64748B`
- 700 `#334155`
- 900 `#0F172A`

### Semantic
- success `#059669`
- warning `#D97706`
- danger `#D92341`
- info `#0284C7`

Do not communicate state by color alone.

## Typography
Font: Cairo

Suggested scale:
- Hero 28/36 bold
- Screen title 22/30 bold
- Section title 18/26 semibold
- Body 15/24 regular
- Body strong 15/24 semibold
- Label 13/20 medium
- Meta 12/18 regular

## Spacing
4pt base grid.
Tokens: 4, 8, 12, 16, 20, 24, 32, 40.
Screen horizontal padding: 20–24.
Card internal padding: usually 16.

## Radius
- small: 10
- standard: 14
- large: 20
- pill: 999

## Interaction
- minimum critical action height: 52
- use one dominant primary action
- destructive/emergency actions use explicit labels
- use loading and disabled states
- prefer borders/surface hierarchy over heavy shadows

## Cards
Standard anatomy:
- status/eyebrow
- title
- supporting metadata
- content
- optional trailing value/status
- optional action

Avoid excessive nested cards in Order Details.

## RTL
Design Arabic RTL first.
Use start/end rather than left/right.
Explicitly test booking references, prices, phone numbers and mixed Arabic/Latin content.
