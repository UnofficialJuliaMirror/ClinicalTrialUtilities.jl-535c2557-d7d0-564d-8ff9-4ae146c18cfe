module CTPSS
__precompile__(true)
using Distributions
using Rmath
using QuadGK
#using SpecialFunctions
import SpecialFunctions.gamma
include("OwensQ.jl")

export sampleSize
export OwensQ

    const ZDIST = Normal()

    function sampleSize(;param="mean", type="ea", group="one", alpha=0.05, beta=0.2, diff=0, sd=0, a=0, b=0, k=1)

        if alpha >= 1 || alpha <= 0 || beta >= 1 || beta <= 0 return false end
        if (type == "ei" || type == "ns") && diff == 0 return false end
        if sd == 0 && param == "mean" return false end
        if k == 0 return false end
        if param == "mean"
            if group == "one"
                if type == "ea"
                    OneSampleMeanEquality(a, b, sd, alpha=alpha, beta=beta)
                elseif type == "ei"
                    OneSampleMeanEquivalence(a, b, sd, diff, alpha=alpha, beta=beta)
                elseif type == "ns"
                    OneSampleMeanNS(a, b, sd, diff, alpha=alpha, beta=beta)
                else return false end
            elseif group == "two"
                if type == "ea"
                    TwoSampleMeanEquality(m0, m1, sd, alpha=alpha, beta=beta, k=k)
                elseif type == "ei"
                    TwoSampleMeanEquivalence(m0, m1, sd, diff, alpha=alpha, beta=beta, k=k)
                elseif type == "ns"
                    TwoSampleMeanNS(m0, m1, sd, diff, alpha=alpha, beta=beta, k=k)
                else return false end
            else return false end
        elseif param == "prop"
            if group == "one"
                if type == "ea"
                elseif type == "ei"
                elseif type == "ns"
                else return false end
            elseif group == "two"
                if type == "ea"
                elseif type == "ei"
                elseif type == "ns"
                else return false end
            else return false end
        elseif param == "or"
            if type == "ea"
            elseif type == "ei"
            elseif type == "ns"
            else return false end
        else return false end
    end

    #Ref: Chow S, Shao J, Wang H. 2008. Sample Size Calculations in Clinical Research. 2nd Ed. Chapman & Hall/CRC Biostatistics Series.

    #Sample Size
    #Compare Means
    #One Sample
    # m0 = μ0; m1 = μ
    function OneSampleMeanEquality(m0, m1, sd; alpha=0.05, beta=0.2)
        return ((quantile(ZDIST, 1-alpha/2) + quantile(ZDIST, 1-beta))*sd/(m1-m0))^2
    end

    function OneSampleMeanEquivalence(m0, m1, sd, diff; alpha=0.05, beta=0.2)
        return (sd*(quantile(ZDIST, 1-alpha) + quantile(ZDIST, 1 - beta/2))/(diff-abs(m1-m0)))^2
    end

    function OneSampleMeanNS(m0, m1, sd, diff; alpha=0.05, beta=0.2) #Non-inferiority / Superiority
        return (sd*(quantile(ZDIST, 1-alpha) + quantile(ZDIST, 1 - beta))/(m1 - m0 - diff))^2
    end
    #Two Sample
    # m0 = μA - Group A; m1 = μB - Group B
    function TwoSampleMeanEquality(m0, m1, sd; alpha=0.05, beta=0.2, k=1)
        return (1+1/k)*((quantile(ZDIST, 1-alpha/2) + quantile(ZDIST, 1-beta))*sd/(m0-m1))^2
    end

    function TwoSampleMeanEquivalence(m0, m1, sd, diff; alpha=0.05, beta=0.2, k=1)
        return (1+1/k)*(sd*(quantile(ZDIST, 1-alpha) + quantile(ZDIST, 1 - beta/2))/(abs(m0-m1)-diff))^2
    end

    function TwoSampleMeanNS(m0, m1, sd, diff; alpha=0.05, beta=0.2, k=1) #Non-inferiority / Superiority

        return (1+1/k)*(sd*(quantile(ZDIST, 1-alpha) + quantile(ZDIST, 1 - beta))/(m0 - m1 - diff))^2
    end

    #Compare Proportion
    #One Sample

    function OneProportionEquality(p0, p1; alpha=0.05, beta=0.2)
        return p1*(1-p1)*((quantile(ZDIST, 1-alpha/2)+quantile(ZDIST, 1 - beta))/(p1-p0))^2
    end

    function OneProportionEquivalence(p0, p1, diff; alpha=0.05, beta=0.2)
        return p1*(1-p1)*((quantile(ZDIST, 1-alpha)+quantile(ZDIST, 1 - beta/2))/(abs(p1-p0)-diff))^2
    end

    function OneProportionNS(p0, p1, diff; alpha=0.05, beta=0.2)
        return p1*(1-p1)*((quantile(ZDIST, 1-alpha)+quantile(ZDIST, 1 - beta))/(p1-p0-diff))^2
    end

    #Two Sample

    function TwoProportionEquality(p0, p1; alpha=0.05, beta=0.2, k=1)
        return (p1*(1-p1)/k+p0*(1-p0))*((quantile(ZDIST, 1-alpha/2)+quantile(ZDIST, 1 - beta))/(p1-p0))^2
    end

    function TwoProportionEquivalence(p0, p1, diff; alpha=0.05, beta=0.2, k=1)
        return (p1*(1-p1)/k+p0*(1-p0))*((quantile(ZDIST, 1-alpha)+quantile(ZDIST, 1 - beta/2))/(abs(p1-p0)-diff))^2
    end

    function TwoProportionNS(p0, p1, diff; alpha=0.05, beta=0.2, k=1)
        return (p1*(1-p1)/k+p0*(1-p0))*((quantile(ZDIST, 1-alpha)+quantile(ZDIST, 1 - beta))/(p1-p0-diff))^2
    end

    function OREquality(p0, p1; alpha=0.05, beta=0.2, k=1)
        OR=p1*(1-p0)/p0/(1-p1)
        return (1/k/p1/(1-p1)+1/p0/(1-p0))*((quantile(ZDIST, 1-alpha/2)+quantile(ZDIST, 1 - beta))/log(OR))^2
    end

    function OREquivalence(p0, p1, diff; alpha=0.05, beta=0.2, k=1, logdiff=true)
        if !logdiff diff=log(diff) end
        OR=p1*(1-p0)/p0/(1-p1)
        return (1/k/p1/(1-p1)+1/p0/(1-p0))*((quantile(ZDIST, 1-alpha)+quantile(ZDIST, 1 - beta/2))/(log(OR)-diff))^2
    end

    function ORNS(p0, p1, diff; alpha=0.05, beta=0.2, k=1, logdiff=true)
        if !logdiff diff=log(diff) end
        OR=p1*(1-p0)/p0/(1-p1)
        return (1/k/p1/(1-p1)+1/p0/(1-p0))*((quantile(ZDIST, 1-alpha)+quantile(ZDIST, 1 - beta))/(log(OR)-diff))^2
    end

    function OwensQ(nu, t, delta, a, b)
        if a==b return(0) end

        if nu < 29 && abs(delta) > 37.62
            if isinf(b)
                return quadgk(x -> ifun1(x, nu, t, delta), 0, 1)[1]
            else
                return OwensQo(nu,t,delta,0,b) #not impl
            end
        else
            if isinf(b)
                #45 of OwensQ
                return cdf(NoncentralT(nu,delta),t)
            else
                integral = quadgk(x -> ifun1(x,nu,t,delta, b=b), 0, 1)[1]
                #58 of OwensQ
                return cdf(NoncentralT(nu,delta),t)-integral
            end
        end

    end #OwensQ

end # module
