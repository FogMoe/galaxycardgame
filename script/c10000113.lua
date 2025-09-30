--虚空碎片：发动后获得 1 点补给。
local s,id=Import()

function s.initial(c)
    -- 激活：增加补给
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.AddSupply(tp,1)
end
