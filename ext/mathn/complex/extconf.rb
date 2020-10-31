# frozen_string_literal: false
require "mkmf"

if have_func("nucomp_canonicalization")
  create_makefile "mathn/complex"
end
