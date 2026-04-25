import mongoose from "mongoose";
import { TimedChallenge } from "./models/timedChallenge.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const challenges = [
    {
        title: "Daily Wanderer",
        description: "Walk 10,000 steps today to earn your reward.",
        metric: "STEPS",
        targetValue: 10000,
        duration: "DAILY",
        intensity: 1,
        rewardCoins: 500,
        rewardOrbs: 2,
    },
    {
        title: "Marathoner",
        description: "Push your limits with 50,000 steps this week.",
        metric: "STEPS",
        targetValue: 50000,
        duration: "WEEKLY",
        intensity: 3,
        rewardCoins: 2500,
        rewardOrbs: 10,
    },
    {
        title: "Lucky Streak",
        description: "Win 3 bets today to prove your intuition.",
        metric: "BETS_WON",
        targetValue: 3,
        duration: "DAILY",
        intensity: 2,
        rewardCoins: 1000,
        rewardOrbs: 5,
    },
    {
        title: "Betting King",
        description: "Win 10 bets this week to dominate the pools.",
        metric: "BETS_WON",
        targetValue: 10,
        duration: "WEEKLY",
        intensity: 4,
        rewardCoins: 5000,
        rewardOrbs: 20,
    },
    {
        title: "Wealth Accumulator",
        description: "Earn 2,000 coins today from various activities.",
        metric: "COINS_EARNED",
        targetValue: 2000,
        duration: "DAILY",
        intensity: 3,
        rewardCoins: 1500,
        rewardOrbs: 8,
    },
    {
        title: "The Grind",
        description: "Walk 100,000 steps this week. Legend status.",
        metric: "STEPS",
        targetValue: 100000,
        duration: "WEEKLY",
        intensity: 5,
        rewardCoins: 10000,
        rewardOrbs: 50,
    }
];

const seedTimedChallenges = async () => {
    try {
        await mongoose.connect(`${process.env.MONGODB_URLI}/campusexchangedb`);
        console.log("Connected to MongoDB for seeding timed challenges...");

        await TimedChallenge.deleteMany({});
        console.log("Deleted old challenges.");

        await TimedChallenge.insertMany(challenges);
        console.log("Seeded 6 timed challenges.");

        process.exit(0);
    } catch (error) {
        console.error("Error seeding timed challenges:", error);
        process.exit(1);
    }
};

seedTimedChallenges();
