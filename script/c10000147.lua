--负载增殖
--支援卡：对方增加1点影响力，制造并部署1只1/1的幼小爬虫，然后，制造2张该卡并加入卡组。

local s,id=Import()

function s.initial(c)
	-- 激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000143,0,TYPES_TOKEN_MONSTER,1,1,1,0,0) end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,1-tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 对方增加1点影响力
	Duel.Recover(1-tp,1,REASON_EFFECT)

	-- 2. 制造并部署1只幼小爬虫
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000143,0,TYPES_TOKEN_MONSTER,1,1,1,0,0) then
		local token=Duel.CreateToken(tp,10000143)
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end

	Duel.BreakEffect()
	-- 3. 制造2张该卡（10000147）并洗入卡组
	local copies=Group.CreateGroup()
	for i=1,2 do
		local copy=Duel.CreateToken(tp,id)
		copies:AddCard(copy)
	end
	-- 展示制造的2张卡片给对手
	Duel.ConfirmCards(1-tp,copies)
	-- 洗入卡组
	Duel.SendtoDeck(copies,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end
