import { Router } from "express";
import { 
    loginUser, 
    logoutUser, 
    registerUser, 
    refreshAccessToken, 
    changeCurrentPassword,
    getCurrentUser,
    updateAccountDetails,
} from "../controllers/user.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

import { getWalletInfo } from "../controllers/wallet.controller.js"
import { getStepInfo, updateSteps, getActivityHistory, updateGoals } from "../controllers/steps.controller.js"


const router = Router()

router.route("/register").post(registerUser)

router.route("/login").post(loginUser)

//secured routes
router.route("/logout").post(verifyJWT,  logoutUser)
router.route("/refresh-token").post(refreshAccessToken)
router.route("/change-password").post(verifyJWT, changeCurrentPassword)
router.route("/current-user").get(verifyJWT, getCurrentUser)
router.route("/update-account").patch(verifyJWT, updateAccountDetails)
router.route("/wallet").get(verifyJWT,getWalletInfo)
router.route("/steps").get(verifyJWT,getStepInfo)
router.route("/steps/update").post(verifyJWT, updateSteps)
router.route("/steps/history").get(verifyJWT, getActivityHistory)
router.route("/steps/goals").post(verifyJWT, updateGoals)

export default router