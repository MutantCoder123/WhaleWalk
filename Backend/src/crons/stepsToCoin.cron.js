import cron from "node-cron"
import { Steps } from "../models/step.model.js"
import { Wallet } from "../models/wallet.model.js"

const stepsToCoinCron = () => {
    cron.schedule('*/1 * * * *', async () => {  // runs every 1 minute
        console.log("Running automatic 1-minute steps-to-coin conversion...")

        try {
            const allSteps = await Steps.find({
                availableSteps: { $gte: 100 }
            })

            for (const step of allSteps) {
                const spendableSteps = step.availableSteps ?? 0
                const earnedCoins = Math.floor(spendableSteps / 100)  // 100 steps = 1 coin

                if (earnedCoins > 0) {
                    const deduction = earnedCoins * 100;
                    
                    // add coins to wallet
                    await Wallet.findOneAndUpdate(
                        { username: step.username },
                        { $inc: { campusCoins: earnedCoins } }
                    )

                    // deduct only the converted steps
                    await Steps.findOneAndUpdate(
                        { username: step.username },
                        {
                            $inc: {
                                availableSteps: -deduction
                            }
                        }
                    )

                    console.log(`Auto-Converted ${deduction} steps to ${earnedCoins} coins for ${step.username}`);
                }
            }

            console.log("Auto-conversion cycle complete.")

        } catch (error) {
            console.log("Fitness Cron error:", error)
        }
    })
}

export { stepsToCoinCron }
