# WhaleWalk 🐋

WhaleWalk (formerly *Campus Exchange*) is a next-generation, full-stack application that gamifies health and finance by combining a **virtual stock market** with **real-world fitness tracking**. 

Users can walk to earn currency, trade virtual stocks on a dynamic market, participate in localized geofenced challenges, and place bets on campus events.

---

## 🌟 Core Features

- **Virtual Stock Market Engine**: A fully functional simulated stock exchange.
  - **Dynamic Price Simulation**: Market orders instantly affect stock prices using an algorithm based on supply/demand and float impact.
  - **Limit Order Matching**: A custom order matching engine (`orderMatcher.js`) pairs buyers and sellers. It features an escrow system that locks funds/stocks while an order is pending, and refunds differences upon execution.
- **Fitness Integration**: Connects with Android Health Connect & built-in pedometers to track steps, active minutes, and distance. Users convert their physical steps into *Campus Coins*.
- **Geofencing & Orb Farming**: Utilizes GPS tracking and custom map layers (`FlutterMap`) to create specific geographical "zones." Users who walk inside these zones farm special "Orbs."
- **Betting & Challenges**: Users can stake their coins on real-world or campus events, with an algorithm calculating proportional payouts for the winners.
- **Robust Transaction Logging**: Every single financial action (stock trades, store purchases, bet staking, challenge rewards) is strictly logged into a ledger for accurate portfolio tracking.

---

## 🛠️ Technology Stack

- **Frontend**: Flutter / Dart
  - **State Management**: Riverpod (for polling data and UI reactivity).
  - **Mapping**: `flutter_map` with `latlong2`.
- **Backend**: Node.js & Express.js
- **Database**: MongoDB (via Mongoose)

---

## 🗄️ Database Architecture: MongoDB

### Why MongoDB?
WhaleWalk utilizes **MongoDB**, a NoSQL document database, for several strategic reasons:
1. **Flexibility & Speed of Iteration**: In a rapidly evolving app with diverse features (Stocks, Bets, Fitness Stats, Store Items), NoSQL allows us to easily add or modify fields (like adding an `initialQuantity` to an order) without running painful, time-consuming schema migrations.
2. **JSON Native**: Since our backend is Node.js and our frontend uses Dart JSON serialization, data flows seamlessly from the database to the client without needing complex ORM translations.
3. **High Read Performance**: Using embedded documents for things like stock price history allows us to retrieve a stock and its chart data in a single query, which is crucial for a fast-polling application.

### Normalization vs. Denormalization (Normal Form)
Because MongoDB is a NoSQL database, it does not strictly adhere to the traditional Relational Database Normal Forms (like 3NF or BCNF). Instead, WhaleWalk uses a hybrid approach prioritizing **Denormalization** for speed, with selective normalization where necessary:

- **Denormalized for Speed**: For example, in the `Stock` model, the `previousPrice` and a bounded `history` array of recent prices are stored directly on the stock document. We do not use a separate `StockHistory` table joined by foreign keys. This ensures that fetching the market page requires only one fast database read.
- **Normalized for Integrity (Similar to 2NF)**: We separate core entities into their own collections (`User`, `Wallet`, `Stock`, `StockTrade`, `Transaction`). Instead of embedding every trade inside a user's document, `StockTrade` and `Transaction` documents use references (like `userId` or `username`). This prevents the user document from growing infinitely large and allows for independent, scalable querying of the order book.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Node.js & npm
- MongoDB URI (Local or Atlas)

### Backend Setup
1. Navigate to the `Backend` directory.
2. Run `npm install` to install dependencies.
3. Create a `.env` file and add your MongoDB connection string (`MONGODB_URI`) and API Port (`PORT`).
4. Run `npm run dev` to start the backend server.

### Frontend Setup
1. Ensure the backend URL in `lib/core/services/api_service.dart` points to your active server (e.g., `http://localhost:8000/api/v1` for local testing).
2. Run `flutter pub get`.
3. Build and run the app via `flutter run`.
