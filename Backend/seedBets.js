import mongoose from "mongoose";
import { Bet } from "./models/bet.model.js";
import { Enroll } from "./models/enroll.model.js";
import { Wallet } from "./models/wallet.model.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

// ── Helper: random future date between 1–7 days from now ─────────────
const futureDate = (daysMin, daysMax) => {
    const ms = Date.now() + (daysMin + Math.random() * (daysMax - daysMin)) * 86400000;
    return new Date(ms);
};

// ── 10 fun college-life bets ──────────────────────────────────────────
const bets = [
    {
        betId: "MESS_BIRYANI",
        question: "Will the mess serve Biryani this Friday?",
        description: "Every Friday we hope. Every Friday we're disappointed.",
        result: "YES",
        resultTime: futureDate(2, 4),
        accentColor: "orange",
        isTrending: true,
    },
    {
        betId: "PROF_LATE_10",
        question: "Will Prof. Sharma arrive more than 10 min late tomorrow?",
        description: "The man runs on IST — Indian Stretchable Time.",
        result: "YES",
        resultTime: futureDate(1, 2),
        accentColor: "blue",
        isTrending: false,
    },
    {
        betId: "WIFI_SURVIVES",
        question: "Will the campus Wi-Fi survive a full day without dying?",
        description: "Hostel Wi-Fi vs 500 students streaming Netflix. Place your bets.",
        result: "NO",
        resultTime: futureDate(1, 3),
        accentColor: "red",
        isTrending: true,
    },
    {
        betId: "CANTEEN_MAGGI",
        question: "Will the canteen run out of Maggi before 9 PM?",
        description: "Late-night Maggi is a fundamental right. Will supply hold up?",
        result: "YES",
        resultTime: futureDate(1, 2),
        accentColor: "orange",
        isTrending: false,
    },
    {
        betId: "CRICKET_HOSTELA",
        question: "Will Hostel A beat Hostel C in tonight's cricket match?",
        description: "Inter-hostel cricket supremacy is on the line.",
        result: "YES",
        resultTime: futureDate(1, 2),
        accentColor: "green",
        isTrending: true,
    },
    {
        betId: "LAB_VIVA_EASY",
        question: "Will the DBMS lab viva be surprisingly easy?",
        description: "The external examiner smiled today. Is this a trap?",
        result: "NO",
        resultTime: futureDate(3, 5),
        accentColor: "blue",
        isTrending: false,
    },
    {
        betId: "PLACEMENT_PKG",
        question: "Will the next placement offer cross 20 LPA?",
        description: "Dream company visiting campus next week. CTC predictions are wild.",
        result: "YES",
        resultTime: futureDate(5, 7),
        accentColor: "green",
        isTrending: true,
    },
    {
        betId: "RAIN_CANCEL",
        question: "Will heavy rain cancel tomorrow's outdoor sports day?",
        description: "Weather forecast says 80% chance. The principal says 'we'll see'.",
        result: "YES",
        resultTime: futureDate(1, 2),
        accentColor: "blue",
        isTrending: false,
    },
    {
        betId: "LIBRARY_FULL",
        question: "Will every seat in the library be taken by 10 AM during exam week?",
        description: "Semester exams are coming. Suddenly everyone loves the library.",
        result: "YES",
        resultTime: futureDate(4, 6),
        accentColor: "red",
        isTrending: false,
    },
    {
        betId: "FEST_CELEB",
        question: "Will a Bollywood celebrity attend the annual college fest?",
        description: "The committee is being suspiciously secretive about the headliner.",
        result: "YES",
        resultTime: futureDate(6, 7),
        accentColor: "orange",
        isTrending: true,
    },
];

// ── Dummy enrollments to make pools look active ───────────────────────
// username → which bets they enrolled in, with side & coins
const enrollments = [
    { username: "traderknight",   betId: "MESS_BIRYANI",   response: "YES", coins: 500 },
    { username: "coinqueen",      betId: "MESS_BIRYANI",   response: "NO",  coins: 300 },
    { username: "wallstreetbro",  betId: "MESS_BIRYANI",   response: "YES", coins: 200 },
    { username: "cryptowiz",      betId: "PROF_LATE_10",   response: "YES", coins: 400 },
    { username: "orbmaster",      betId: "PROF_LATE_10",   response: "YES", coins: 150 },
    { username: "yoloinvestor",   betId: "PROF_LATE_10",   response: "NO",  coins: 350 },
    { username: "stonksguru",     betId: "WIFI_SURVIVES",  response: "NO",  coins: 600 },
    { username: "diamondape",     betId: "WIFI_SURVIVES",  response: "NO",  coins: 450 },
    { username: "betshark",       betId: "WIFI_SURVIVES",  response: "YES", coins: 200 },
    { username: "traderknight",   betId: "WIFI_SURVIVES",  response: "YES", coins: 300 },
    { username: "campuswhale",    betId: "CANTEEN_MAGGI",  response: "YES", coins: 250 },
    { username: "fitnessfinance", betId: "CANTEEN_MAGGI",  response: "NO",  coins: 100 },
    { username: "rookierunner",   betId: "CANTEEN_MAGGI",  response: "YES", coins: 180 },
    { username: "coinqueen",      betId: "CRICKET_HOSTELA",response: "YES", coins: 500 },
    { username: "wallstreetbro",  betId: "CRICKET_HOSTELA",response: "NO",  coins: 400 },
    { username: "cryptowiz",      betId: "CRICKET_HOSTELA",response: "YES", coins: 300 },
    { username: "orbmaster",      betId: "CRICKET_HOSTELA",response: "NO",  coins: 250 },
    { username: "yoloinvestor",   betId: "LAB_VIVA_EASY",  response: "NO",  coins: 200 },
    { username: "stonksguru",     betId: "LAB_VIVA_EASY",  response: "YES", coins: 100 },
    { username: "diamondape",     betId: "LAB_VIVA_EASY",  response: "NO",  coins: 350 },
    { username: "traderknight",   betId: "PLACEMENT_PKG",  response: "YES", coins: 800 },
    { username: "coinqueen",      betId: "PLACEMENT_PKG",  response: "YES", coins: 600 },
    { username: "betshark",       betId: "PLACEMENT_PKG",  response: "NO",  coins: 400 },
    { username: "campuswhale",    betId: "PLACEMENT_PKG",  response: "YES", coins: 300 },
    { username: "fitnessfinance", betId: "RAIN_CANCEL",    response: "YES", coins: 150 },
    { username: "rookierunner",   betId: "RAIN_CANCEL",    response: "NO",  coins: 200 },
    { username: "orbmaster",      betId: "LIBRARY_FULL",   response: "YES", coins: 250 },
    { username: "yoloinvestor",   betId: "LIBRARY_FULL",   response: "YES", coins: 300 },
    { username: "stonksguru",     betId: "LIBRARY_FULL",   response: "NO",  coins: 150 },
    { username: "traderknight",   betId: "FEST_CELEB",     response: "YES", coins: 1000 },
    { username: "coinqueen",      betId: "FEST_CELEB",     response: "NO",  coins: 500 },
    { username: "wallstreetbro",  betId: "FEST_CELEB",     response: "YES", coins: 700 },
    { username: "cryptowiz",      betId: "FEST_CELEB",     response: "NO",  coins: 400 },
    { username: "diamondape",     betId: "FEST_CELEB",     response: "YES", coins: 350 },
];

// ── Seed function ─────────────────────────────────────────────────────
const seedBets = async () => {
    try {
        const connectionString = process.env.MONGODB_URLI || "mongodb://127.0.0.1:27017";
        await mongoose.connect(`${connectionString}/campusexchangedb`);
        console.log("✅ Connected to MongoDB for seeding bets...\n");

        // 1) Upsert all bets
        for (const bet of bets) {
            await Bet.findOneAndUpdate(
                { betId: bet.betId },
                { ...bet, status: "open", totalEnrolled: 0, totalPool: 0, yesPool: 0, noPool: 0 },
                { upsert: true, returnDocument: "after" }
            );
            console.log(`🎲 Bet "${bet.betId}" — ${bet.question}`);
        }

        // 2) Process enrollments
        console.log("\n📝 Processing enrollments...");
        let enrolled = 0;
        let skipped = 0;

        for (const e of enrollments) {
            // Skip if already enrolled
            const exists = await Enroll.findOne({ betId: e.betId, username: e.username });
            if (exists) {
                skipped++;
                continue;
            }

            // Check wallet has enough coins
            const wallet = await Wallet.findOne({ username: e.username });
            if (!wallet || wallet.campusCoins < e.coins) {
                console.warn(`⚠️  ${e.username} can't afford ${e.coins} for ${e.betId} — skipping`);
                skipped++;
                continue;
            }

            // Create enrollment
            await Enroll.create({
                betId: e.betId,
                username: e.username,
                campusCoins: e.coins,
                response: e.response,
            });

            // Deduct coins
            await Wallet.findOneAndUpdate(
                { username: e.username },
                { $inc: { campusCoins: -e.coins } }
            );

            // Update bet pools
            const poolInc = e.response === "YES"
                ? { $inc: { totalEnrolled: 1, totalPool: e.coins, yesPool: e.coins } }
                : { $inc: { totalEnrolled: 1, totalPool: e.coins, noPool: e.coins } };

            await Bet.findOneAndUpdate({ betId: e.betId }, poolInc);

            console.log(`   ✅ ${e.username} → ${e.betId} (${e.response}, ${e.coins} CMX)`);
            enrolled++;
        }

        console.log(`\n🎉 Done! Created 10 bets, ${enrolled} enrollments, ${skipped} skipped.`);
    } catch (error) {
        console.error("❌ Error seeding bets:", error);
    } finally {
        process.exit(0);
    }
};

seedBets();
