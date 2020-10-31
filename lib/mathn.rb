# frozen_string_literal: false
#--
# $Release Version: 0.5 $
# $Revision: 1.1.1.1.4.1 $

##
# = mathn
#
# mathn serves to make mathematical operations more precise in Ruby
# and to integrate other mathematical standard libraries.
#
# Without mathn:
#
#   3 / 2 => 1 # Integer
#
# With mathn:
#
#   3 / 2 => 3/2 # Rational
#
# mathn keeps value in exact terms.
#
# Without mathn:
#
#   20 / 9 * 3 * 14 / 7 * 3 / 2 # => 18
#
# With mathn:
#
#   20 / 9 * 3 * 14 / 7 * 3 / 2 # => 20
#
#
# When you require 'mathn', the libraries for Prime, CMath, Matrix and Vector
# are also loaded.
#
# == Copyright
#
# Author: Keiju ISHITSUKA (SHL Japan Inc.)
#--
# class Numeric follows to make this documentation findable in a reasonable
# location

require "cmath.rb"
# require "matrix.rb"
# require "prime.rb"

module Math::N
  refine Complex do
    def canonicalize
      if imag.zero?
        real
      else
        self
      end
    end
  end

  refine Rational do
    def canonicalize
      if denominator == 1
        numerator
      else
        self
      end
    end
  end

  using self

  module Canonicalization
    def +(other)
      super.canonicalize
    end

    def -(other)
      super.canonicalize
    end

    def *(other)
      super.canonicalize
    end

    def /(other)
      super.canonicalize
    end

    def **(other)
      super.canonicalize
    end
  end

  refine Complex do
    include Canonicalization
  end

  refine Rational do
    include Canonicalization
  end

  ##
  # Enhance Integer's division to return more precise values from
  # mathematical expressions.
  #
  #   require 'mathn'
  #   2/3*3  # => 0
  #   using Math::N
  #   2/3*3  # => 2
  #
  #   (2**72) / ((2**70) * 3)  # => 4/3

  refine Integer do
    ##
    # +/+ defines the Rational division for Integer.
    #
    #   (2**72) / ((2**70) * 3)  # => 4/3

    def /(other)
      quo(other).canonicalize
    end
  end

  ##
  # Standard Math module behaviour:
  #   Math.sqrt(4/9)     # => 0.0
  #   Math.sqrt(4.0/9.0) # => 0.666666666666667
  #   Math.sqrt(- 4/9)   # => Errno::EDOM: Numerical argument out of domain - sqrt
  #
  # When using 'Math::N', this is changed to:
  #
  #   require 'mathn'
  #   using Math::N
  #   Math.sqrt(4/9)      # => 2/3
  #   Math.sqrt(4.0/9.0)  # => 0.666666666666667
  #   Math.sqrt(- 4/9)    # => Complex(0, 2/3)

  refine Math do
    alias sqrt! sqrt

    ##
    # Computes the square root of +a+.  It makes use of Complex and
    # Rational to have no rounding errors if possible.
    #
    #   Math.sqrt(4/9)      # => 2/3
    #   Math.sqrt(- 4/9)    # => Complex(0, 2/3)
    #   Math.sqrt(4.0/9.0)  # => 0.666666666666667

    def sqrt(a)
      if a.kind_of?(Complex)
        sqrt!(a)
      elsif a.respond_to?(:nan?) and a.nan?
        a
      elsif a >= 0
        rsqrt(a)
      else
        Complex(0,rsqrt(-a))
      end
    end

    ##
    # Compute square root of a non negative number. This method is
    # internally used by +Math.sqrt+.

    def rsqrt(a) # :nodoc:
      if a.kind_of?(Float)
        sqrt!(a)
      elsif a.kind_of?(Rational)
        rsqrt(a.numerator)/rsqrt(a.denominator)
      else
        src = a
        max = 2 ** 32
        byte_a = [src & 0xffffffff]
        # ruby's bug
        while (src >= max) and (src >>= 32)
          byte_a.unshift src & 0xffffffff
        end

        answer = 0
        main = 0
        side = 0
        for elm in byte_a
          main = (main << 32) + elm
          side <<= 16
          if answer != 0
            if main * 4  < side * side
              applo = main.div(side)
            else
              applo = ((sqrt!(side * side + 4 * main) - side)/2.0).to_i + 1
            end
          else
            applo = sqrt!(main).to_i + 1
          end

          while (x = (side + applo) * applo) > main
            applo -= 1
          end
          main -= x
          answer = (answer << 16) + applo
          side += applo * 2
        end
        if main == 0
          answer
        else
          sqrt!(a)
        end
      end
    end

    module_function :sqrt
    module_function :rsqrt
  end
end
