import mongoose from "mongoose";
import dotenv from "dotenv";
import { User } from "./src/models/user.model.js";
import { Wallet } from "./src/models/wallet.model.js";
import { UserStocks } from "./src/models/userstocks.model.js";
import { Stock } from "./src/models/stock.model.js";
import { TimedChallenge } from "./src/models/timedChallenge.model.js";
import { UserChallengeProgress } from "./src/models/userChallengeProgress.model.js";

import { UserStats } from "./src/models/userStats.model.js";
import { Steps } from "./src/models/step.model.js";

dotenv.config({ path: "./.env" });

const seedIndranilData = async () => {
    const username = "indranil";
    try {
        const connectionString = process.env.MONGODB_URLI;
        if (!connectionString) throw new Error("MONGODB_URLI not found in .env");
        
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log(`Connected to MongoDB. Seeding data for user: ${username}`);

        const user = await User.findOne({ username });
        if (!user) {
            console.error(`User "${username}" not found!`);
            process.exit(1);
        }
        const userId = user._id;

        // 1. Reset Stats and Steps
        await UserStats.findOneAndUpdate(
            { username },
            { $set: { betsWon: 5, betsPlaced: 10, stocksTraded: 20 } },
            { upsert: true }
        );
        await Steps.findOneAndUpdate(
            { username },
            { $set: { totalStepsWalked: 15000, campusCoinsEarned: 1000 } },
            { upsert: true }
        );
        console.log(`Reset stats and steps for ${username}.`);

        // 2. Remove all current stocks in portfolio
        await UserStocks.deleteMany({ username });
        console.log(`Deleted all portfolio stocks for ${username}.`);

        // 3. Give 100,000 coins
        await Wallet.findOneAndUpdate(
            { username },
            { $set: { campusCoins: 100000 } }
        );
        console.log(`Set ${username}'s wallet to 100,000 coins.`);

        // 4. Seed dummy value for portfolio
        const stocks = await Stock.find().limit(5); 
        if (stocks.length > 0) {
            for (const stock of stocks) {
                await UserStocks.create({
                    username,
                    stockId: stock.stockId,
                    quantity: Math.floor(Math.random() * 50) + 10,
                    avgPrice: stock.price * (0.9 + Math.random() * 0.2)
                });
            }
            console.log(`Added ${stocks.length} dummy stocks to portfolio.`);
        }

        // 5. Seed dummy value for challenge progress
        await UserChallengeProgress.deleteMany({ user: userId });
        const challenges = await TimedChallenge.find({ isActive: true }).limit(6);
        if (challenges.length > 0) {
            for (const challenge of challenges) {
                const durationDays = challenge.duration === 'DAILY' ? 1 : 7;
                const expiresAt = new Date();
                expiresAt.setDate(expiresAt.getDate() + durationDays);

                // We seed startValue to 0 so the current stats (e.g. 15000 steps) show up as progress
                await UserChallengeProgress.create({
                    user: userId,
                    challenge: challenge._id,
                    startValue: 0, 
                    currentValue: 0, // Will be updated by controller logic
                    status: 'ACTIVE',
                    expiresAt
                });
            }
            console.log(`Added ${challenges.length} dummy challenge progress records.`);
        }

        console.log("\n===============================================");
        console.log("SUCCESS: Comprehensive seeding completed for indranil!");
        console.log("===============================================");
    } catch (error) {
        console.error("Error seeding data:", error);
    } finally {
        await mongoose.disconnect();
        process.exit(0);
    }
};

seedIndranilData();
