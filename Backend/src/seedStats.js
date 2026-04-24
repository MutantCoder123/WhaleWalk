import mongoose from "mongoose";
import { Steps } from "./models/step.model.js";
import { UserStats } from "./models/userStats.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

// ── Dummy fitness & betting stats ─────────────────────────────────────
const userStats = [
    { username: "traderknight",   steps: 87500,  betsPlaced: 12, betsWon: 8  },
    { username: "coinqueen",      steps: 62300,  betsPlaced: 10, betsWon: 7  },
    { username: "wallstreetbro",  steps: 45800,  betsPlaced: 8,  betsWon: 5  },
    { username: "cryptowiz",      steps: 103000, betsPlaced: 15, betsWon: 6  },
    { username: "orbmaster",      steps: 71200,  betsPlaced: 6,  betsWon: 4  },
    { username: "yoloinvestor",   steps: 34500,  betsPlaced: 9,  betsWon: 3  },
    { username: "stonksguru",     steps: 55000,  betsPlaced: 7,  betsWon: 2  },
    { username: "diamondape",     steps: 28700,  betsPlaced: 5,  betsWon: 1  },
    { username: "betshark",       steps: 92400,  betsPlaced: 20, betsWon: 14 },
    { username: "campuswhale",    steps: 41000,  betsPlaced: 3,  betsWon: 2  },
    { username: "fitnessfinance", steps: 130500, betsPlaced: 4,  betsWon: 1  },
    { username: "rookierunner",   steps: 115000, betsPlaced: 2,  betsWon: 0  },
];

const seedStats = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("✅ Connected to MongoDB for seeding stats...\n");

        for (const u of userStats) {
            // Upsert steps
            await Steps.findOneAndUpdate(
                { username: u.username },
                {
                    username: u.username,
                    stepsCount: u.steps,
                    totalStepsWalked: u.steps,
                    convertedSteps: 0,
                },
                { upsert: true, returnDocument: "after" }
            );

            // Upsert user stats (bets)
            await UserStats.findOneAndUpdate(
                { username: u.username },
                {
                    username: u.username,
                    betsPlaced: u.betsPlaced,
                    betsWon: u.betsWon,
                },
                { upsert: true, returnDocument: "after" }
            );

            console.log(`✅ ${u.username} — ${u.steps} steps, ${u.betsWon}/${u.betsPlaced} bets won`);
        }

        console.log("\n🎉 Done! Seeded steps & bet stats for all dummy users.");
    } catch (error) {
        console.error("❌ Error seeding stats:", error);
    } finally {
        process.exit(0);
    }
};

seedStats();
