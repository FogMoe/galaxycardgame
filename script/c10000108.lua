--：装备着强化支援时可以劫掠影响力（将战斗造成的影响力收入己方）。
local s,id=Import()

function s.initial(c)
    -- 战斗造成影响力时触发劫掠
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_BATTLE_DAMAGE)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.plundercon)
    e1:SetOperation(s.plunderop)
    c:RegisterEffect(e1)
end

function s.plundercon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return ep~=tp and c:GetEquipGroup():IsExists(Card.IsType,1,nil,TYPE_EQUIP)
end

function s.plunderop(e,tp,eg,ep,ev,re,r,rp)
    -- 劫掠：获得等同于造成伤害的影响力
    Duel.Recover(tp,ev,REASON_EFFECT)
end
