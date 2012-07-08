@problems = %w[Y Z]
@starttime = Time.local(2012, 7, 7, 16, 30, 0, 0)
# @endtime = @starttime + 3 * 60 * 60


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
