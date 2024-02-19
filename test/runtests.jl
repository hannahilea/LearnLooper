using Test
using LearnLooper
using Aqua

@testset "LearnLooper" begin
    @testset "Aqua" begin
        Aqua.test_all(LearnLooper; ambiguities=false)
    end

    @test isnothing(learn_demo())
end
