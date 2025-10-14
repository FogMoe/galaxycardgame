--机械智能中枢
--死亡时，选择1项效果使用（
--打击：使自己场上所有机械类单位获得效果（可以和多个敌人同时战斗）。
--战争：制造并部署2张3/1的战争机甲，使它们获得效果（直接攻击时劫掠影响力）。
--)

local s,id=Import()

function s.initial(c)
	-- 死亡时选择效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCondition(s.effcon)
	e1:SetTarget(s.efftg)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
end

-- 条件：从场上进入墓地
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

-- 目标：检查是否能执行任一效果
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- 预先声明可能的操作
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,0,0)
end

-- 操作：让玩家选择效果
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- 让玩家选择2个选项之一
	local sel=Duel.SelectOption(tp,
		aux.Stringid(id,1),  -- 选项1：打击（群攻）
		aux.Stringid(id,2))  -- 选项2：战争（生成衍生物）

	if sel==0 then
		-- 选项1：打击 - 场上所有机械类单位获得群攻能力
		local g=Duel.GetMatchingGroup(s.machinefilter,tp,LOCATION_MZONE,0,nil)
		if #g>0 then
			for tc in aux.Next(g) do
				-- 添加可以攻击所有怪兽的效果
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_ATTACK_ALL)
				e1:SetValue(1)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)

				-- 客户端提示：可以和多个敌人同时战斗
				local e2=Effect.CreateEffect(c)
				e2:SetDescription(aux.Stringid(id,3))
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e2)
			end
		end
	elseif sel==1 then
		-- 选项2：战争 - 制造2个3/1战争机甲
		local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
		if ft<2 then return end
		-- 战争机甲token ID: 10000085
		if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000085,0,TYPES_TOKEN_MONSTER,3,1,1,RACE_MACHINE,GALAXY_PROPERTY_COMMON) then return end

		for i=1,2 do
			local token=Duel.CreateToken(tp,10000085)
			if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK) then
				-- 给token添加直接攻击劫掠能力
				-- 监听战斗造成伤害
				local e1=Effect.CreateEffect(c)
				e1:SetDescription(aux.Stringid(id,4))
				e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
				e1:SetCode(EVENT_BATTLE_DAMAGE)
				e1:SetProperty(EFFECT_FLAG_DELAY)
				e1:SetCondition(s.plundercon)
				e1:SetOperation(s.plunderop)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				token:RegisterEffect(e1,true)

				-- 客户端提示：直接攻击时劫掠影响力
				local e2=Effect.CreateEffect(c)
				e2:SetDescription(aux.Stringid(id,4))
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
				e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				token:RegisterEffect(e2,true)
			end
		end
		Duel.SpecialSummonComplete()
	end
end

-- 机械类单位过滤
function s.machinefilter(c)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT)
end

-- 劫掠条件：对敌方玩家造成战斗伤害（直接攻击）
function s.plundercon(e,tp,eg,ep,ev,re,r,rp)
	-- ep~=tp 表示对方玩家受到伤害
	-- GetAttackTarget()==nil 表示直接攻击（没有攻击单位）
	return ep~=tp and Duel.GetAttackTarget()==nil
end

-- 劫掠操作：获得等同于造成伤害的影响力
function s.plunderop(e,tp,eg,ep,ev,re,r,rp)
	-- ev 是造成的伤害值
	Duel.Recover(tp,ev,REASON_EFFECT)
end
