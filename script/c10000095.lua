--准备战斗，和战斗的敌方单位一起放入游戏外。
local s, id = Import()
function s.initial(c)
	--准备，和敌方单位一起放入游戏外
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_BATTLE_START)
	e1:SetCondition(s.rmcon)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
end

--检查是否有战斗目标且为敌方单位
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(1-tp)
end

--目标设置：自己和战斗目标
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	local g=Group.FromCards(c,bc)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,3)
end

--执行除外操作
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not c:IsRelateToEffect(e) or not bc or not bc:IsRelateToBattle() then return end

	--将两者一起除外
	local g=Group.FromCards(c,bc)
	if g:GetCount()==2 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		--获得3影响力
		Duel.Recover(tp,3,REASON_EFFECT)
	end
end