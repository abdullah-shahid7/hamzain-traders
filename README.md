# Hum Zen Traders

A premium, production-oriented Flutter e-commerce application built for **Hum Zen Traders** — a multi-brand retail storefront covering four product brands. The app provides a full shopping experience: browse brands and products, manage a cart, save delivery addresses, check out, and track orders, all backed by a PHP/MySQL REST API.

## Contributor

- **Contributor:** Muhammad Abdullah Shahid
- **Email:** abdullah.shahid.tech1@gmail.com

## 1. Project Overview

Hum Zen Traders is a mobile-first shopping app that lets a customer:

1. Discover the storefront's brands and browse each brand's products.
2. View rich product details (image gallery, description, price) and add items to a cart.
3. Manage delivery addresses and place Cash-on-Delivery orders.
4. Track past and current orders, view receipts, and manage account/profile settings.

The UI follows a "premium" design language — gradient/glass surfaces, animated backgrounds, shimmer loading states, and a floating bottom navigation bar — built entirely with Flutter widgets (no external UI kit).

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Frontend framework | Flutter (Dart, Material 3) |
| State handling | Stateful widgets + `FutureBuilder` (screen-local state, no external state-management package) |
| Networking | `http` package, JSON REST calls to a PHP backend |
| Local persistence | `shared_preferences` (session/login persistence) |
| Images | `cached_network_image` for remote product/brand images |
| Fonts | `google_fonts` |
| Backend | PHP endpoints over HTTPS |
| Database | MySQL (accessed only through the PHP API layer) |

Key dependencies (see `pubspec.yaml`): `http`, `cached_network_image`, `google_fonts`, `shared_preferences`.

## 3. Flutter Frontend Architecture

```
lib/
├── main.dart                     # App entry point, MaterialApp, AuthGate (session check)
├── core/
│   ├── constants/                # App-wide colors, text styles, durations, order-status constants
│   ├── navigation/                # Custom page transitions (PremiumPageRoute)
│   └── widgets/                   # Shared premium UI primitives (gradient backgrounds, buttons, page indicators, orbiting/floating icon effects)
├── models/                       # Plain Dart data models mapped 1:1 to backend tables
│   ├── user_model.dart            # users table
│   ├── brand.dart                 # brands table
│   ├── product.dart               # products table
│   ├── product_image.dart         # product image gallery entries
│   ├── cart_model.dart            # cart + cart_items (joined)
│   ├── address_model.dart         # address table
│   ├── order_model.dart           # orders + order_items
│   └── payment_method_model.dart  # saved payment methods (UI-level)
├── services/                     # All networking + business logic, no UI code
│   ├── api_constants.dart         # Every backend endpoint URL, in one place
│   ├── api_http_helper.dart       # Shared HTTP helpers
│   ├── api_service.dart           # Products + product images
│   ├── brand_service.dart         # Brands
│   ├── cart_service.dart          # Cart CRUD
│   ├── address_service.dart       # Address CRUD
│   ├── order_service.dart         # Place order, order history/details/receipt
│   └── session_service.dart       # Persists/reads the logged-in user via shared_preferences
├── screens/                      # One folder per feature area (see Section 4 for the full flow)
└── widgets/                      # Reusable widgets shared across screens (app bar, bottom nav, brand card, auth fields, drawer, shimmer, banners)
```

Each `*_service.dart` file is the **only** place that talks to the network for its domain; screens call services and render the result — they never build URLs or parse raw JSON themselves. Every model's `fromJson` factory parses fields defensively (tolerating `int`/`double`/`String` mismatches from PHP/MySQL), so the UI never crashes on a slightly different response shape from the backend.

## 4. Backend / API Integration

**Base URL:** `https://devtechnical.com/Abdullah.Shahid/HamZainTraders/`

All endpoints return a common JSON envelope: `{ "success": bool, "data": [...] }` (or a bare array), which the services parse through a shared, defensive decoder that also surfaces the backend's own error message when `success` is `false`.

| Feature | Endpoint | Used by |
|---|---|---|
| Sign up | `insertsignup.php` | Register screen |
| Login | `getlogin.php` | Login screen |
| Products | `getproducts.php` | Home / Products / Product Details |
| Product images | `getproductimages.php` | Product image gallery |
| Add address | `addaddress.php` | Add New Address form |
| List addresses | `getaddresses.php` | Saved Addresses / Checkout |
| Update address | `updateaddress.php` | Edit address |
| Delete address | `deleteaddress.php` | Saved Addresses |
| Add to cart | `addtocart.php` | Product Details |
| Get cart | `getcart.php` | Cart / Checkout |
| Update cart quantity | `updatecartquantity.php` | Cart |
| Remove cart item | `removecartitem.php` | Cart |
| Clear cart | `clearcart.php` | After order placement |
| Place order | `placeorder.php` | Checkout |
| My orders | `getmyorders.php` | My Orders |
| Order history | `getorderhistory.php` | Order History |
| Order details | `getorderdetails.php` | Order Details |
| Order receipt | `getorderreceipt.php` | Receipt screen |

Database tables referenced by the models: `users`, `brands`, `products`, `product_images`, `address`, `cart` / `cart_items`, `orders` / `order_items`.

## 5. Authentication Flow

1. **Splash Screen** (`screens/splash/splash_screen.dart`) — branded loading screen shown on cold start.
2. **`AuthGate`** (in `main.dart`) checks `SessionService` (backed by `shared_preferences`) for a saved logged-in user.
   - If a session exists → the user is taken straight to **Home** (`MainShell`), skipping login.
   - If not → the user lands on **Register/Sign Up**.
3. **Onboarding Screen** (`screens/onboarding/onboarding_screen.dart`) — swipeable intro slides (data-driven from `onboarding/data/onboarding_data.dart`) introducing the app before authentication, shown to first-time users.
4. **Register / Sign Up flow** (`screens/auth/register_screen.dart`, `signup_screen.dart`) — collects full name, email, phone number, and password, and posts to `insertsignup.php`.
5. **Login flow** (`screens/auth/login_screen.dart`) — collects email + password, calls `getlogin.php`, and on success saves the returned user via `SessionService` and navigates into `MainShell`.

Session persistence means a returning user is never asked to log in again unless they explicitly log out (from **Profile → Settings**).

## 6. Home Screen

`screens/home/home_screen.dart` is the first screen after authentication and shows:

- A welcome banner personalized with the logged-in user's name.
- **Brand selection**: brands are fetched from `BrandService` (`brands` table) and shown as tappable brand cards (`widgets/brand_card.dart`).
- A pull-to-refresh flow that re-fetches brands.

Tapping a brand navigates into the **Products** flow filtered to that brand.

## 7. Products Screen & Brand Filtering

- `screens/products_screen.dart` / `screens/products/all_products_screen.dart` display the product grid/list.
- Products are fetched from `getproducts.php` via `ApiService` and filtered client-side by `brandId` when the user arrives from a specific brand on Home, or shown unfiltered as "All Products".
- Each product tile shows its image, name, and price, and navigates to **Product Details** on tap.

## 8. Product Details Screen

`screens/product_detail_screen.dart`:

- **Image gallery** — fetched from `getproductimages.php` via `ApiService`, displayed as a swipeable gallery for that product.
- **Description and pricing** — the product's full description and price from `products`.
- **Add to Cart** — calls `CartService` → `addtocart.php`, associating the product with the logged-in user's cart.

## 9. Cart Screen

`screens/cart/cart_screen.dart`:

- Loads the current cart via `CartService.getCart()` → `getcart.php`, showing each item's product snapshot (name, image, unit price), quantity, and per-item total.
- Quantity can be incremented/decremented (`updatecartquantity.php`) or an item removed entirely (`removecartitem.php`).
- Shows a running **subtotal** and a button to proceed to **Checkout**.

## 10. Address Selection / Add New Address

`screens/address/saved_address_screen.dart`:

- Lists all saved addresses for the user (`getaddresses.php`).
- **Add New Address** is presented as a form sheet (`_AddressFormSheet`) collecting full name, phone, email, address line, city, area, and notes, and posts to `addaddress.php`.
- Addresses can be edited (`updateaddress.php`) or deleted (`deleteaddress.php`).
- From **Checkout**, the user picks one saved address (or adds a new one) as the delivery address for that order.

## 11. Checkout Screen

`screens/checkout/checkout_screen.dart`:

- **Delivery address selection** — pulls the user's saved addresses via `AddressService` and lets them pick one (or jump into Add New Address).
- **Order summary** — lists every cart item with quantity and line total.
- **Subtotal, delivery charges, tax, and total amount** — computed from the cart's subtotal plus delivery charges, presented as itemized summary lines before the final total.
- **Payment selection** — Cash on Delivery (with `screens/payments/` supporting saved payment method entries for future/alternate payment options).
- **Place Order** — submits the order (selected address + cart items + totals) to `placeorder.php` via `OrderService`, then clears the cart (`clearcart.php`).

## 12. Order Confirmation / Success Flow

`screens/checkout/order_success_screen.dart`:

- Shown immediately after a successful `placeorder.php` call.
- Confirms the order number and estimated delivery date, with a way to jump to **My Orders** or back to **Home**.

## 13. Orders

`screens/orders/`:

- **My Orders** (`my_orders_screen.dart`) — the user's current/recent orders (`getmyorders.php`).
- **Order History** (`order_history_screen.dart`) — full past order history (`getorderhistory.php`), including each order's line items.
- **Order Details** (`order_details_screen.dart`) — a single order's full breakdown (`getorderdetails.php`): items, address used, subtotal/delivery/total, and status.
- **Receipt** (`receipt_screen.dart`) — a printable/shareable receipt view (`getorderreceipt.php`).

## 14. Profile, Settings & Supporting Screens

- **My Profile** (`screens/profile/my_profile_screen.dart`) — account details, entry point to Settings, Saved Addresses, Payment Methods, Orders, and Support.
- **Settings** (`screens/settings/settings_screen.dart`) — app preferences and logout (clears the `SessionService` session, returning the user to Register/Login).
- **Payments** (`screens/payments/`) — view/add saved payment methods.
- **Support** (`screens/support/`) — FAQ, Help & Support, Contact Support.
- **About Us** (`screens/about/about_us_screen.dart`) and **Privacy Policy** (`screens/legal/privacy_policy_screen.dart`).
- **App Drawer** (`widgets/app_drawer.dart`) — side navigation shortcut to the above.

## 15. Navigation Structure

- `main.dart` → `AuthGate` decides between **Register/Login** and `MainShell` based on saved session.
- `MainShell` (`screens/main_shell.dart`) hosts four primary tabs — **Home, Products (All Products), Cart, Profile** — behind a floating bottom navigation bar (`widgets/floating_bottom_nav.dart`).
- Each tab owns its **own nested Navigator**, so pushing a screen (Product Details, Checkout, Order Success, Receipt, Order Details, Add/Select Address, etc.) inside one tab does not disturb the other tabs' state, and switching tabs preserves each tab's navigation stack (`IndexedStack`).
- The floating bottom nav automatically hides whenever a screen is pushed on top of a tab's root, and reappears when the user returns to that root — standard e-commerce app behavior, so Checkout/Receipt/Product Details etc. get full-screen focus.
- Screen-to-screen transitions use a custom `PremiumPageRoute` (`core/navigation/premium_page_route.dart`) for consistent animated transitions app-wide.

## 16. How the App Works, End to End (User Perspective)

1. Open the app → **Splash Screen** → (first run) **Onboarding**.
2. **Register** a new account or **Log in** with an existing one.
3. Land on **Home**, see a personalized welcome and the list of **brands**.
4. Tap a brand → browse that brand's **Products** (or open **All Products** from the bottom nav for everything).
5. Tap a product → view its **image gallery**, description, and price on **Product Details** → **Add to Cart**.
6. Open **Cart** from the bottom nav → adjust quantities or remove items → **Checkout**.
7. On **Checkout**, pick (or add) a **delivery address**, review the **order summary** (subtotal, delivery charges, tax, total), confirm **Cash on Delivery**, and **Place Order**.
8. See the **Order Success** confirmation with the order number and estimated delivery date.
9. Track the order any time from **Profile → My Orders / Order History**, view full **Order Details**, or pull up the **Receipt**.
10. Manage **Saved Addresses**, **Payment Methods**, app **Settings**, and get help via **Support/FAQ** from the **Profile** tab.

## 17. App Identity

- **Application display name:** `Hum Zen Traders` (set in `MaterialApp.title`, the web manifest, and — once the native platform folders are generated, see below — the Android app label and iOS display name).
- **Launcher icon:** the custom Hum Zen Traders shopping-cart logo (`assets/icon/icon.png`), replacing the default Flutter icon everywhere it is configured.

### Generating the native (Android/iOS) launcher icon and app label

This project, as shared, contains only `lib/`, `web/`, and the Flutter config files — it does **not** include the native `android/` and `ios/` platform folders (they were not part of the provided ZIP). To finish applying the icon and label on a real device build:

1. Run `flutter create .` in the project root. This safely regenerates the missing `android/` and `ios/` folders without touching any existing Dart code.
2. Run `flutter pub get` followed by `dart run flutter_launcher_icons` (the `flutter_launcher_icons` dev-dependency and its config are already set up in `pubspec.yaml`, pointing at `assets/icon/icon.png`). This generates every required mipmap/asset-catalog size for both platforms and removes the default Flutter icon.
3. Set the Android label to `Hum Zen Traders` in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application
       android:label="Hum Zen Traders"
       ...>
   ```
4. Set the iOS display name to `Hum Zen Traders` in `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleDisplayName</key>
   <string>Hum Zen Traders</string>
   <key>CFBundleName</key>
   <string>Hum Zen Traders</string>
   ```

The **web** build's title, manifest name, and icons (`web/manifest.json`, `web/index.html`, `web/icons/`, `web/favicon.png`) are already fully configured with the exact name and the provided icon — no extra step is needed for web.

## 18. Notes

- No existing application functionality was changed — this pass only added documentation, the exact display name, and launcher-icon configuration/assets.
- Backend endpoint list and table/column names above are taken directly from the current `services/` and `models/` source, not assumed.
