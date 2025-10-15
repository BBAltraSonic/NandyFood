# App Store Preparation Guide
**NandyFood - Google Play & Apple App Store**  
**Version:** 1.0  
**Date:** January 15, 2025

---

## App Store Optimization Checklist

### Google Play Store

#### 1. App Listing Assets

**App Icon**
- Size: 512 x 512 pixels
- Format: 32-bit PNG with alpha
- No rounded corners (Google adds them)
- High contrast, recognizable at small sizes

**Feature Graphic**
- Size: 1024 x 500 pixels
- Used in Play Store promotions
- Highlight key features visually

**Screenshots** (Required: minimum 2)
- Phone: 16:9 or 9:16 ratio
- 7-inch tablet: 16:9 or 9:16 ratio  
- 10-inch tablet: 16:9 or 9:16 ratio
- Recommended: 1080 x 1920 pixels (portrait)

**Promotional Video** (Optional)
- YouTube link
- 30-120 seconds recommended
- Show app in action

#### 2. Store Listing Content

**App Title**
- Maximum: 50 characters
- Suggested: "NandyFood - Food Delivery"

**Short Description**
- Maximum: 80 characters
- "Order delicious food from local restaurants. Fast delivery guaranteed!"

**Full Description**
- Maximum: 4000 characters
- See template below

**App Category**
- Primary: Food & Drink
- Secondary: Shopping (optional)

**Content Rating**
- PEGI 3 / Everyone
- No objectionable content

**Contact Details**
- Website: https://nandyfood.com
- Email: support@nandyfood.com
- Phone: +27 [NUMBER]
- Privacy Policy URL: https://nandyfood.com/privacy

---

### Apple App Store

#### 1. App Listing Assets

**App Icon**
- Size: 1024 x 1024 pixels
- No alpha channel
- No rounded corners (iOS adds them)

**Screenshots**
- iPhone 6.7": 1290 x 2796 pixels (portrait)
- iPhone 6.5": 1284 x 2778 pixels
- iPhone 5.5": 1242 x 2208 pixels
- iPad Pro 12.9": 2048 x 2732 pixels

**App Preview Videos** (Optional)
- 15-30 seconds recommended
- Different sizes for different devices

#### 2. Store Listing Content

**App Name**
- Maximum: 30 characters
- "NandyFood"

**Subtitle**
- Maximum: 30 characters
- "Fast Food Delivery"

**Promotional Text**
- Maximum: 170 characters
- Editable without app update
- "Get your favorite meals delivered fast! New users get 20% off first order."

**Description**
- Maximum: 4000 characters
- See template below

**Keywords**
- Maximum: 100 characters (comma-separated)
- "food,delivery,restaurant,order,pizza,burger,fast,meals,takeaway"

**Category**
- Primary: Food & Drink
- Secondary: Shopping (optional)

**Age Rating**
- 4+ (no objectionable content)

**Support URL**
- https://nandyfood.com/support

**Privacy Policy URL**
- https://nandyfood.com/privacy

---

## App Description Template

### Full Description (Both Stores)

```
🍕 NandyFood - Your Favorite Food, Delivered Fast!

Craving delicious food? NandyFood connects you with the best local restaurants and delivers your favorite meals right to your door.

✨ WHY CHOOSE NANDYFOOD?

🚀 Fast Delivery
Get your food delivered in 30 minutes or less! Track your order in real-time and know exactly when it will arrive.

🍔 Wide Selection
Discover hundreds of restaurants offering cuisine from around the world - pizza, burgers, sushi, Indian, Chinese, and more!

💳 Easy Payment
Multiple payment options including credit/debit cards, digital wallets, and cash on delivery.

⭐ Exclusive Deals
Save money with daily deals, first-order discounts, and loyalty rewards!

📍 Real-Time Tracking
Track your delivery driver in real-time on the map. Get notifications at every step.

🌟 FEATURES

• Browse restaurants by cuisine, rating, or delivery time
• Advanced filters for dietary restrictions (vegan, halal, gluten-free)
• Save favorite restaurants and orders for quick reordering
• Schedule orders for later
• Rate and review restaurants
• Customer support via chat, email, or phone
• Secure payment processing
• Order history and receipts

🎁 NEW USER OFFER
Get 20% off your first order! Use code: WELCOME20

📱 HOW IT WORKS

1. Browse restaurants and menus
2. Add items to your cart
3. Enter delivery address
4. Choose payment method
5. Place order and track delivery
6. Enjoy your meal!

🏆 TRUSTED BY THOUSANDS
Join thousands of happy customers who order with NandyFood every day!

💬 NEED HELP?
Our customer support team is available 24/7 to assist you.
Email: support@nandyfood.com
Phone: +27 [NUMBER]

📢 FOLLOW US
Instagram: @nandyfood
Facebook: /nandyfood
Twitter: @nandyfood

Download NandyFood today and get your favorite meals delivered!

---

Legal: By using NandyFood, you agree to our Terms of Service and Privacy Policy.
```

---

## Bundle Size Optimization

### Current Size Analysis
**Target:** < 50MB for initial download

### Optimization Steps

1. **Image Optimization**
   - Compress all images
   - Use WebP format where supported
   - Remove unused images
   - Use vector graphics (SVG) when possible

2. **Code Optimization**
   - Remove unused packages
   - Enable code shrinking (ProGuard/R8)
   - Enable resource shrinking
   - Split APKs by ABI

3. **Asset Optimization**
   - Compress animations (Lottie)
   - Remove unused fonts
   - Minimize audio files
   - Use app bundles (AAB) instead of APK

4. **Build Configuration**
   ```gradle
   android {
       buildTypes {
           release {
               minifyEnabled true
               shrinkResources true
               proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
           }
       }
   }
   ```

**Expected Result:** 30-40MB download size

---

## Screenshot Planning

### Key Screens to Showcase

1. **Home Screen**
   - Restaurant discovery
   - Search functionality
   - Featured promotions

2. **Restaurant Details**
   - Menu browsing
   - Ratings and reviews
   - Order customization

3. **Cart & Checkout**
   - Easy checkout process
   - Multiple payment options
   - Delivery time selection

4. **Order Tracking**
   - Real-time map tracking
   - Order status updates
   - Driver information

5. **Profile & Rewards**
   - Order history
   - Loyalty program
   - Special offers

### Screenshot Specifications

**Design Guidelines:**
- Use real app screenshots (not mockups)
- Show actual content (not lorem ipsum)
- Highlight key features with overlays
- Use device frames
- Maintain consistent branding
- Add captions/text overlays

**Tools:**
- Figma for design
- Screenshots.pro for device frames
- Canva for text overlays

---

## App Store Keywords

### Google Play (Search Optimization)

**Primary Keywords:**
- food delivery
- restaurant delivery
- order food online
- takeaway
- food ordering app

**Long-Tail Keywords:**
- fast food delivery near me
- order pizza online
- restaurant delivery app
- food delivery south africa
- best food delivery app

### Apple App Store

**Keyword String (100 chars max):**
```
food,delivery,restaurant,order,pizza,burger,takeaway,fast,meals,online
```

**Optimization:**
- Research competitor keywords
- Use App Store Connect analytics
- Update monthly based on performance
- Avoid brand names (not allowed)

---

## Pre-Launch Checklist

### Technical Requirements

- [ ] App builds successfully
- [ ] All features tested on real devices
- [ ] No crash bugs in production build
- [ ] Analytics integrated and working
- [ ] Crash reporting configured
- [ ] Performance optimized
- [ ] Deep linking configured
- [ ] Push notifications working
- [ ] Payment processing tested
- [ ] Security audit completed

### Legal Requirements

- [ ] Privacy Policy published
- [ ] Terms of Service published
- [ ] Content rating questionnaire completed
- [ ] Export compliance declaration (if applicable)
- [ ] All licenses and attributions included
- [ ] GDPR/POPIA compliance verified

### Marketing Assets

- [ ] App icon finalized
- [ ] Screenshots captured
- [ ] Feature graphic created (Google)
- [ ] Promotional video created (optional)
- [ ] App description written
- [ ] Keywords researched
- [ ] Press kit prepared
- [ ] Social media assets ready

### Store Listings

- [ ] Google Play Console account created
- [ ] Apple Developer account created
- [ ] App created in both consoles
- [ ] All metadata uploaded
- [ ] Screenshots uploaded
- [ ] Pricing and distribution set
- [ ] Age rating completed
- [ ] Contact information added

---

## Launch Strategy

### Soft Launch (Recommended)

1. **Beta Testing**
   - Google Play: Open beta or closed beta
   - Apple: TestFlight
   - Target: 100-500 beta testers
   - Duration: 2-4 weeks

2. **Limited Geographic Release**
   - Start with 1-2 cities
   - Monitor performance
   - Fix issues quickly
   - Gather user feedback

3. **Gradual Rollout**
   - Week 1: 10% of users
   - Week 2: 25% of users
   - Week 3: 50% of users
   - Week 4: 100% of users

### Full Launch

- Simultaneous release on both platforms
- Press release
- Social media campaign
- Influencer partnerships
- Paid advertising
- Email marketing to wait list

---

## Post-Launch

### Monitor Metrics

- Downloads and installations
- Active users (DAU/MAU)
- Retention rate
- App store ratings
- Reviews and feedback
- Crash rate
- Performance metrics

### Ongoing Optimization

- Respond to reviews
- Update screenshots for new features
- Refresh description monthly
- A/B test app icon and screenshots
- Monitor keyword rankings
- Update based on user feedback

---

## App Store Review Guidelines

### Google Play

**Review Time:** 1-7 days (usually 1-2 days)

**Common Rejection Reasons:**
- Misleading metadata
- Inappropriate content
- Broken functionality
- Privacy policy missing
- Permissions not justified

### Apple App Store

**Review Time:** 1-3 days (usually 24-48 hours)

**Common Rejection Reasons:**
- App crashes or bugs
- Incomplete app information
- Privacy policy issues
- Guideline violations
- Performance issues

---

**Document Owner:** Product Marketing Manager  
**Next Review:** Before each major release
