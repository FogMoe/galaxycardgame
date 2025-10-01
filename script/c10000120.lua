--宇宙巨藤根
--保护友方单位。
--部署时，对所有敌方单位造成4点伤害。
--死亡时，把自己的影响力增加到20点。
local s, id = Import()
function s.initial(c)
	--保护效果：嘲讽，对方单位必须优先攻击这张卡
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)

	--部署时对所有敌方单位造成4点伤害
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)

	--死亡时给玩家增加20点影响力
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.reccon)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
end

--部署时伤害目标检查
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil) end
end

--部署时伤害操作
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	if g:GetCount()==0 then return end

	local tc=g:GetFirst()
	while tc do
		--对每个敌方单位造成4点伤害
		Duel.AddHp(tc, -4, REASON_EFFECT)
		tc=g:GetNext()
	end
end

--死亡条件：从场上进入墓地
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

--死亡时恢复操作
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	--如果玩家生命值低于20，则恢复到20点
	local lp=Duel.GetLP(tp)
	if lp<20 then
		Duel.Recover(tp,20-lp,REASON_EFFECT)
	end
end
