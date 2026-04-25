import mongoose from "mongoose";
import bcryptjs from "bcryptjs";
import { User } from "./models/user.model.js";
import { Wallet } from "./models/wallet.model.js";
import { StoreItem } from "./models/store.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

// ── Dummy users with campus-themed names ──────────────────────────────
const dummyUsers = [
    { username: "traderknight",   fullName: "Arjun Mehta",      email: "arjun.m@campus.edu",      college: "RVCE",  coins: 48200 },
    { username: "coinqueen",      fullName: "Priya Sharma",     email: "priya.s@campus.edu",       college: "BMSCE", coins: 39750 },
    { username: "wallstreetbro",  fullName: "Karan Singh",      email: "karan.s@campus.edu",       college: "PESIT", coins: 31500 },
    { username: "cryptowiz",      fullName: "Sneha Reddy",      email: "sneha.r@campus.edu",       college: "MSRIT", coins: 27800 },
    { username: "orbmaster",      fullName: "Rahul Nair",       email: "rahul.n@campus.edu",       college: "RVCE",  coins: 22300 },
    { username: "yoloinvestor",   fullName: "Ananya Gupta",     email: "ananya.g@campus.edu",      college: "BMSCE", coins: 18900 },
    { username: "stonksguru",     fullName: "Varun Patel",      email: "varun.p@campus.edu",       college: "PESIT", coins: 15600 },
    { username: "diamondape",     fullName: "Ishaan Kumar",     email: "ishaan.k@campus.edu",      college: "MSRIT", coins: 12400 },
    { username: "betshark",       fullName: "Meera Joshi",      email: "meera.j@campus.edu",       college: "RVCE",  coins: 9500  },
    { username: "campuswhale",    fullName: "Aditya Rao",       email: "aditya.r@campus.edu",      college: "BMSCE", coins: 7200  },
    { username: "fitnessfinance", fullName: "Riya Deshmukh",    email: "riya.d@campus.edu",        college: "PESIT", coins: 5100  },
    { username: "rookierunner",   fullName: "Nikhil Verma",     email: "nikhil.v@campus.edu",      college: "MSRIT", coins: 3400  },
];

// Titles to assign (matched by name from the store).
// Order matters — first user gets the first title, etc.
const titleAssignments = [
    "The Whale",          // traderknight  – 48200 coins (mythic)
    "Wolf of Campus",     // coinqueen     – 39750 coins (legendary)
    "Master of Coin",     // wallstreetbro – 31500 coins (legendary)
    "Diamond Hands",      // cryptowiz    – 27800 coins (epic)
    "Hedge Fund Hero",    // orbmaster    – 22300 coins (epic)
    "Alpha Trader",       // yoloinvestor – 18900 coins (rare)
    "Crypto Crusader",    // stonksguru   – 15600 coins (rare)
    "Market Maverick",    // diamondape   – 12400 coins (uncommon)
    "Degenerate",         // betshark     – 9500  coins (uncommon)
    "Novice Trader",      // campuswhale  – 7200  coins (common)
    "Paper Hands",        // fitnessfinance – 5100 coins (common)
    "The Architect",      // rookierunner – 3400  coins (mythic, just for fun)
];

const seedDummyUsers = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("✅ Connected to MongoDB for seeding dummy users...\n");

        // Hash a shared dummy password once
        const hashedPassword = await bcryptjs.hash("Campus@123", 10);

        // Pre-fetch all title store items
        const allTitles = await StoreItem.find({ category: "title" });
        const titleMap = {};
        for (const t of allTitles) {
            titleMap[t.name] = t._id;
        }

        let created = 0;
        let skipped = 0;

        for (let i = 0; i < dummyUsers.length; i++) {
            const du = dummyUsers[i];
            const titleName = titleAssignments[i];
            const titleId = titleMap[titleName];

            if (!titleId) {
                console.warn(`⚠️  Title "${titleName}" not found in store. Run seedStore.js / seedTitles.js first!`);
                continue;
            }

            // Check if user already exists
            const existing = await User.findOne({ username: du.username });
            if (existing) {
                console.log(`⏭️  User "${du.username}" already exists — skipping.`);
                skipped++;
                continue;
            }

            // Create user document directly (bypass pre-save hash since we pre-hashed)
            const user = await User.create({
                username: du.username,
                fullName: du.fullName,
                email: du.email,
                college: du.college,
                password: hashedPassword,
                inventory: [titleId],
                activeTitle: titleId,
            });

            // Create wallet with custom coin balance
            await Wallet.findOneAndUpdate(
                { username: du.username },
                { username: du.username, campusCoins: du.coins },
                { upsert: true, new: true }
            );

            console.log(`✅ Created "${du.username}" — ${du.coins} coins — title: "${titleName}"`);
            created++;
        }

        console.log(`\n🎉 Done! Created ${created} users, skipped ${skipped}.`);
    } catch (error) {
        console.error("❌ Error seeding dummy users:", error);
    } finally {
        process.exit(0);
    }
};

seedDummyUsers();
