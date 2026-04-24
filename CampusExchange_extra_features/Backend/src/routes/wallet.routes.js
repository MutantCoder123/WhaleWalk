import { Router } from "express";
import { getLeaderBoard, convertSteps, convertOrbs, getStepsLeaderboard, getBetsWonLeaderboard, getPortfolioLeaderboard } from "../controllers/wallet.controller.js"
import { verifyJWT } from "../middlewares/auth.middleware.js"

const router = Router()

router.route("/leaderboard").get(getLeaderBoard)
router.route("/leaderboard/steps").get(getStepsLeaderboard)
router.route("/leaderboard/bets-won").get(getBetsWonLeaderboard)
router.route("/leaderboard/portfolio").get(getPortfolioLeaderboard)
router.route("/convert-steps").post(verifyJWT, convertSteps)
router.route("/convert-orbs").post(verifyJWT, convertOrbs)

export default router