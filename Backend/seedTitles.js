import mongoose from "mongoose";
import { StoreItem } from "./models/store.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const coolTitles = [
    {
        name: "Novice Trader",
        description: "Just starting the journey.",
        price: 100,
        category: "title",
        rarity: "common"
    },
    {
        name: "Market Maverick",
        description: "Shows promise in the markets.",
        price: 500,
        category: "title",
        rarity: "uncommon"
    },
    {
        name: "Crypto Crusader",
        description: "Master of the digital coins.",
        price: 1500,
        category: "title",
        rarity: "rare"
    },
    {
        name: "Hedge Fund Hero",
        description: "Managing virtual millions with ease.",
        price: 5000,
        category: "title",
        rarity: "epic"
    },
    {
        name: "Wolf of Campus",
        description: "The top predator in the exchange.",
        price: 15000,
        category: "title",
        rarity: "legendary"
    },
    {
        name: "The Architect",
        description: "Sees the patterns others miss.",
        price: 50000,
        category: "title",
        rarity: "mythic"
    },
    {
        name: "Gold Master",
        description: "The classic elite title.",
        price: 0,
        category: "title",
        rarity: "legendary",
        isPurchasable: false
    }
];

const seedTitles = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("Connected to MongoDB for seeding titles...");

        for (const title of coolTitles) {
            await StoreItem.findOneAndUpdate(
                { name: title.name },
                title,
                { upsert: true, new: true }
            );
        }

        console.log("Successfully seeded cool titles!");
    } catch (error) {
        console.error("Error seeding titles:", error);
    } finally {
        process.exit(0);
    }
};

seedTitles();
