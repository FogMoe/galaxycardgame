--[[message 新手指引教程 Beginner Guide]]
-- 教程目标：在当前回合内击败「人类叛军」AI，学习部署与战术运用流程。

Debug.SetAIName("人类叛军 Human rebels")
Debug.ReloadFieldBegin(DUEL_ATTACK_FIRST_TURN + DUEL_SIMPLE_AI, 2)

-- 玩家/AI 基础数据
Debug.SetPlayerInfo(0, 10, 0, 0)
Debug.SetPlayerInfo(1, 7, 0, 0)
Duel.SetSupply(0, 6, 6)
Duel.SetSupply(1, 5, 5)

-- 我方场地：补给线（持续支援，用于教学抽牌）
Debug.AddCard(10000032, 0, 0, LOCATION_SZONE, 1, POS_FACEUP)

-- 我方手牌：太阳系先锋（Rush 单位，部署后可立即攻击）
Debug.AddCard(10000002, 0, 0, LOCATION_HAND, 0, POS_FACEDOWN)
Debug.AddCard(10000018, 0, 0, LOCATION_HAND, 0, POS_FACEDOWN)
Debug.AddCard(10000009, 0, 0, LOCATION_HAND, 0, POS_FACEDOWN)

-- 我方卡组顶：精确打击（部署先锋后通过补给线抽得）
Debug.AddCard(10000028, 0, 0, LOCATION_DECK, 0, POS_FACEDOWN)
Debug.AddCard(10000018, 0, 0, LOCATION_DECK, 0, POS_FACEDOWN)
Debug.ShowHint("指挥官：欢迎来到新手指引教程。目标是在这个回合内消灭人类叛军。")
Debug.ShowHint("Commander: Welcome to the Beginner Guide. Your goal is to destroy the human rebels within this round.")
Debug.ShowHint("回合结束即判定失败。请按照引导完成第一场胜利。祝你好运！")
Debug.ShowHint("If you end your turn, you will lose. Please follow the instructions to complete your first victory. Good luck!")

Debug.ReloadFieldEnd()
aux.BeginPuzzle()

local function DeployRebelForces()
	local tp = 1
	if Duel.GetFieldGroupCount(tp, LOCATION_MZONE, 0) > 0 then return end
	local guard = Duel.CreateToken(tp, 10000019)
	if guard then
		Duel.SpecialSummonStep(guard, 0, tp, tp, false, false, POS_FACEUP_ATTACK)
		Duel.MoveSequence(guard, 1)
		Duel.PaySupplyCost(tp, guard:GetLevel())
	end
	local raider = Duel.CreateToken(tp, 10000016)
	if raider then
		Duel.SpecialSummonStep(raider, 0, tp, tp, false, false, POS_FACEUP_ATTACK)
		Duel.MoveSequence(raider, 2)
		Duel.PaySupplyCost(tp, raider:GetLevel())
	end
	Duel.SpecialSummonComplete()
	Debug.ShowHint("人类叛军刚刚从手牌部署了单位，请按照引导突破。")
	Debug.ShowHint("The human rebels have just deployed units from their hand. Please follow the instructions to break through.")
	Debug.ShowHint("消耗补给，将太阳系先锋部署到前线。支援区的补给线会因为部署补给≤3的单位而让你抽1张牌。")
	Debug.ShowHint("Pay supply to deploy the Solar Vanguard to the front line. The Supply Lines in the Support Zone will let you draw 1 card for deploying a unit with supply cost ≤ 3.")
	Debug.ShowHint("部署抽到的太阳系先锋。但殖民地防卫军拥有保护，必须先被歼灭。")
	Debug.ShowHint("Deploy the drawn Solar Vanguard. But the Colonial Defense Corps has Protection and must be destroyed first.")
	Debug.ShowHint("使用精确打击直接攻击对方。然后进入交战阶段，操控单位攻击殖民地防卫军，体验战斗的判定。")
	Debug.ShowHint("Use Precision Strike to attack the opponent directly. Then enter the Combat Phase and control your units to attack the Colonial Defense Corps to experience the battle judgment.")
	Debug.ShowHint("击败单位后，直接攻击对方，终结人类叛军。")
	Debug.ShowHint("After defeating the unit, attack the opponent directly to eliminate the human rebels.")
end

local eInit = Effect.GlobalEffect()
eInit:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
eInit:SetCode(EVENT_ADJUST)
eInit:SetCountLimit(1)
eInit:SetOperation(function(e)
	e:Reset()
	DeployRebelForces()
end)
Duel.RegisterEffect(eInit, 0)

Debug.ShowHint("检查手牌的太阳系先锋。它具备部署当回合即可攻击。")
Debug.ShowHint("Check the Solar Vanguard in your hand. It can attack the turn it is deployed.")
