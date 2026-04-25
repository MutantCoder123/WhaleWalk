import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Activity } from './src/models/activity.model.js';
import { User } from './src/models/user.model.js';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URLI;

async function seed() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('Connected!');

        const user = await User.findOne({});
        if (!user) {
            console.error('No user found to seed history for!');
            process.exit(1);
        }

        const username = user.username;
        console.log(`Seeding history for user: ${username}`);

        const today = new Date();
        const activities = [];

        for (let i = 1; i <= 7; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() - i);
            const dateStr = date.toISOString().slice(0, 10);

            // Randomish data
            const steps = Math.floor(Math.random() * 8000) + 4000;
            const distance = parseFloat((steps * 0.0007).toFixed(2));
            const kcal = parseFloat((steps * 0.04).toFixed(1));

            activities.push({
                username,
                date: dateStr,
                actualSteps: steps,
                distanceKm: distance,
                kcal,
                activeMin: Math.floor(steps / 100),
            });
        }

        // Use upsert to avoid duplicates if run multiple times
        for (const activity of activities) {
            await Activity.findOneAndUpdate(
                { username: activity.username, date: activity.date },
                { $set: activity },
                { upsert: true, new: true }
            );
        }

        console.log('Successfully seeded 7 days of activity history.');
        process.exit(0);
    } catch (error) {
        console.error('Seeding failed:', error);
        process.exit(1);
    }
}

seed();
