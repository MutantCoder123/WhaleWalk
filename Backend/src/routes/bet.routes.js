import { Router } from "express";
import { getallBet,enrolluser,getEnrolledBets,createBet,resolveBet } from "../controllers/bets.controller.js"

import { verifyJWT } from "../middlewares/auth.middleware.js"


const router = Router()

router.route("/allbets").get(getallBet)
router.route("/enroll").post(verifyJWT, enrolluser)
router.route("/mybets").get(verifyJWT, getEnrolledBets)
router.route("/createbet").post(createBet)
router.route("/resolve").post(resolveBet)

export default router