--裂变核武器
--支援卡：消耗7点补给，选择1个敌方单位并破坏，其他敌方单位受到3点伤害，摧毁敌方3点影响力。
local s, id = Import()
function s.initial(c)
	--发动：指定敌方单位并造成范围伤害
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗7点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,7) end
	Duel.PaySupplyCost(tp,7)
end

--可被摧毁的敌方单位
function s.filter(c)
	return c:IsFaceup() and c:IsDestructable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(1-tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,3)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	Duel.Destroy(tc,REASON_EFFECT)
	--对其余敌方单位造成3点伤害
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	if tc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) then
		g:RemoveCard(tc)
	end
	if g:GetCount()>0 then
		for sc in aux.Next(g) do
			Duel.AddHp(sc,-3,REASON_EFFECT)
		end
	end
	--摧毁敌方3点影响力
	Duel.Damage(1-tp,3,REASON_EFFECT)
end
