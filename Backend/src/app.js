import express from "express"
import cors from "cors"
import cookieParser from "cookie-parser"
import dotenv from "dotenv"

dotenv.config({
    path: "./.env"
})

const app = express()

const corsOrigin = process.env.CORS_ORIGIN?.trim()

app.use(cors({
    origin: !corsOrigin || corsOrigin === "*" ? true : corsOrigin,
    credentials: true
}))

app.use(express.json({limit: "25kb"}))
app.use(express.urlencoded({ extended: true, limit: "16kb" }))
app.use(express.static("public"))
app.use(cookieParser())

app.get("/health", (_, res) => {
    res.status(200).json({ success: true, message: "Backend is reachable" })
})


//routes import
import userRouter from './routes/user.routes.js'
import walletRouter from './routes/wallet.routes.js'
import betRouter from './routes/bet.routes.js'
import stockRouter from './routes/stock.routes.js'
import storeRouter from './routes/store.routes.js'
import achievementRouter from './routes/achievement.routes.js'
import zoneRouter from './routes/zone.routes.js'

//routes declaration
app.use("/api/v1/users", userRouter)
app.use("/api/v1/wallet", walletRouter)
app.use("/api/v1/bet",betRouter)
app.use("/api/v1/stocks", stockRouter)
app.use("/api/v1/store", storeRouter)
app.use("/api/v1/achievements", achievementRouter)
app.use("/api/v1/zones", zoneRouter)
// http://localhost:4000/api/v1/users/register

app.use((req, res) => {
    res.status(404).json({
        statusCode: 404,
        data: null,
        message: `Route not found: ${req.originalUrl}`,
        success: false
    })
})

app.use((err, req, res, next) => {
    const statusCode = err.statusCode || 500

    res.status(statusCode).json({
        statusCode,
        data: null,
        message: err.message || "Internal Server Error",
        success: false,
        errors: err.errors || []
    })
})

export { app }
