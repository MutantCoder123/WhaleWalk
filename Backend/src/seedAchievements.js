import mongoose from "mongoose";
import { Achievement } from "./models/achievement.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "../.env" });

const initialAchievements = [
    // --- STEPS ---
    { title: "First Steps", description: "Walk 1,000 steps.", metric: "STEPS", targetValue: 1000, rewardCoins: 50, rewardOrbs: 0 },
    { title: "Daily Walk", description: "Walk 5,000 steps.", metric: "STEPS", targetValue: 5000, rewardCoins: 100, rewardOrbs: 0 },
    { title: "Active Citizen", description: "Walk 10,000 steps.", metric: "STEPS", targetValue: 10000, rewardCoins: 200, rewardOrbs: 1 },
    { title: "Hiker", description: "Walk 20,000 steps.", metric: "STEPS", targetValue: 20000, rewardCoins: 300, rewardOrbs: 1 },
    { title: "Trailblazer", description: "Walk 50,000 steps.", metric: "STEPS", targetValue: 50000, rewardCoins: 500, rewardOrbs: 2 },
    { title: "Marathoner", description: "Walk 100,000 steps.", metric: "STEPS", targetValue: 100000, rewardCoins: 1000, rewardOrbs: 5 },
    { title: "Globe Trotter", description: "Walk 250,000 steps.", metric: "STEPS", targetValue: 250000, rewardCoins: 2500, rewardOrbs: 10 },
    { title: "Step Legend", description: "Walk 500,000 steps.", metric: "STEPS", targetValue: 500000, rewardCoins: 5000, rewardOrbs: 20 },
    { title: "Unstoppable", description: "Walk 1,000,000 steps.", metric: "STEPS", targetValue: 1000000, rewardCoins: 10000, rewardOrbs: 50 },
    { title: "Olympic Walker", description: "Walk 2,000,000 steps.", metric: "STEPS", targetValue: 2000000, rewardCoins: 20000, rewardOrbs: 100 },

    // --- BETS PLACED ---
    { title: "Taking a Chance", description: "Place your 1st bet.", metric: "BETS_PLACED", targetValue: 1, rewardCoins: 20, rewardOrbs: 0 },
    { title: "Novice Bettor", description: "Place 5 bets.", metric: "BETS_PLACED", targetValue: 5, rewardCoins: 50, rewardOrbs: 0 },
    { title: "Regular", description: "Place 10 bets.", metric: "BETS_PLACED", targetValue: 10, rewardCoins: 100, rewardOrbs: 1 },
    { title: "High Roller", description: "Place 20 bets.", metric: "BETS_PLACED", targetValue: 20, rewardCoins: 200, rewardOrbs: 2 },
    { title: "Risk Taker", description: "Place 50 bets.", metric: "BETS_PLACED", targetValue: 50, rewardCoins: 500, rewardOrbs: 5 },
    { title: "Betting Pro", description: "Place 100 bets.", metric: "BETS_PLACED", targetValue: 100, rewardCoins: 1000, rewardOrbs: 10 },
    { title: "Whale", description: "Place 250 bets.", metric: "BETS_PLACED", targetValue: 250, rewardCoins: 2500, rewardOrbs: 25 },
    { title: "Gambit", description: "Place 500 bets.", metric: "BETS_PLACED", targetValue: 500, rewardCoins: 5000, rewardOrbs: 50 },
    { title: "Casino King", description: "Place 1,000 bets.", metric: "BETS_PLACED", targetValue: 1000, rewardCoins: 10000, rewardOrbs: 100 },
    { title: "Oracle of Probabilities", description: "Place 2,000 bets.", metric: "BETS_PLACED", targetValue: 2000, rewardCoins: 25000, rewardOrbs: 200 },

    // --- BETS WON ---
    { title: "Fortune Favors You", description: "Win your 1st bet.", metric: "BETS_WON", targetValue: 1, rewardCoins: 50, rewardOrbs: 0 },
    { title: "Lucky Streak", description: "Win 5 bets.", metric: "BETS_WON", targetValue: 5, rewardCoins: 150, rewardOrbs: 1 },
    { title: "Clairvoyant", description: "Win 10 bets.", metric: "BETS_WON", targetValue: 10, rewardCoins: 300, rewardOrbs: 2 },
    { title: "Master Predictor", description: "Win 25 bets.", metric: "BETS_WON", targetValue: 25, rewardCoins: 750, rewardOrbs: 5 },
    { title: "Champion", description: "Win 50 bets.", metric: "BETS_WON", targetValue: 50, rewardCoins: 1500, rewardOrbs: 10 },
    { title: "Invincible", description: "Win 100 bets.", metric: "BETS_WON", targetValue: 100, rewardCoins: 3000, rewardOrbs: 20 },
    { title: "Godlike", description: "Win 250 bets.", metric: "BETS_WON", targetValue: 250, rewardCoins: 7500, rewardOrbs: 50 },
    { title: "Supreme Being", description: "Win 500 bets.", metric: "BETS_WON", targetValue: 500, rewardCoins: 15000, rewardOrbs: 100 },
    { title: "Grandmaster", description: "Win 750 bets.", metric: "BETS_WON", targetValue: 750, rewardCoins: 25000, rewardOrbs: 200 },
    { title: "Legend of the Exchange", description: "Win 1,000 bets.", metric: "BETS_WON", targetValue: 1000, rewardCoins: 50000, rewardOrbs: 500 }
];

const seedDB = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("Connected to MongoDB (campusexchangedb) for seeding...");

        await Achievement.deleteMany({});
        await Achievement.insertMany(initialAchievements);

        console.log("Successfully seeded achievements!");
    } catch (error) {
        console.error("Error seeding:", error);
    } finally {
        process.exit(0);
    }
};

seedDB();
