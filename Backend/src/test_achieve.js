import mongoose from "mongoose";
import { User } from "./models/user.model.js";
import { Steps } from "./models/step.model.js";
import { Achievement } from "./models/achievement.model.js";
import { checkAndUnlockAchievements } from "./utils/achievement.utils.js";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" });

const test = async () => {
    try {
        await mongoose.connect(`${process.env.MONGODB_URLI}/campusexchangedb`);
        console.log("Connected to campusexchangedb");

        const username = "testuser_achieve";
        await User.deleteOne({ username });
        await Steps.deleteOne({ username });

        await User.create({ username, fullName: "Test", email: "test@test.com", password: "test" });
        await Steps.create({ username, stepsCount: 200000 });

        console.log("Created user and steps");

        const allA = await Achievement.find();
        console.log("Total achievements in DB:", allA.length);
        
        const unlocked = await checkAndUnlockAchievements(username);
        console.log("Unlocked:", unlocked.map(a => a.title));

        const user = await User.findOne({ username });
        console.log("User unlocked array:", user.unlockedAchievements);

    } catch (e) {
        console.error(e);
    } finally {
        process.exit(0);
    }
};

test();
