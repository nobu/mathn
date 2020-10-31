# frozen_string_literal: false
require "mkmf"

if have_func("nurat_canonicalization")
  create_makefile "mathn/rational"
end
