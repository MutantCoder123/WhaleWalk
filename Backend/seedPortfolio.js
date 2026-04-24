import mongoose from "mongoose";
import { Stock } from "./models/stock.model.js";
import { UserStocks } from "./models/userstocks.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

// ── Campus-themed stocks ──────────────────────────────────────────────
const stocks = [
    { stockId: "MESS", name: "Mess Food Index",      price: 120, previousPrice: 115, sharesct: 500, history: [100, 105, 110, 115, 120] },
    { stockId: "WIFI", name: "Campus WiFi Corp",     price: 45,  previousPrice: 50,  sharesct: 500, history: [60, 55, 50, 48, 45] },
    { stockId: "LIB",  name: "Library Holdings",     price: 200, previousPrice: 185, sharesct: 500, history: [150, 165, 175, 185, 200] },
    { stockId: "FEST", name: "Fest Entertainment",   price: 310, previousPrice: 290, sharesct: 500, history: [250, 270, 280, 290, 310] },
    { stockId: "CGPA", name: "Academic Futures",     price: 88,  previousPrice: 92,  sharesct: 500, history: [95, 93, 90, 92, 88] },
    { stockId: "PLMT", name: "Placement Premium",    price: 450, previousPrice: 420, sharesct: 500, history: [380, 400, 410, 420, 450] },
    { stockId: "HOST", name: "Hostel Realty Trust",   price: 75,  previousPrice: 70,  sharesct: 500, history: [60, 65, 68, 70, 75] },
    { stockId: "CRIC", name: "Cricket League Token", price: 160, previousPrice: 155, sharesct: 500, history: [140, 145, 150, 155, 160] },
];

// ── Portfolio holdings for dummy users ────────────────────────────────
const holdings = [
    // traderknight — big diversified portfolio
    { username: "traderknight", stockId: "PLMT", quantity: 30, avgPrice: 400 },
    { username: "traderknight", stockId: "FEST", quantity: 20, avgPrice: 280 },
    { username: "traderknight", stockId: "LIB",  quantity: 15, avgPrice: 170 },

    // coinqueen — tech-heavy
    { username: "coinqueen", stockId: "PLMT", quantity: 25, avgPrice: 410 },
    { username: "coinqueen", stockId: "CRIC", quantity: 30, avgPrice: 145 },

    // wallstreetbro — balanced
    { username: "wallstreetbro", stockId: "FEST", quantity: 25, avgPrice: 270 },
    { username: "wallstreetbro", stockId: "HOST", quantity: 40, avgPrice: 65  },
    { username: "wallstreetbro", stockId: "MESS", quantity: 20, avgPrice: 110 },

    // cryptowiz — big on academics
    { username: "cryptowiz", stockId: "CGPA", quantity: 50, avgPrice: 90 },
    { username: "cryptowiz", stockId: "LIB",  quantity: 20, avgPrice: 175 },

    // orbmaster
    { username: "orbmaster", stockId: "CRIC", quantity: 35, avgPrice: 150 },
    { username: "orbmaster", stockId: "WIFI", quantity: 30, avgPrice: 48  },

    // yoloinvestor — one big YOLO bet
    { username: "yoloinvestor", stockId: "PLMT", quantity: 15, avgPrice: 430 },

    // stonksguru
    { username: "stonksguru", stockId: "FEST", quantity: 10, avgPrice: 290 },
    { username: "stonksguru", stockId: "MESS", quantity: 25, avgPrice: 115 },

    // diamondape
    { username: "diamondape", stockId: "HOST", quantity: 50, avgPrice: 68 },
    { username: "diamondape", stockId: "WIFI", quantity: 40, avgPrice: 52 },

    // betshark
    { username: "betshark", stockId: "CRIC", quantity: 20, avgPrice: 155 },

    // campuswhale — small portfolio
    { username: "campuswhale", stockId: "MESS", quantity: 10, avgPrice: 118 },

    // fitnessfinance
    { username: "fitnessfinance", stockId: "HOST", quantity: 25, avgPrice: 70 },

    // rookierunner
    { username: "rookierunner", stockId: "CGPA", quantity: 15, avgPrice: 88 },
];

const seedPortfolio = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("✅ Connected to MongoDB for seeding portfolio data...\n");

        // 1) Seed stocks
        for (const s of stocks) {
            await Stock.findOneAndUpdate(
                { stockId: s.stockId },
                s,
                { upsert: true, returnDocument: "after" }
            );
            console.log(`📈 Stock "${s.stockId}" — ${s.name} @ ${s.price}`);
        }

        // 2) Seed user holdings
        console.log("\n💼 Seeding portfolio holdings...");
        for (const h of holdings) {
            await UserStocks.findOneAndUpdate(
                { username: h.username, stockId: h.stockId },
                h,
                { upsert: true, returnDocument: "after" }
            );
            const stock = stocks.find(s => s.stockId === h.stockId);
            const value = h.quantity * (stock?.price || 0);
            console.log(`   ✅ ${h.username} → ${h.quantity}x ${h.stockId} = ${value} CMX`);
        }

        // 3) Print portfolio summary
        console.log("\n📊 Portfolio value summary:");
        const portfolioMap = {};
        for (const h of holdings) {
            const stock = stocks.find(s => s.stockId === h.stockId);
            const value = h.quantity * (stock?.price || 0);
            portfolioMap[h.username] = (portfolioMap[h.username] || 0) + value;
        }
        Object.entries(portfolioMap)
            .sort(([,a], [,b]) => b - a)
            .forEach(([username, value]) => console.log(`   ${username}: ${value} CMX`));

        console.log("\n🎉 Done!");
    } catch (error) {
        console.error("❌ Error seeding portfolio:", error);
    } finally {
        process.exit(0);
    }
};

seedPortfolio();
