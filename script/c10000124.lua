--种子巨兽
--部署时，部署2个临时的1/1的植物幼芽，使它们获得效果（可以直接攻击）。
--死亡时，抽1张卡，制造2张星核种子，加入卡组顶部。
local s, id = Import()
function s.initial(c)
	--部署时召唤2个植物幼芽
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--死亡时抽卡并制造星核种子
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

--部署时召唤目标
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=2
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000123,0,TYPES_TOKEN_MONSTER,1,1,1,RACE_PLANT,GALAXY_PROPERTY_LEGION) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,0,0)
end

--部署时召唤操作
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<2 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000123,0,TYPES_TOKEN_MONSTER,1,1,1,RACE_PLANT,GALAXY_PROPERTY_LEGION) then return end

	for i=1,2 do
		local token=Duel.CreateToken(tp,10000123)
		if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK) then
			--给token添加直接攻击能力
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DIRECT_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1,true)

			--客户端提示：可以直接攻击
			local e2=Effect.CreateEffect(c)
			e2:SetDescription(aux.Stringid(id,1))
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e2,true)
		end
	end
	Duel.SpecialSummonComplete()
end

--死亡条件：从场上进入墓地
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

--死亡目标
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,0)
end

--死亡操作
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local d=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)

	--抽1张卡
	Duel.Draw(p,d,REASON_EFFECT)

	--创建2张星核种子token
	local g=Group.CreateGroup()
	for i=1,2 do
		local token=Duel.CreateToken(tp,10000122)
		g:AddCard(token)
	end

	if #g>0 then
		--显示给对手看
		Duel.ConfirmCards(1-tp,g)
		--加入卡组顶部（SEQ_DECKTOP=0）
		Duel.SendtoDeck(g,tp,0,REASON_EFFECT)
	end
end
