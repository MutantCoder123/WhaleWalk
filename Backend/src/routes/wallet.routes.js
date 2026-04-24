import { Router } from "express";
import { getLeaderBoard, convertSteps, convertOrbs, getStepsLeaderboard, getBetsWonLeaderboard, getPortfolioLeaderboard, getTransactions, farmOrbs } from "../controllers/wallet.controller.js"
import { verifyJWT } from "../middlewares/auth.middleware.js"

const router = Router()

router.use(verifyJWT)

router.route("/leaderboard").get(getLeaderBoard)
router.route("/leaderboard/steps").get(getStepsLeaderboard)
router.route("/leaderboard/bets-won").get(getBetsWonLeaderboard)
router.route("/leaderboard/portfolio").get(getPortfolioLeaderboard)
router.route("/convert-steps").post(convertSteps)
router.route("/convert-orbs").post(convertOrbs)
router.route("/history").get(getTransactions)
router.route("/farm-orbs").post(farmOrbs)

export default router