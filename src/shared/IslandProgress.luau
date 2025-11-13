local IslandProgress = {}

export type ProgressEntry = {
    delivered: number,
    status: string?,
    contributions: { [number]: number }?,
}

function IslandProgress.createEntry(): ProgressEntry
    return {
        delivered = 0,
        status = "locked",
        contributions = {},
    }
end

local function resolveDependencyStatus(resolver, dependencyId: string)
    if not resolver then
        return "completed"
    end

    local success, status = pcall(function()
        return resolver(dependencyId)
    end)

    if success and typeof(status) == "string" then
        return status
    end

    return "locked"
end

local function deliveriesRequired(project)
    local req = project.requirements
    if req and req.deliveries and req.deliveries > 0 then
        return req.deliveries
    end
    return 1
end

function IslandProgress.computeStatus(project, progress: ProgressEntry?, resolver)
    progress = progress or IslandProgress.createEntry()

    if not project then
        return "locked"
    end

    for _, dependencyId in ipairs(project.requires or {}) do
        local dependencyStatus = resolveDependencyStatus(resolver, dependencyId)
        if dependencyStatus ~= "completed" then
            return "locked"
        end
    end

    local delivered = progress.delivered or 0
    local required = deliveriesRequired(project)

    if not project.repeatable and delivered >= required then
        return "completed"
    end

    if project.repeatable then
        if delivered > 0 then
            return "repeatable"
        else
            return "available"
        end
    end

    if delivered > 0 then
        return "in-progress"
    end

    return "available"
end

function IslandProgress.toClientPayload(project, progress: ProgressEntry?)
    progress = progress or IslandProgress.createEntry()

    return {
        delivered = progress.delivered or 0,
        status = progress.status or "available",
        contributions = progress.contributions or {},
    }
end

return IslandProgress
