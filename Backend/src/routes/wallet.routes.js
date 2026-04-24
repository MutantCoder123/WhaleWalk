import { Router } from "express";
import { getLeaderBoard, convertSteps, convertOrbs, getTransactions, farmOrbs } from "../controllers/wallet.controller.js"
import { verifyJWT } from "../middlewares/auth.middleware.js"

const router = Router()

router.route("/leaderboard").get(getLeaderBoard)
router.route("/convert-steps").post(verifyJWT, convertSteps)
router.route("/convert-orbs").post(verifyJWT, convertOrbs)
router.route("/transactions").get(verifyJWT, getTransactions)
router.route("/farm-orbs").post(verifyJWT, farmOrbs)

export default router