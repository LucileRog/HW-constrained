


module AssetTests

	using Base.Test, HW_constrained, JuMP, NLopt, DataFrames, AmplNLWriter, CoinOptServices

	@testset "testing components" begin

		@testset "finite differences" begin
		end

		@testset "test_finite_diff" begin
		end


		@testset "tests gradient of objective function" begin
		d = HW_constrained.data(1.0)
		@test HW_constrained.obj(zeros(4), ones(4), d)[1] == [1.0, 1.0, 1.0200000000000002, 1.01]
		end


		@testset "tests gradient of constraint function" begin
		d = HW_constrained.data(1.0)
		@test HW_constrained.constr(zeros(4), ones(4), d)[1] == [1.0, 1.0, 1.0, 1.0]
		end
	end

	@testset "testing result of both maximization methods" begin
	truth = DataFrame(a=[0.5;1.0;5.0], c=[1.00801;1.00401;1.0008], omega1=[-1.41237;-0.206197;0.758762], omega2=[0.801458;0.400729;0.0801456], omega3=[1.60291;0.801462;0.160291], fval=[-1.20821;-0.732819;-0.013422], diff=[1e-3, 1e-3, 1e-3])

		@testset "checking result of JuMP maximization" begin
		result = HW_constrained.table_JuMP()
		for i in 2:6
			for j in 1:3
		@test abs(result[j, i] - truth[j, i]) < 1e-3
			end
		end
		end

		@testset "checking result of NLopt maximization" begin
		result = HW_constrained.table_NLopt()
		for i in 2:6
			for j in 1:3
		@test abs(result[j, i] - truth[j, i]) < 1e-3
			end
		end
		end
	end




end
