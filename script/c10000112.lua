--虚空触须：攻击宣言为直接攻击时，生成1张“虚空碎片”加入手牌。
local s,id=Import()

function s.initial(c)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_ATTACK_ANNOUNCE)
    e1:SetCondition(s.thcon)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetAttackTarget()==nil
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local token=Duel.CreateToken(tp,10000113)
    if token then
        Duel.SendtoHand(token,nil,REASON_EFFECT)
    end
end
