--反哺重铠虫
--保护。
--死亡时，为双方回复相当于对方单位数量的影响力。

local s,id=Import()

function s.initial(c)
	-- 效果1：保护（嘲讽）
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)

	-- 效果2：死亡时，为双方回复相当于对方单位数量的影响力
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.reccon)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

-- 效果2的条件：从场上离开且之前是表侧表示
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousLocation(LOCATION_MZONE)
end

-- 效果2的操作：为双方回复相当于对方单位数量的影响力
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	-- 统计对方场上的单位数量
	local count=Duel.GetMatchingGroupCount(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)

	-- 双方都回复相同的数值（对方场上的单位数量）
	if count>0 then
		Duel.Recover(tp,count,REASON_EFFECT)
		Duel.Recover(1-tp,count,REASON_EFFECT)
	end
end
