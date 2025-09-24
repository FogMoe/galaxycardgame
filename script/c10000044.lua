--生物质汲取
--支援卡，消耗2点补给，破坏一个友方节肢类单位，抽取等同于其生命值张数的卡（最多4张）。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
		and c:IsType(GALAXY_TYPE_UNIT) and c:IsDestructable()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2)
		and Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) end
	Duel.PaySupplyCost(tp,2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,1) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,1,nil)
	local tc=g:GetFirst()
	local def=tc:GetHp()
	local draw=math.min(def,4)
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(draw)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,draw)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local def=tc:GetDefense()
		local draw=math.min(def,4)
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
			Duel.Draw(p,draw,REASON_EFFECT)
		end
	end
end
