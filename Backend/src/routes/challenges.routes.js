import { Router } from "express";
import { getTimedChallenges, claimChallengeReward, createTimedChallenge } from "../controllers/challenges.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(verifyJWT); // All challenge routes require authentication

router.route("/timed").get(getTimedChallenges).post(createTimedChallenge);
router.route("/claim").post(claimChallengeReward);

export default router;
