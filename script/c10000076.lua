--护卫无人机：攻击时，对所有敌方单位造成1点伤害。
local s, id = Import()
function s.initial(c)
	--攻击时，对所有敌方单位造成1点伤害
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetTarget(s.deftg)
	e1:SetOperation(s.defop)
	c:RegisterEffect(e1)
end

--防御力变化目标
function s.deftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,g:GetCount(),0,0)
end

--伤害操作
function s.defop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	for tc in aux.Next(g) do
		Duel.AddHp(tc, -1, REASON_EFFECT)
	end
end