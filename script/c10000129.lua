--残骸碎片
--消耗1点补给，获得2点影响力或摧毁敌方2点影响力。
local s, id = Import()
function s.initial(c)
	--激活效果：二选一
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗1点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,1) end
	Duel.PaySupplyCost(tp,1)
end

--目标
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	e:SetLabel(op)
	if op==0 then
		--选择获得2点影响力
		Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,2)
	else
		--选择摧毁敌方2点影响力
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,2)
	end
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		--获得2点影响力
		Duel.Recover(tp,2,REASON_EFFECT)
	else
		--摧毁敌方2点影响力
		Duel.Damage(1-tp,2,REASON_EFFECT)
	end
end
