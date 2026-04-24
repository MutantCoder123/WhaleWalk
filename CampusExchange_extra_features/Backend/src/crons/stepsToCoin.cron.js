import cron from "node-cron"
import { Steps } from "../models/step.model.js"
import { Wallet } from "../models/wallet.model.js"

const stepsToCoinCron = () => {
    // '* * * * *' runs every minute
    cron.schedule('* * * * *', async () => {  
        try {
            const allSteps = await Steps.find();

            for (const step of allSteps) {
                const collectableSteps = step.stepsCount - (step.convertedSteps || 0);

                // Check if they have at least enough to make a conversion 
                // (using 100 steps = 1 coin to match manual conversion rate)
                if (collectableSteps >= 100) {
                    const stepsToConvert = Math.floor(collectableSteps / 100) * 100;
                    const earnedCoins = stepsToConvert / 100;

                    if (earnedCoins > 0) {
                        // add coins to wallet
                        await Wallet.findOneAndUpdate(
                            { username: step.username },
                            { $inc: { campusCoins: earnedCoins } }
                        );

                        // Increment convertedSteps by the amount we just processed
                        // Do NOT reset stepsCount to 0!
                        await Steps.findOneAndUpdate(
                            { username: step.username },
                            { $inc: { convertedSteps: stepsToConvert } }
                        );
                    }
                }
            }
        } catch (error) {
            console.error("Cron job error:", error);
        }
    });
}

export { stepsToCoinCron }