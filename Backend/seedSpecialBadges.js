import mongoose from "mongoose";
import { StoreItem } from "./src/models/store.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const specialBadges = [
    {
        name: "Achievement Master Level 1",
        description: "Unlocked by earning 5 achievements.",
        price: 0,
        category: "badge",
        imageUrl: "/media/images/t1badge.png",
        isPurchasable: false
    },
    {
        name: "Achievement Master Level 2",
        description: "Unlocked by earning 15 achievements.",
        price: 0,
        category: "badge",
        imageUrl: "/media/images/t2badge.png",
        isPurchasable: false
    },
    {
        name: "Achievement Master Level 3",
        description: "Unlocked by earning 30 achievements.",
        price: 0,
        category: "badge",
        imageUrl: "/media/images/t3badge.png",
        isPurchasable: false
    }
];

const seedBadges = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("Connected to MongoDB for seeding special badges...");

        for (const badge of specialBadges) {
            await StoreItem.findOneAndUpdate(
                { name: badge.name },
                badge,
                { upsert: true, new: true }
            );
        }

        console.log("Successfully seeded special badges!");
    } catch (error) {
        console.error("Error seeding badges:", error);
    } finally {
        process.exit(0);
    }
};

seedBadges();
