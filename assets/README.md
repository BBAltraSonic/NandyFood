# Assets Directory

This directory contains all static assets for the NandyFood app.

## 📁 Directory Structure

```
assets/
├── images/
│   ├── placeholders/
│   │   ├── restaurant_placeholder.png
│   │   ├── food_placeholder.png
│   │   └── user_avatar_placeholder.png
│   └── branding/
│       ├── logo.png
│       ├── logo_white.png
│       └── splash_logo.png
├── icons/
│   ├── app_icon.png (1024x1024)
│   └── notification_icon.png
└── fonts/
    └── Poppins/ (if using custom fonts)
```

## 🖼️ Image Guidelines

### Restaurant Images
- **Resolution**: 1200x800px minimum
- **Format**: JPEG or WebP for photos, PNG for graphics
- **Size**: Keep under 500KB (use compression)
- **Aspect Ratio**: 3:2 recommended

### Menu Item Images
- **Resolution**: 800x600px minimum
- **Format**: JPEG or WebP
- **Size**: Keep under 300KB
- **Aspect Ratio**: 4:3 recommended
- **Style**: Clean, well-lit food photography

### User Avatars
- **Resolution**: 200x200px minimum
- **Format**: PNG or JPEG
- **Size**: Keep under 100KB
- **Shape**: Square (will be clipped to circle in UI)

### App Icons
- **Android**: Generate using Android Asset Studio
  - Sizes: 48dp to 512dp
  - Place in `android/app/src/main/res/mipmap-*/`
- **iOS**: Use Xcode Asset Catalog
  - Sizes: 20pt to 1024pt
  - Place in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## 📝 Placeholder Images

For development, you can use these free placeholder services:

1. **Food Images**: https://foodish-api.herokuapp.com/
2. **Restaurant Images**: https://picsum.photos/
3. **User Avatars**: https://ui-avatars.com/

Example URLs:
- Food: `https://source.unsplash.com/800x600/?food`
- Restaurant: `https://source.unsplash.com/1200x800/?restaurant`
- Avatar: `https://ui-avatars.com/api/?name=John+Doe&size=200`

## 🎨 Generating Placeholders

Use these tools to create placeholder images:

```dart
// In Flutter code
NetworkImage('https://source.unsplash.com/800x600/?food,${item.name}')

// Or use CachedNetworkImage
CachedNetworkImage(
  imageUrl: 'https://source.unsplash.com/800x600/?food',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

## 🔧 Image Optimization

Before adding images to assets:

1. **Compress images**: Use TinyPNG or ImageOptim
2. **Generate WebP versions**: Better compression, supported by Flutter
3. **Create multiple resolutions**: 1x, 2x, 3x for different densities

```bash
# Convert to WebP
cwebp input.png -q 80 -o output.webp

# Resize image
ffmpeg -i input.png -vf scale=800:-1 output.png
```

## 📦 Adding Assets to pubspec.yaml

Ensure assets are declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/placeholders/
    - assets/icons/
    - assets/branding/
```

## 🚀 Usage in Code

```dart
// Loading local asset
Image.asset('assets/images/placeholders/restaurant_placeholder.png')

// With size constraints
Image.asset(
  'assets/images/logo.png',
  width: 200,
  height: 100,
  fit: BoxFit.contain,
)

// SVG assets (if using flutter_svg)
SvgPicture.asset('assets/icons/icon.svg')
```

## 📋 TODO: Required Assets

### High Priority
- [ ] App icon (iOS and Android)
- [ ] Splash screen logo
- [ ] Restaurant placeholder
- [ ] Food placeholder
- [ ] User avatar placeholder

### Medium Priority
- [ ] Empty state illustrations
- [ ] Error state illustrations
- [ ] Success icons/animations
- [ ] Category icons (appetizers, main course, etc.)

### Low Priority
- [ ] Onboarding illustrations
- [ ] Feature banners
- [ ] Promotion badges

## 📄 License

Ensure all images used have appropriate licenses:
- Use royalty-free images from Unsplash, Pexels, or Pixabay
- Create custom icons using Figma or Adobe Illustrator
- Always attribute when required by license

---

**Note**: Current assets are placeholders. Replace with production assets before release.
