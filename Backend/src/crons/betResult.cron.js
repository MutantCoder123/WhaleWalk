import cron from "node-cron"
import { Bet } from "../models/bet.model.js"
import { Enroll } from "../models/enroll.model.js"
import { Wallet } from "../models/wallet.model.js"

const betResultCron = () => {
    cron.schedule('* * * * *', async () => {
        try {
            const now = new Date()  // always UTC in Node.js
            console.log(`Cron running at UTC: ${now.toISOString()}`)

            // find all open bets whose resultTime has passed in UTC
            const expiredBets = await Bet.find({
                status: "open",
                resultTime: { $lte: now }
            })

            console.log(`Found ${expiredBets.length} expired bets`)

            for (const bet of expiredBets) {
                console.log(`Processing bet: ${bet.betId} | result: ${bet.result}`)

                // get all enrollments for this bet
                const enrollments = await Enroll.find({ betId: bet.betId })
                console.log(`Found ${enrollments.length} enrollments`)

                if (enrollments.length === 0) {
                    // no enrollments — just close the bet
                    await Bet.findOneAndUpdate(
                        { betId: bet.betId },
                        { $set: { status: "closed" } }
                    )
                    console.log(`Bet ${bet.betId} closed with no enrollments`)
                    continue
                }

                // get winning side enrollments
                const winners = enrollments.filter(
                    e => e.response === bet.result
                )
                console.log(`Found ${winners.length} winners`)

                if (winners.length === 0) {
                    // no winners — just close the bet, no coins distributed
                    await Bet.findOneAndUpdate(
                        { betId: bet.betId },
                        { $set: { status: "closed" } }
                    )
                    console.log(`Bet ${bet.betId} closed with no winners`)
                    continue
                }

                // calculate total coins on winning side
                const totalWinningCoins = winners.reduce(
                    (sum, e) => sum + e.campusCoins, 0
                )
                console.log(`Total winning coins: ${totalWinningCoins}`)
                console.log(`Total pool: ${bet.totalPool}`)

                // distribute pool to winners proportionally
                for (const winner of winners) {
                    const reward = Math.floor(
                        (winner.campusCoins / totalWinningCoins) * bet.totalPool
                    )
                    console.log(`Rewarding ${winner.username} with ${reward} coins`)

                    await Wallet.findOneAndUpdate(
                        { username: winner.username },
                        { $inc: { campusCoins: reward } }
                    )
                }

                // close the bet
                await Bet.findOneAndUpdate(
                    { betId: bet.betId },
                    { $set: { status: "closed" } }
                )

                console.log(`Bet ${bet.betId} resolved successfully!`)
            }

        } catch (error) {
            console.log("Bet result cron error:", error)
        }
    })  // no timezone needed — using UTC directly like MongoDB
}

export { betResultCron }
/*```

Key points:

`new Date()` in Node.js is always UTC — same as MongoDB storage, so comparison is direct and correct.

No timezone option on cron — since both Node.js and MongoDB use UTC, adding a timezone would cause a mismatch.

Added 3 edge case handlers:
```
enrollments = 0  → just close bet, no coins
winners = 0      → just close bet, pool lost
winners > 0      → distribute proportionally, then close
*/