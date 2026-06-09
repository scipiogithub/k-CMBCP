using Random
using StatsBase
using HTTP


function randomC()::Vector{Vector{Int}}
    cuts = sort(rand(1:(S - 1), K - 1))
    elements = diff([0; cuts; S])
    cuts = collect(1:S)
    shuffle!(cuts)
    C = Vector{Int64}[]
    start, stop = 0, 0
    for i in eachindex(elements)
        start = stop + 1
        stop = start + elements[i] - 1
        push!(C, cuts[start:stop]) 
    end
    return C
end

function action(s::Int64, ϵ::Float64)::Int
    rand() < ϵ && return rand(1:K)
    return argmax(qtable[s, :])
end

@inline function fitnes(ci::Vector{Int})
    cols = size(edges, 2)

    s = 0
    for j in 1:cols
        p = length(ci)
        for k in ci p -= edges[k, j] end
        s += p == length(ci) ? 0 : p
    end
    return s
end


function fitness(C::Vector{Vector{Int}})
    Tcost = 0
    costs = zeros(Int, length(C))

    @inbounds for i in eachindex(C)
        isempty(C[i]) && continue
        s = fitnes(C[i])
        costs[i] = s
        Tcost += s
    end

    return Tcost, costs
end

function move2!(C::Vector{Vector{Int64}}, Tcost::Int64, costs::Vector{Int64})::Int64
    for c₁ in 1:K, c₂ in 1:K
        c₁ == c₂ && continue
        λ = length(C[c₂])
        λ < 2 && continue
        C₁, C₂ = copy(C[c₁]), copy(C[c₂])
        i₁::Int64 = 1
        while i₁ < λ
            i₂::Int64 = i₁ + 1
            while i₂ <= λ 
                i, j = C₂[[i₁, i₂]]
                deleteat!(C₂, i₁)
                deleteat!(C₂, i₂ - 1)
                append!(C₁, (i, j))
                newcost₁ = fitnes(C₁)
                newcost₂ = λ == 2 ? 0 : fitnes(C₂)
                if newcost₁ + newcost₂ < costs[c₁] + costs[c₂]
                    Tcost += newcost₁ + newcost₂ - costs[c₁] - costs[c₂]
                    deleteat!(C[c₂], i₁)
                    deleteat!(C[c₂], i₂ - 1)
                    append!(C[c₁], (i, j))
                    costs[c₁], costs[c₂] = newcost₁, newcost₂
                    λ -= 2
                else
                    resize!(C₁, length(C₁) - 2)
                    insert!(C₂, i₁, i)
                    insert!(C₂, i₂, j)
                    i₂ += 1
                end
            end
            i₁ += 1
        end
    end
    return Tcost
end

function move!(C::Vector{Vector{Int64}}, Tcost::Int64, costs::Vector{Int64})::Int64
    for c₁ in 1:K, c₂ in 1:K
        c₁ == c₂ && continue
        λ = length(C[c₂])
        λ == 0 && continue
        C₁, C₂ = copy(C[c₁]), copy(C[c₂])
        i::Int64 = 1
        while i <= λ
            j = C₂[i]
            deleteat!(C₂, i)
            push!(C₁, j)
            newcost₁ = fitnes(C₁)
            newcost₂ = λ == 1 ? 0 : fitnes(C₂)
            if newcost₁ + newcost₂ < costs[c₁] + costs[c₂]
                Tcost += newcost₁ + newcost₂ - costs[c₁] - costs[c₂]
                deleteat!(C[c₂], i)
                push!(C[c₁], j)
                costs[c₁], costs[c₂] = newcost₁, newcost₂
                λ -= 1
            else
                pop!(C₁)
                insert!(C₂, i, j)
                i += 1
            end
        end
    end
    return Tcost
end

function swap!(C::Vector{Vector{Int64}}, Tcost::Int64, costs::Vector{Int64})::Int64
    for c₁ in 1:(K - 1), c₂ in (c₁ + 1):K
        λ₁, λ₂ = length(C[c₁]), length(C[c₂])
        λ₁ == 0 || λ₂ == 0 && continue
        C₁, C₂ = copy(C[c₁]), copy(C[c₂])
        for i₁ in 1:λ₁, i₂ in 1:λ₂
            C₁[i₁], C₂[i₂] = C₂[i₂], C₁[i₁]    
            newcost₁ = fitnes(C₁)
            newcost₂ = fitnes(C₂)
            if newcost₁ + newcost₂ < costs[c₁] + costs[c₂]
                Tcost += newcost₁ + newcost₂ - costs[c₁] - costs[c₂]
                C[c₁][i₁], C[c₂][i₂] = C[c₂][i₂], C[c₁][i₁]
                costs[c₁], costs[c₂] = newcost₁, newcost₂
            else
                C₁[i₁], C₂[i₂] = C₂[i₂], C₁[i₁]
            end
        end
    end
    return Tcost
end


function main(ϵ, ω, Δϵ, Δω, T)
    trapped = false
    funks = [swap!, move!, move2!]
    C = randomC()
    Tcost, costs = fitness(C)
    Tcost = swap!(C, Tcost, costs)
    Tcost = move!(C, Tcost, costs)
    Tcost = move2!(C, Tcost, costs)
    bestC, bestTcost, bestCosts = deepcopy(C), Tcost, copy(costs)   
    
    ΣΔ = 0.0
    t = time()
    bestₜ = 0.0
    for counter in 1:999999999
        if trapped
            C = randomC()
        else
            C = [Int64[] for _ in 1:K]
            for s in 1:S
                c = action(s, ϵ)
                push!(C[c], s)
            end
        end
        newTcost, costs = fitness(C)
        shuffle!(funks)
        if rand() < ω
            tempcost = newTcost    
            while true
                for f in funks tempcost = f(C, tempcost, costs) end
                tempcost == newTcost && break
                newTcost = tempcost
            end
        else
            for f in funks
                newTcost = f(C, newTcost, costs)
            end
        end
        Δ = Tcost - newTcost
        if Δ != 0
            for i in eachindex(C)
                for s in C[i]
                    qtable[s, i] += α * (sign(Δ) + γ * maximum(qtable[s, :]) - qtable[s, i])
                end
            end
        end
        Tcost = newTcost
        ΣΔ += Δ
        if counter % stepsize == 0
            trapped = ΣΔ == 0
            a = round(ΣΔ / stepsize)
            if abs(a) < 5
                Δϵ, Δω = 0, 0
            elseif a < 0
                Δϵ = Δϵ == 0 ? rand([-1, 1]) : Δϵ *= -1
                Δω = Δω == 0 ? rand([-1, 1]) : Δω *= -1
            end
            ΣΔ = 0
            ϵ = max(0, ϵ + Δϵ * 0.01)
            ω = max(0, ω + Δω * 0.01)
        end
        if Tcost < bestTcost
            bestₜ = time() - t
            for i in eachindex(C)
                for s in C[i]
                    qtable[s, i] += 1
                end
            end
            bestTcost = Tcost
            bestCosts = copy(costs)
            bestC = deepcopy(C)
        end
        time() - t >= T && break
    end
    return bestTcost, bestₜ 
end

function readFile(filename)
    response = HTTP.get(filename)
    text = String(response.body)
    lines = split(text, "\n")
    
    tx = parse.(Int, split(lines[1], r"\s+"))
    c = tx[2]
    es = BitMatrix(falses(tx[1], c))
    k = tx[3]
    for i=2:length(lines)
        lines[i] == "" && continue
        tx = parse.(Int, split(lines[i], r"\s+"))
        es[tx[1], tx[2] - c] = true
    end
    return es, k
end

url = "https://raw.githubusercontent.com/scipiogithub/k-CMBCP/main/data/"
filename = ARGS[1]
const edges, K = readFile("$url$filename")
const S = size(edges, 1)
const qtable = ones(Float64, S, K) 
const stepsize = S < 200 ? 10 : (S < 300 ? 5 : 2)
const α, γ = 0.1, 0.9
f, t = main(0.05, 0.05, 1, 1, parse(Int, ARGS[2]))
println("F_best:$f t_best:$t")