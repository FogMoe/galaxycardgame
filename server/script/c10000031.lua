--舰队总动员
local s, id = Import()
function s.initial(c)
	--魔法卡，把最多3只水属性、攻击力5以下的，融合怪兽从额外卡组特殊召唤，def设为1。支付那些怪兽等级之和的补给作为代价，如补给不足以消耗，则取消部署。
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.filter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsAttribute(ATTRIBUTE_WATER)
		and c:GetAttack()<=5 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	local ct=math.min(ft,3)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,ct,nil,e,tp)
	if g:GetCount()==0 then return end

	-- 先计算等级总和
	local lv_sum=0
	local tc=g:GetFirst()
	while tc do
		lv_sum=lv_sum+tc:GetLevel()
		tc=g:GetNext()
	end

	if g:GetCount()>0 then
		--支付等级之和对应的补给，如果不足则送墓地
		if Duel.CheckSupplyCost(tp, lv_sum) then
			--补给足够，支付代价
			Duel.PaySupplyCost(tp, lv_sum)
			-- 再执行召唤
			local summoned_monsters=Group.CreateGroup()
			tc=g:GetFirst()
			while tc do
				if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP_ATTACK) then
					summoned_monsters:AddCard(tc)
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_SET_DEFENSE)
					e1:SetValue(1)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
				end
				tc=g:GetNext()
			end
			Duel.SpecialSummonComplete()	
		else
			--补给不足，取消部署
			Duel.ConfirmCards(1-tp,g)
		end
	end	
end