import { Router } from "express";
import { getAchievements, acknowledgeAchievements } from "../controllers/achievement.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(verifyJWT);

router.route("/").get(getAchievements);
router.route("/acknowledge").post(acknowledgeAchievements);

export default router;
