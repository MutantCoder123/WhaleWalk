import mongoose from "mongoose";
import { StoreItem } from "./models/store.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const storeItems = [
    // --- TITLES ---
    {
        name: "Diamond Hands",
        description: "For those who never sell, no matter what.",
        price: 5000,
        category: "title",
        rarity: "epic"
    },
    {
        name: "Paper Hands",
        description: "Sold at the first sign of red. Shameful.",
        price: 50,
        category: "title",
        rarity: "common"
    },
    {
        name: "Master of Coin",
        description: "The official treasurer of the campus.",
        price: 10000,
        category: "title",
        rarity: "legendary"
    },
    {
        name: "Degenerate",
        description: "High risk, questionable rewards.",
        price: 420,
        category: "title",
        rarity: "uncommon"
    },
    {
        name: "The Whale",
        description: "Moving markets with a single click.",
        price: 25000,
        category: "title",
        rarity: "mythic"
    },
    {
        name: "Alpha Trader",
        description: "Leading the pack since day one.",
        price: 2500,
        category: "title",
        rarity: "rare"
    },

    // --- BADGES (External URLs - Designed as Frames) ---
    {
        name: "Neon Circuit",
        description: "A futuristic digital border for your profile.",
        price: 1500,
        category: "badge",
        rarity: "rare",
        imageUrl: "media/images/t1badge.png"
    },
    {
        name: "Golden Halo",
        description: "A prestigious circular frame of pure gold.",
        price: 5000,
        category: "badge",
        rarity: "legendary",
        imageUrl: "media/images/t2badge.png"
    },
    {
        name: "Cyber Hexagon",
        description: "Sharp edges for a sharp trader.",
        price: 2500,
        category: "badge",
        rarity: "epic",
        imageUrl: "media/images/t3badge.png"
    },
    {
        name: "Void Portal",
        description: "An enigmatic cosmic boundary.",
        price: 12000,
        category: "badge",
        rarity: "mythic",
        imageUrl: "media/images/t1badge.png"
    },
    {
        name: "Iron Ring",
        description: "A sturdy, reliable frame.",
        price: 200,
        category: "badge",
        rarity: "common",
        imageUrl: "media/images/t2badge.png"
    },
    {
        name: "Diamond Shield",
        description: "Unbreakable protection and prestige.",
        price: 50000,
        category: "badge",
        rarity: "mythic",
        imageUrl: "media/images/t3badge.png"
    }
];

const seedStore = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("Connected to MongoDB for seeding full store...");

        // Clear existing titles/badges if needed, or just upsert
        // We use upsert to avoid duplicates but update content
        for (const item of storeItems) {
            await StoreItem.findOneAndUpdate(
                { name: item.name },
                item,
                { upsert: true, returnDocument: 'after' }
            );
        }

        console.log("Successfully seeded full store with Badges and Titles!");
    } catch (error) {
        console.error("Error seeding store:", error);
    } finally {
        process.exit(0);
    }
};

seedStore();
