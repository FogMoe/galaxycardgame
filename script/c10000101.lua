--银河使者 (Galaxy Messenger)
--开局时从卡组特殊召唤（由utility.lua统一处理）
local s, id = Import()
function s.initial(c)
    -- 开局特殊召唤已在utility.lua的Galaxy.SummonForStart中统一处理
    -- 无需在此处添加额外效果
end
