<h1 align="center">HamZain Traders</h1>

<p align="center">
  A multi-brand e-commerce mobile application built with Flutter, powered by a PHP/MySQL REST API.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Backend-PHP-777BB4?logo=php&logoColor=white" alt="PHP" />
  <img src="https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql&logoColor=white" alt="MySQL" />
  <img src="https://img.shields.io/badge/Payment-Cash%20on%20Delivery-green" alt="Cash on Delivery" />
</p>

---

## Table of Contents

1. [Overview](#1-overview)
2. [Purpose and Target Users](#2-purpose-and-target-users)
3. [Key Features](#3-key-features)
4. [Application Flow](#4-application-flow)
5. [Screenshots](#5-screenshots)
6. [Technology Stack](#6-technology-stack)
7. [Project Architecture](#7-project-architecture)
8. [Backend and API Integration](#8-backend-and-api-integration)
9. [Authentication and Session Management](#9-authentication-and-session-management)
10. [Navigation Structure](#10-navigation-structure)
11. [Screen-by-Screen Breakdown](#11-screen-by-screen-breakdown)
12. [App Identity](#12-app-identity)
13. [Getting Started](#13-getting-started)
14. [Contributor](#14-contributor)

---

## 1. Overview

**HamZain Traders** is an **e-commerce mobile application** developed with Flutter for a multi-brand retail storefront covering **four product brands**. It provides a complete online shopping experience: customers can browse brands and products, view detailed product information, manage a shopping cart, save delivery addresses, place **Cash-on-Delivery** orders, and track their orders afterwards.

The app is mobile-first and uses a premium design language, with gradient and glass-style surfaces, animated backgrounds, shimmer loading states, and a floating bottom navigation bar. All of this is built with Flutter's own widgets rather than an external UI kit.

All data (products, brands, carts, addresses, orders, and user accounts) is served by a **PHP REST API** backed by a **MySQL** database. The Flutter app never connects to the database directly.

## 2. Purpose and Target Users

**Purpose:** HamZain Traders gives customers a single mobile storefront to discover and buy products from multiple brands. They can do this without visiting a physical store or switching between separate apps.

**Intended for:**

- **Customers**, who browse, order, and track purchases from their phone.
- **Developers, recruiters, and clients**, who can use this repository as a reference for a complete Flutter + PHP/MySQL e-commerce implementation.

## 3. Key Features

- **Splash and onboarding:** a branded splash screen and swipeable intro slides for first-time users.
- **Account system:** registration and login, with the session persisted on the device.
- **Brand-based browsing:** brands are loaded from the backend and shown as tappable cards on the Home screen.
- **Product catalog:** product listings filtered by brand, or an "All Products" view.
- **Product details:** swipeable image gallery, description, price, and Add to Cart.
- **Shopping cart:** increase or decrease quantity, remove items, and view a running subtotal.
- **Address management:** add, edit, delete, and select saved delivery addresses.
- **Checkout:** address selection, order summary, itemized subtotal, delivery charges, tax and total, and Cash on Delivery.
- **Order confirmation:** an order success screen with the order number and estimated delivery date.
- **Order tracking:** My Orders, Order History, Order Details, and a printable/shareable Receipt.
- **Profile and settings:** account details, saved addresses, payment methods, settings, and logout.
- **Support and information:** FAQ, Help & Support, Contact Support, About Us, and Privacy Policy.
- **Polished UX:** custom animated page transitions, shimmer loaders, pull-to-refresh, and per-tab navigation stacks.

## 4. Application Flow

### 4.1 User Journey

1. Open the app and see the **Splash Screen**. First-time users then see **Onboarding**.
2. **Register** a new account or **Log in** to an existing one. Returning users with a saved session skip this step.
3. Land on **Home**, which shows a personalized welcome and the list of **brands**.
4. Tap a brand to browse its **Products**, or open **All Products** from the bottom navigation bar to see everything.
5. Tap a product to open **Product Details**, where you can view the image gallery, description, and price, then **Add to Cart**.
6. Open **Cart** from the bottom navigation bar, adjust quantities or remove items, then proceed to **Checkout**.
7. On **Checkout**, select (or add) a **delivery address** and review the **order summary** (subtotal, delivery charges, tax, total). Confirm **Cash on Delivery** and tap **Place Order**.
8. See the **Order Success** screen with your order number and estimated delivery date.
9. Track the order at any time from **Profile → My Orders / Order History**, open full **Order Details**, or view the **Receipt**.
10. Manage **Saved Addresses**, **Payment Methods**, **Settings**, and **Support** from the **Profile** tab.

### 4.2 Flow Diagram

```text
Splash → (first run) Onboarding → Register / Login
                                        │
                                        ▼
                                  Home (Brands)
                                        │
                      ┌─────────────────┴──────────────────┐
                      ▼                                    ▼
             Brand Products                         All Products
                      └─────────────────┬──────────────────┘
                                        ▼
                                 Product Details
                                        │ Add to Cart
                                        ▼
                                      Cart
                                        │
                                        ▼
                                    Checkout
                          (Address · Summary · COD)
                                        │ Place Order
                                        ▼
                                  Order Success
                                        │
                                        ▼
                      My Orders → Order Details → Receipt
```

### 4.3 Technical Flow

1. A screen calls a method on its domain service (for example `CartService.getCart()`).
2. The service builds the request using the endpoint URLs defined in `api_constants.dart` and sends it with the `http` package.
3. The PHP endpoint reads or writes the MySQL database and returns JSON.
4. A shared, defensive decoder parses the response and surfaces the backend's own error message when `success` is `false`.
5. The data is mapped into a Dart model through its `fromJson` factory and rendered by the screen, typically through a `FutureBuilder`.

## 5. Screenshots

> Screenshots have not been added yet. Replace the placeholders below with images from a `docs/` or `screenshots/` folder.

| Home | Products | Product Details |
|:---:|:---:|:---:|
| _Add screenshot_ | _Add screenshot_ | _Add screenshot_ |

| Cart | Checkout | Order Success |
|:---:|:---:|:---:|
| _Add screenshot_ | _Add screenshot_ | _Add screenshot_ |

## 6. Technology Stack

| Layer | Technology |
|---|---|
| Frontend framework | Flutter (Dart, Material 3) |
| State handling | Stateful widgets and `FutureBuilder` (screen-local state, no external state-management package) |
| Networking | `http` package, JSON REST calls to a PHP backend |
| Local persistence | `shared_preferences` (session/login persistence) |
| Images | `cached_network_image` for remote product and brand images |
| Fonts | `google_fonts` |
| Backend | PHP endpoints over HTTPS |
| Database | MySQL (accessed only through the PHP API layer) |

**Key dependencies** (see `pubspec.yaml`): `http`, `cached_network_image`, `google_fonts`, `shared_preferences`.

## 7. Project Architecture

### Repository Structure

```text
HamZain Traders/
├── android/            # Android platform project
├── assets/
│   └── icon/           # App launcher icon assets
├── lib/                # Flutter application source (see below)
├── web/                # Web platform files (index.html, manifest, icons)
├── analysis_options.yaml
├── pubspec.yaml        # Dependencies and asset configuration
└── README.md
```

### Application Source (`lib/`)

```text
lib/
├── main.dart                     # App entry point, MaterialApp, AuthGate (session check)
├── core/
│   ├── constants/                # App-wide colors, text styles, durations, order-status constants
│   ├── navigation/               # Custom page transitions (PremiumPageRoute)
│   └── widgets/                  # Shared premium UI primitives (gradient backgrounds, buttons,
│                                 #   page indicators, orbiting/floating icon effects)
├── models/                       # Plain Dart data models mapped to backend tables
│   ├── user_model.dart           # users table
│   ├── brand.dart                # brands table
│   ├── product.dart              # products table
│   ├── product_image.dart        # product image gallery entries
│   ├── cart_model.dart           # cart + cart_items (joined)
│   ├── address_model.dart        # address table
│   ├── order_model.dart          # orders + order_items
│   └── payment_method_model.dart # saved payment methods (UI-level)
├── services/                     # All networking and business logic, no UI code
│   ├── api_constants.dart        # Every backend endpoint URL, in one place
│   ├── api_http_helper.dart      # Shared HTTP helpers
│   ├── api_service.dart          # Products and product images
│   ├── brand_service.dart        # Brands
│   ├── cart_service.dart         # Cart CRUD
│   ├── address_service.dart      # Address CRUD
│   ├── order_service.dart        # Place order, order history/details/receipt
│   └── session_service.dart      # Persists/reads the logged-in user via shared_preferences
├── screens/                      # One folder per feature area (see Section 11)
└── widgets/                      # Reusable widgets (app bar, bottom nav, brand card, auth fields,
                                  #   drawer, shimmer, banners)
```

**Design principles**

- **Separation of concerns:** each `*_service.dart` file is the only place that talks to the network for its domain. Screens call services and render the result. They never build URLs or parse raw JSON themselves.
- **Defensive parsing:** every model's `fromJson` factory tolerates `int`, `double`, and `String` mismatches coming from PHP/MySQL, so the UI does not crash on a slightly different response shape.
- **Centralized endpoints:** all URLs live in `api_constants.dart`.

## 8. Backend and API Integration

**Base URL:** `https://devtechnical.com/Abdullah.Shahid/HamZainTraders/`

All endpoints return a common JSON envelope, either `{ "success": bool, "data": [...] }` or a bare array. The services parse it through a shared decoder that also surfaces the backend's error message when `success` is `false`.

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

**Database connectivity:** the MySQL database is accessed exclusively through the PHP API layer. The Flutter models map to these tables:

| Table | Dart model |
|---|---|
| `users` | `user_model.dart` |
| `brands` | `brand.dart` |
| `products` | `product.dart` |
| `product_images` | `product_image.dart` |
| `address` | `address_model.dart` |
| `cart` / `cart_items` | `cart_model.dart` |
| `orders` / `order_items` | `order_model.dart` |

## 9. Authentication and Session Management

1. **Splash Screen** (`screens/splash/splash_screen.dart`) is a branded loading screen shown on cold start.
2. **`AuthGate`** (in `main.dart`) checks `SessionService`, which is backed by `shared_preferences`, for a saved logged-in user.
   - If a session exists, the user goes straight to **Home** (`MainShell`).
   - If not, the user lands on **Register / Sign Up**.
3. **Onboarding** (`screens/onboarding/onboarding_screen.dart`) shows swipeable intro slides to first-time users before authentication. The slides are data-driven from `onboarding/data/onboarding_data.dart`.
4. **Register** (`screens/auth/register_screen.dart`, `signup_screen.dart`) collects full name, email, phone number, and password, and posts to `insertsignup.php`.
5. **Login** (`screens/auth/login_screen.dart`) collects email and password and calls `getlogin.php`. On success, the returned user is saved through `SessionService` and the app navigates into `MainShell`.

A returning user is never asked to log in again unless they explicitly log out from **Profile → Settings**.

## 10. Navigation Structure

- `main.dart` → `AuthGate` decides between **Register/Login** and `MainShell`, based on the saved session.
- `MainShell` (`screens/main_shell.dart`) hosts four primary tabs behind a floating bottom navigation bar (`widgets/floating_bottom_nav.dart`):
  **Home · Products (All Products) · Cart · Profile**
- Each tab owns its **own nested Navigator**. Pushing a screen (Product Details, Checkout, Order Success, Receipt, Order Details, Address screens, and so on) inside one tab does not disturb the other tabs, and switching tabs preserves each tab's navigation stack through an `IndexedStack`.
- The bottom navigation bar **hides automatically** when a screen is pushed on top of a tab's root and reappears when the user returns. This gives Checkout, Receipt, and Product Details full-screen focus.
- Screen transitions use a custom `PremiumPageRoute` (`core/navigation/premium_page_route.dart`) for consistent animations across the app.

## 11. Screen-by-Screen Breakdown

### Home
`screens/home/home_screen.dart` is the first screen after authentication.
- Personalized welcome banner using the logged-in user's name.
- Brands are fetched from `BrandService` (`brands` table) and shown as tappable cards (`widgets/brand_card.dart`).
- Pull-to-refresh re-fetches the brands.
- Tapping a brand opens the Products flow filtered to that brand.

### Products
`screens/products_screen.dart` and `screens/products/all_products_screen.dart`
- Products are fetched from `getproducts.php` through `ApiService`.
- They are filtered client-side by `brandId` when the user arrives from a specific brand, or shown unfiltered as "All Products".
- Each tile shows the product's image, name, and price, and opens **Product Details** on tap.

### Product Details
`screens/product_detail_screen.dart`
- **Image gallery:** fetched from `getproductimages.php` and shown as a swipeable gallery.
- **Description and pricing:** taken from the `products` table.
- **Add to Cart:** calls `CartService` → `addtocart.php`, associating the product with the logged-in user's cart.

### Cart
`screens/cart/cart_screen.dart`
- Loads the cart through `CartService.getCart()` → `getcart.php`, showing each item's name, image, unit price, quantity, and line total.
- Quantity can be changed (`updatecartquantity.php`) or the item removed (`removecartitem.php`).
- Shows a running **subtotal** and a button to proceed to **Checkout**.

### Addresses
`screens/address/saved_address_screen.dart`
- Lists the user's saved addresses (`getaddresses.php`).
- **Add New Address** opens a form sheet (`_AddressFormSheet`) collecting full name, phone, email, address line, city, area, and notes, and posts to `addaddress.php`.
- Addresses can be edited (`updateaddress.php`) or deleted (`deleteaddress.php`).
- From Checkout, the user picks a saved address or adds a new one as the delivery address.

### Checkout
`screens/checkout/checkout_screen.dart`
- **Delivery address:** loads saved addresses through `AddressService` and lets the user pick one or add a new one.
- **Order summary:** lists every cart item with quantity and line total.
- **Totals:** itemized subtotal, delivery charges, tax, and final total amount.
- **Payment:** Cash on Delivery. `screens/payments/` contains supporting saved payment method entries for future or alternate payment options.
- **Place Order:** submits the selected address, cart items, and totals to `placeorder.php` through `OrderService`, then clears the cart (`clearcart.php`).

### Order Success
`screens/checkout/order_success_screen.dart`
- Shown right after a successful `placeorder.php` call.
- Confirms the order number and estimated delivery date, with shortcuts to **My Orders** or **Home**.

### Orders
`screens/orders/`
- **My Orders** (`my_orders_screen.dart`) shows current and recent orders (`getmyorders.php`).
- **Order History** (`order_history_screen.dart`) shows full past order history with each order's line items (`getorderhistory.php`).
- **Order Details** (`order_details_screen.dart`) shows a single order's items, address, subtotal, delivery charges, total, and status (`getorderdetails.php`).
- **Receipt** (`receipt_screen.dart`) is a printable/shareable receipt view (`getorderreceipt.php`).

### Profile, Settings, and Supporting Screens
- **My Profile** (`screens/profile/my_profile_screen.dart`) shows account details and is the entry point to Settings, Saved Addresses, Payment Methods, Orders, and Support.
- **Settings** (`screens/settings/settings_screen.dart`) holds app preferences and logout, which clears the `SessionService` session and returns the user to Register/Login.
- **Payments** (`screens/payments/`) lets users view and add saved payment methods.
- **Support** (`screens/support/`) contains FAQ, Help & Support, and Contact Support.
- **About Us** (`screens/about/about_us_screen.dart`) and **Privacy Policy** (`screens/legal/privacy_policy_screen.dart`).
- **App Drawer** (`widgets/app_drawer.dart`) is a side-navigation shortcut to the screens above.

## 12. App Identity

- **Application display name:** `HamZain Traders`, set in `MaterialApp.title` and the web manifest.
- **Launcher icon:** the custom HamZain Traders shopping-cart logo at `assets/icon/icon.png`.

## 13. Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (with Dart)
- An IDE such as Android Studio or VS Code with the Flutter plugin
- An Android emulator, physical Android device, or Chrome (for web)
- Internet access, since the app talks to the hosted PHP/MySQL backend

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/abdullah-shahid7/hamzain-traders.git
cd hamzain-traders

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

The app uses the hosted backend at the base URL listed in [Section 8](#8-backend-and-api-integration). To point it at a different server, update the endpoint definitions in `lib/services/api_constants.dart`.

### Running on Web

The web build's title, manifest name, and icons (`web/manifest.json`, `web/index.html`, `web/icons/`, `web/favicon.png`) are already included:

```bash
flutter run -d chrome
```

### Platform Support

| Platform | Status |
|---|---|
| Android | Included in the repository (`android/`) |
| Web | Included in the repository (`web/`) |
| iOS | The `ios/` folder is not included in this repository |

To add iOS support, run the following in the project root. It generates the missing `ios/` folder without touching the existing Dart code:

```bash
flutter create . --platforms=ios
```

### Regenerating the Launcher Icon

The `flutter_launcher_icons` dev-dependency and its configuration are set up in `pubspec.yaml`, pointing at `assets/icon/icon.png`. To regenerate the icons for all configured platforms:

```bash
flutter pub get
dart run flutter_launcher_icons
```

### Setting the App Label

- **Android:** set the label in `android/app/src/main/AndroidManifest.xml`:
```xml
  <application
      android:label="HamZain Traders"
      ...>
```
- **iOS** (after generating the `ios/` folder): set the display name in `ios/Runner/Info.plist`:
```xml
  <key>CFBundleDisplayName</key>
  <string>HamZain Traders</string>
  <key>CFBundleName</key>
  <string>HamZain Traders</string>
```

## 14. Contributor

| Name | Email |
|---|---|
| **Muhammad Abdullah Shahid** | [abdullah.shahid.tech1@gmail.com](mailto:abdullah.shahid.tech1@gmail.com) |