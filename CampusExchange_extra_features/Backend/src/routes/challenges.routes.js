import { Router } from "express";
import { getTimedChallenges, claimChallengeReward } from "../controllers/challenges.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(verifyJWT); // All challenge routes require authentication

router.route("/timed").get(getTimedChallenges);
router.route("/claim").post(claimChallengeReward);

export default router;
