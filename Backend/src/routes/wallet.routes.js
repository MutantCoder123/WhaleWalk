import { Router } from "express";
import { getLeaderBoard, convertSteps, convertOrbs } from "../controllers/wallet.controller.js"
import { verifyJWT } from "../middlewares/auth.middleware.js"

const router = Router()

router.route("/leaderboard").get(getLeaderBoard)
router.route("/convert-steps").post(verifyJWT, convertSteps)
router.route("/convert-orbs").post(verifyJWT, convertOrbs)

export default router