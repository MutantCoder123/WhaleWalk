// require('dotenv').config({path: './env'})
import dotenv from "dotenv"
import connectDB from "./db/db.js";
import {app} from './app.js'
dotenv.config({
    path: './.env'
})

import { stepsToCoinCron } from "./crons/stepsToCoin.cron.js"
import { betResultCron } from "./crons/betResult.cron.js"
import { stockTradeCron } from "./crons/stockTrade.cron.js"
import { marketStatusCron } from "./crons/marketStatus.cron.js"

connectDB()
.then(() => {
    stepsToCoinCron()  // steps to coin
    betResultCron()    // bets Result
    stockTradeCron() 
    marketStatusCron() // automated trading hours
    app.listen(process.env.PORT || 8000, () => {
        console.log(`⚙️ Server is running at port : ${process.env.PORT}`);
    })
})
.catch((err) => {
    console.log("MONGO db connection failed !!! ", err);
})




