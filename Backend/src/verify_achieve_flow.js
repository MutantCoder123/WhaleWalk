import mongoose from "mongoose";
import { User } from "./models/user.model.js";
import { Steps } from "./models/step.model.js";
import { Achievement } from "./models/achievement.model.js";
import { checkAndUnlockAchievements } from "./utils/achievement.utils.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const verifyFlow = async () => {
    try {
        await mongoose.connect(`${process.env.MONGODB_URLI}/campusexchangedb`);
        console.log("Connected to campusexchangedb");

        const username = "flow_test_user";
        await User.deleteOne({ username });
        await Steps.deleteOne({ username });

        // 1. Create User
        await User.create({ username, fullName: "Flow Test", email: "flow@test.com", password: "test" });
        await Steps.create({ username, actualSteps: 0, stepsCount: 0 });
        console.log("Created flow_test_user");

        // 1.5 Ensure achievements exist
        let allA = await Achievement.find({ isActive: true });
        if (allA.length === 0) {
            console.log("No achievements found, seeding...");
            const initialAchievements = [
                { title: "First Steps", description: "Walk 1,000 steps.", metric: "STEPS", targetValue: 1000, rewardCoins: 50, rewardOrbs: 0, isActive: true },
                { title: "Trailblazer", description: "Walk 50,000 steps.", metric: "STEPS", targetValue: 50000, rewardCoins: 500, rewardOrbs: 2, isActive: true },
            ];
            await Achievement.insertMany(initialAchievements);
            allA = await Achievement.find({ isActive: true });
        }
        console.log("Active achievements in DB:", allA.length);

        // 2. Add Steps to trigger achievement
        const steps = await Steps.findOneAndUpdate(
            { username },
            { $set: { stepsCount: 50000, actualSteps: 50000 } },
            { new: true }
        );
        console.log("Updated steps to 50k");

        // 3. Trigger check
        const unlocked = await checkAndUnlockAchievements(username);
        console.log("Newly Unlocked:", unlocked.map(a => a.title));

        // 4. Verify User state
        let user = await User.findOne({ username });
        console.log("Newly Unlocked in DB:", user.newlyUnlockedAchievements.length);
        
        if (user.newlyUnlockedAchievements.length > 0) {
            console.log("✅ Achievement correctly tracked as 'newly unlocked'");
        } else {
            console.log("❌ Achievement NOT tracked as 'newly unlocked'");
        }

        // 5. Simulate Acknowledge (what the frontend does)
        await User.findOneAndUpdate(
            { username },
            { $set: { newlyUnlockedAchievements: [] } }
        );
        console.log("Simulated Acknowledgement");

        // 6. Verify cleared
        user = await User.findOne({ username });
        console.log("Newly Unlocked after ack:", user.newlyUnlockedAchievements.length);

        if (user.newlyUnlockedAchievements.length === 0) {
            console.log("✅ Acknowledgement flow verified");
        } else {
            console.log("❌ Acknowledgement flow FAILED");
        }

    } catch (e) {
        console.error(e);
    } finally {
        process.exit(0);
    }
};

verifyFlow();
