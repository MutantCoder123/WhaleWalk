import cron from "node-cron"
import { Steps } from "../models/step.model.js"
import { Wallet } from "../models/wallet.model.js"

const stepsToCoinCron = () => {
    cron.schedule('0 0 * * *', async () => {  // runs every midnight
        console.log("Running steps to coin conversion...")

        try {
            const allSteps = await Steps.find({ stepsCount: { $gt: 0 } })

            for (const step of allSteps) {
                const earnedCoins = Math.floor(step.stepsCount / 10)  // 10 steps = 1 coin

                if (earnedCoins > 0) {
                    // add coins to wallet
                    await Wallet.findOneAndUpdate(
                        { username: step.username },
                        { $inc: { campusCoins: earnedCoins } }
                    )

                    // reset steps to 0
                    await Steps.findOneAndUpdate(
                        { username: step.username },
                        { $set: { stepsCount: 0 } }
                    )
                }
            }

            console.log("Steps to coin conversion done!")

        } catch (error) {
            console.log("Cron job error:", error)
        }
    })
}

export { stepsToCoinCron }