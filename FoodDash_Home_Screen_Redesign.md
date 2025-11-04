
#Home Screen — Redesign Plan (Functional Merge)

## 🎯 Core Goal
Maintain current functionality while upgrading layout & visuals to integrate:
- A **60% parallax map section**
- A **dish recommendation zone**
- **Same logical flow** (search, offers, categories, restaurants)
- Updated **pickup-focused UX**

---

## 🧱 New Layout Structure

### 1. Top Section (Parallax Map — 60%)
- Map visible at the top portion of the home screen.
- Overlays your location (e.g., *New York, NY* → *Mfuleni Pickup Zone*).
- The user avatar, location label, and filter icons remain — but float over the map.
- Map has parallax movement as you scroll down.
- Optional small “Pickup Spot” markers with dish/restaurant icons.

**Functionality kept:** location + navigation  
**New addition:** interactive map, pickup visualization

---

### 2. Mid Section (Dish Carousel — overlay start)
- As user scrolls, cards slide up over the map with **rounded corners**.
- Displays **Recommended** or **Favorite Dishes**.
- Card content:
  - Dish image
  - Dish name
  - Restaurant name
  - Price + distance
  - Pickup button

**Functionality kept:** “Popular Restaurants” section → evolved into “Recommended for Pickup”

---

### 3. Main Body (Search, Offers, Categories)
Below the dish cards, you retain your existing content blocks:
- 🔍 **Search Bar** — unchanged, just visually restyled to match the new tone.
- 🎁 **Special Offer** card — kept, placed just below dish carousel.
- 🍕 **Categories** — same horizontal scroll with icons.
- 🍔 **Popular Restaurants** — same cards or mini-carousel, rebranded as “Nearby Pickup Spots”.

**Functionality kept:** fully intact  
**Layout update:** visual continuity from map → dish cards → offers → categories.

---

### 4. Bottom Navigation Bar
- Keep your current 4-tab setup (Home, Favourites, Delivery, Profile).
- Replace **“Delivery”** with **“Pickup Orders”** to reflect the app’s new focus.
- Floating, translucent bar to align with the elevated look.

---

## 🪄 Interactions

| Interaction | Behavior |
|--------------|-----------|
| Scroll Up | Map moves up slowly (parallax); dish cards slide in. |
| Scroll Down | Map slides back down; header reappears. |
| Tap Dish | Map zooms to restaurant. |
| Tap Category | Filters visible dishes/restaurants by type. |
| Tap Offer | Redirects to promo page. |

---

## 🧠 Design Flow Summary
1. Open app → see map + pickup pins.  
2. Scroll → discover favorite dishes overlayed on map.  
3. Continue → see offers, search, and categories (same as before).  
4. Finish → browse restaurants & interact with pickup orders.
