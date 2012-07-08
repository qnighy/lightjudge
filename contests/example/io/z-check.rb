#!/usr/bin/ruby

require "scanf"

def check_Z(input,output,expect)
  File.open(output,"r") do|output_f|
    File.open(expect,"r") do|expect_f|
      loop do
        a, = output_f.scanf("%f")
        b, = expect_f.scanf("%f")
        a or return true
        b or return false
        (a-b).abs < 1e-7 or return false
      end
    end
  end
end

p check_Z(*ARGV)

