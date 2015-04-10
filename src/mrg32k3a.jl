
const m1 = float64(2^32 - 209)
const m2 = float64(2^32 - 22853)
const a12 = float64(1403580)
const a13 = float64(-810728)
const a21 = float64(527612)
const a23 = float64(-1370589)
const norm = 1.0 / (1 + m1)


const A1p0 =  [  0.0   1.0   0.0 ;
                 0.0   0.0   1.0 ;
                 a13   a12   0.0 ]

const A2p0 =  [  0.0   1.0   0.0 ;
                 0.0   0.0   1.0 ;
                 a23   0.0   a21 ]

const A1p76 =  [   82758667.0  1871391091.0  4127413238.0 ;
                 3672831523.0    69195019.0  1871391091.0 ;
                 3672091415.0  3528743235.0    69195019.0 ]

const A2p76 =  [ 1511326704.0  3759209742.0  1610795712.0 ;
                 4292754251.0  1511326704.0  3889917532.0 ;
                 3859662829.0  4292754251.0  3708466080.0 ]

const A1p127 = [ 2427906178.0  3580155704.0   949770784.0 ;
                  226153695.0  1230515664.0  3580155704.0 ;
                 1988835001.0   986791581.0  1230515664.0 ]

const A2p127 = [ 1464411153.0   277697599.0  1610723613.0 ;
                   32183930.0  1464411153.0  1022607788.0 ; 
                 2824425944.0    32183930.0  2093834863.0 ]
      
const InvA1  = [  184888585.0           0.0  1945170933.0 ;
                          1.0           0.0           0.0 ;
                          0.0           1.0           0.0 ]

const InvA2 =  [          0.0   360363334.0  4225571728.0 ;
                          1.0           0.0           0.0 ;
                          0.0           1.0           0.0 ]
       

type MRG32k3a <: AbstractRNG
    Cg::Vector{Int64}  # the current state of the RNG
    Bg::Vector{Int64}  # the start point of the current substream
    Ig::Vector{Int64}  # the start point of the current stream
    
    function MRG32k3a(x::Vector{Int64})
        @assert(length(x) == 6)
        @assert(all(x[1:3] .> 0))
        @assert(all(x[1:3] .< m1))
        @assert(all(x[4:6] .> 0))
        @assert(all(x[4:6] .< m2))

        new(copy(x),copy(x),copy(x))
    end
end    

# produces a random number with 32 bits of precision

function random_U01(rng::MRG32k3a)
    
    p1::Int64 = (a12 * rng.Cg[2] + a13 * rng.Cg[1]) % m1
    p1 += p1 > 0 ? 0 : m1 

    rng.Cg[1] = rng.Cg[2]
    rng.Cg[2] = rng.Cg[3]
    rng.Cg[3] = p1

    p2::Int64 = (a21 * rng.Cg[6] + a23 * rng.Cg[4]) % m2
    p2 += p2 > 0 ? 0 : m2

    rng.Cg[4] = rng.Cg[5]
    rng.Cg[5] = rng.Cg[6]
    rng.Cg[6] = p2

    u::Float64 = p1 > p2 ? (p1 - p2) * norm : (p1 + m1 - p2) * norm
end  

############################################################
      
type MRG32k3aGen <: AbstractRNGStream
    nextSeed::Vector{Int64}

    function MRG32k3aGen(x::Vector{Int64})
        @assert(length(x) == 6)
        @assert(all(x[1:3] .> 0))
        @assert(all(x[1:3] .< m1))
        @assert(all(x[4:6] .> 0))
        @assert(all(x[4:6] .< m2))

        new(x)
    end

end

function next_stream(rng_gen::MRG32k3aGen)
    rng = MRG32k3a(copy(rng_gen.nextSeed))
    
    rng_gen.nextSeed *= 3
    rng_gen.nextSeed += 1
    rng_gen.nextSeed[1:3] %= m1
    rng_gen.nextSeed[4:6] %= m2
    
    # need to adjust for numerical accuracy
    # rng_gen.nextSeed[1:3] = (A1p127 * rng_gen.nextSeed[1:3]) % m1
    # rng_gen.nextSeed[4:6] = (A2p127 * rng_gen.nextSeed[4:6]) % m2
    
    return rng
end
