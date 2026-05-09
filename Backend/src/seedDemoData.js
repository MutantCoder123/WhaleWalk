import mongoose from "mongoose";
import { Wallet } from "./models/wallet.model.js";
import { Steps } from "./models/step.model.js";
import { Achievement } from "./models/achievement.model.js";
import { UserStats } from "./models/userStats.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const USERS = ["aviral", "shrut"];

const seedDemoData = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("Connected to MongoDB for seeding demo data...");

        // Import User model
        const { User } = await import("./models/user.model.js");

        // 1. Add 100,000 coins to each user
        for (const username of USERS) {
            const wallet = await Wallet.findOneAndUpdate(
                { username },
                { $inc: { campusCoins: 100000 } },
                { upsert: true, returnDocument: 'after' }
            );
            console.log(`✅ ${username}: campusCoins = ${wallet.campusCoins}`);
        }

        // 2. Add fitness/steps data
        for (const username of USERS) {
            const stepsData = {
                actualSteps: username === "aviral" ? 45320 : 32100,
                availableSteps: username === "aviral" ? 12000 : 8500,
                stepsCount: username === "aviral" ? 12000 : 8500,
                distanceKm: username === "aviral" ? 34.2 : 24.1,
                kcal: username === "aviral" ? 1820 : 1350,
                activeMin: username === "aviral" ? 285 : 210,
                lastSyncedOn: new Date().toISOString(),
                stepGoal: 10000,
                distanceGoal: 8.0,
            };
            await Steps.findOneAndUpdate(
                { username },
                { $set: stepsData },
                { upsert: true, returnDocument: 'after' }
            );
            console.log(`✅ ${username}: fitness data seeded (${stepsData.actualSteps} steps, ${stepsData.distanceKm}km, ${stepsData.kcal}kcal, ${stepsData.activeMin}min)`);
        }

        // 3. Seed UserStats for achievement unlocking
        for (const username of USERS) {
            const stats = {
                betsPlaced: username === "aviral" ? 12 : 8,
                betsWon: username === "aviral" ? 6 : 3,
            };
            await UserStats.findOneAndUpdate(
                { username },
                { $set: stats },
                { upsert: true, returnDocument: 'after' }
            );
            console.log(`✅ ${username}: userStats seeded (${stats.betsPlaced} bets placed, ${stats.betsWon} won)`);
        }

        // 4. Unlock achievements based on their stats
        const allAchievements = await Achievement.find({});
        console.log(`Found ${allAchievements.length} achievements to evaluate.`);

        for (const username of USERS) {
            const user = await User.findOne({ username });
            if (!user) {
                console.log(`⚠️  User '${username}' not found in DB, skipping achievements.`);
                continue;
            }

            const stats = await UserStats.findOne({ username });
            const steps = await Steps.findOne({ username });
            const totalSteps = steps?.actualSteps ?? 0;
            const betsPlaced = stats?.betsPlaced ?? 0;
            const betsWon = stats?.betsWon ?? 0;

            const toUnlock = [];
            for (const ach of allAchievements) {
                // Skip if already unlocked
                if (user.unlockedAchievements.some(id => id.toString() === ach._id.toString())) continue;

                let qualifies = false;
                switch (ach.metric) {
                    case 'STEPS':
                        qualifies = totalSteps >= ach.targetValue;
                        break;
                    case 'BETS_PLACED':
                        qualifies = betsPlaced >= ach.targetValue;
                        break;
                    case 'BETS_WON':
                        qualifies = betsWon >= ach.targetValue;
                        break;
                }
                if (qualifies) {
                    toUnlock.push(ach);
                }
            }

            if (toUnlock.length > 0) {
                const ids = toUnlock.map(a => a._id);
                await User.findOneAndUpdate(
                    { username },
                    { $addToSet: { unlockedAchievements: { $each: ids } } }
                );
                console.log(`✅ ${username}: Unlocked ${toUnlock.length} achievements: ${toUnlock.map(a => a.title).join(', ')}`);
            } else {
                console.log(`ℹ️  ${username}: No new achievements to unlock.`);
            }
        }

        console.log("\n🎉 All demo data seeded successfully!");
    } catch (error) {
        console.error("Error seeding demo data:", error);
    } finally {
        process.exit(0);
    }
};

seedDemoData();
