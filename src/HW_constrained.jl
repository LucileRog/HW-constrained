

# constrained maximization exercises

## portfolio choice problem

module HW_constrained

	using JuMP, NLopt, DataFrames, Ipopt #AmplNLWriter, CoinOptServices

	export data, table_NLopt, table_JuMP

	function data(a=0.5)
		n = 3
		S = 4^2
		e = (2.0, 0.0, 0.0)
		p = ones(n)
		z1 = ones(4)
		z2 = [.72, .92, 1.12, 1.32]
		z3 = [.86, .96, 1.06, 1.16]
		z = hcat(ones(S), repeat(z2, inner = 1, outer = 4), repeat(z3, inner = 4, outer = 1))
		return Dict("a" => a, "n"=> n,"endow"=> e, "price"=> p, "S" => S, "outcome" => z)
	end

	function u(x, a_)
		-exp(-a_ .* x)
	end

	function u_prim(x, a_)
		a_ .* exp(-a_ .* x)
	end

	function max_JuMP(a=0.5)
	d = data(a)
	m = Model(solver=IpoptSolver())
	@variable(m, c >= 0.0)
	@variable(m, omega1)
	@variable(m, omega2)
	@variable(m, omega3)
	@NLobjective(m, Max, -exp(-d["a"]*c) - (1/d["S"]) * sum( exp(-d["a"]*(omega1*d["outcome"][s,1]+omega2*d["outcome"][s,2]+omega3*d["outcome"][s,3])) for s in 1:d["S"]))
	@NLconstraint(m, c + d["price"][1]*(omega1-d["endow"][1]) + d["price"][2]*(omega2-d["endow"][2]) + d["price"][3]*(omega3-d["endow"][3])  == 0.0)
	status = solve(m)
	res = (getvalue(c), getvalue(omega1), getvalue(omega2), getvalue(omega3), getobjectivevalue(m))
	return res
	end
	max_JuMP()

	function table_JuMP()
	  d = DataFrame(a=[0.5;1.0;5.0], c = zeros(3), omega1=zeros(3), omega2=zeros(3), omega3=zeros(3), fval=zeros(3))
	  for i in 1:3
	    result = max_JuMP(d[1][i])
	  for j in 1:5
	  d[1+j][i] = result[j]
	  end
	  end
	  return d
	  display(d)
	end

	function obj(x::Vector,grad::Vector,data::Dict)
		if length(grad) > 0
        grad[1] = u_prim(x[1], data["a"])
		for i in 2:4
        grad[i] = (1/data["S"]) * sum(data["outcome"][s,i-1] * u_prim(sum(x[j+1]*data["outcome"][s,j] for j in 1:data["n"]), data["a"]) for s in 1:data["S"])
		end
		end
		objfun = u(x[1], data["a"]) + (1/data["S"]) * sum( u( sum(x[i+1]*data["outcome"][s,i] for i in 1:data["n"]), data["a"]) for s in 1:data["S"])
		return grad, objfun
	end



	function constr(x::Vector,grad::Vector,data::Dict)
		if length(grad) > 0
				grad[1] = 1
				for i in 2:4
				grad[i] = data["price"][i-1]
				end
		end
		constr = x[1] + sum(data["price"][i-1] * (x[i] - data["endow"][i-1]) for i in 2:4)
		return grad, constr
	end


	#function max_NLopt(a=0.5)
		#d = data(a)
		# define the algorithm (LD_SLSQP to allow for equality constraints) and dims
		#opt = NLopt.Opt(:LD_SLSQP,4)
		# define the type optimization
		#max_objective!(opt,(x,g)->obj(x,g,d)[2])
		# define the bounds, note that consumption can not be negative
		#lower_bounds!(opt,[0;[-Inf for i=1:3]])
		#upper_bounds!(opt,[+Inf for i=1:4])
		# define the constraint
		#equality_constraint!(opt,(x,g)->constr(x,g,d)[2],1e-4)
		#(optf,optx,ret) = NLopt.optimize(opt, ones(4))
		#ftol_rel!(opt,1e-4)
	#end


	function max_NLopt(a=0.5)

		d = data(a)
		# define the algorithm (LD_SLSQP to allow for equality constraints) and dims
		opt = NLopt.Opt(:LD_SLSQP,4)

		# define the type optimization
		max_objective!(opt,(x,g)->obj(x,g,d)[2])
		# define the bounds, note that consumption can not be negative
		lower_bounds!(opt,[0;[-Inf for i=1:3]])
		upper_bounds!(opt,[+Inf for i=1:4])
		xtol_rel!(opt,1e-9)
		ftol_rel!(opt,1e-9)

		# define the constraint
		equality_constraint!(opt,(x,g)->constr(x,g,d)[2],1e-9)
		(optf,optx,ret) = optimize(opt, rand(4))
		return [optx; optf]

	end


	function table_NLopt()

		d = DataFrame(a=[0.5;1.0;5.0], c = zeros(3), omega1=zeros(3), omega2=zeros(3), omega3=zeros(3), fval=zeros(3))
		for i in 1:3
			result = max_NLopt(d[i,1])
			for j in 1:5
				d[1+j][i] = result[j]
			end
		end
		return d

	end

	# function `f` is for the NLopt interface, i.e.
	# it has 2 arguments `x` and `grad`, where `grad` is
	# modified in place
	# if you want to call `f` with more than those 2 args, you need to
	# specify an anonymous function as in
	# other_arg = 3.3
	# test_finite_diff((x,g)->f(x,g,other_arg), x )
	# this function cycles through all dimensions of `f` and applies
	# the finite differencing to each. it prints some nice output.
	function test_finite_diff(f::Function,x::Vector{Float64},tol=1e-6)

	end

	# do this for each dimension of x
	# low-level function doing the actual finite difference
	function finite_diff(f::Function,x::Vector)

	end

	function runAll()
		println("running tests:")
		include("test/runtests.jl")
		println("")
		println("JumP:")
		tab1 = table_JuMP()
		println("")
		println("NLopt:")
		tab2 = table_NLopt()
		println("RESULTS JUMP: ")
		println("-------------")
		display(tab1)
		println("RESULTS NLOPT : ")
		println("-------------")
		display(tab2)
		#ok = input("enter y to close this session.")
		#if ok == "y"
		#quit()
		end

end
