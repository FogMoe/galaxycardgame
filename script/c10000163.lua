--打击藤蔓
--死亡时，选择最多3个敌方单位，造成2点伤害。
local s,id = Import()
function s.initial(c)
	--死亡时造成伤害
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCondition(s.damcon)
	e1:SetTarget(s.damtg)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

function s.filter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(1-tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,3,nil)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,#g,0,0)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local tg=g:Filter(Card.IsRelateToEffect,nil,e)
	if #tg>0 then
		for tc in aux.Next(tg) do
			if tc:IsFaceup() and tc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) then
				Duel.AddHp(tc,-2,REASON_EFFECT)
			end
		end
	end
end
