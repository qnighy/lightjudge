# -*- coding: utf-8 -*-

require "yaml"
require "fileutils"
require "digest/md5"

$messages = YAML.load_file("messages.yml")
def generatePassword
  chars=("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  (1..10).map{ chars.sample }.join
end

def YAML.transaction(filename, default = {}, &block)
  File.open(filename, File::RDWR|File::CREAT) do|file|
    file.flock(File::LOCK_EX)
    yaml = YAML.load(file.read) || default
    begin
      block.call(yaml)
    ensure
      file.rewind
      file.write(YAML.dump(yaml))
      file.flush
      file.truncate(file.pos)
    end
  end
end
def YAML.transactionRead(filename, default = {}, &block)
  File.open(filename, "r") do|file|
    file.flock(File::LOCK_SH)
    yaml = YAML.load(file.read) || default
    block.call(yaml)
  end
rescue
  block.call(default)
end

class Contest
  attr_reader :name, :dir, :lastmod, :problems
  def initialize(name)
    @name = name
    @dir = "contests/#@name/"
    @lastmod = File.mtime("#@dir/config.rb")
    @problems = []
    eval(File.read("#@dir/config.rb"))
    @problems = @problems.select{|s| s =~ /\A[A-Z]\z/}
  end
  def teams
    YAML.transactionRead("#@dir/teams.yml", {}) do|teams|
      return teams
    end
  end
  def addTeam(teamname,univname)
    passwd = generatePassword()
    YAML.transaction("#@dir/teams.yml", {}) do|teams|
      teamid = (teams.keys.map(&:to_i)+[0]).max+1
      teams[teamid.to_s] = [passwd, teamname, univname]
      return [teamid, passwd, teamname, univname]
    end
  end
  def submissions
    YAML.transactionRead("#@dir/submissions.yml", {}) do|submissions|
      return submissions
    end
  end
  def getTeamScore(teamid, submissions=submissions)
    a = [0,0]
    @problems.each do|probid|
      status = getStatus(teamid.to_i,probid,submissions)
      if status[0] == 2
        a[0] += 1
        a[1] += status[1]
      end
    end
    return a
  end
  def getStatus(teamid, probid, submissions=submissions)
    submissionsA = submissions.find_all{|id,subm|
      subm["teamid"] == teamid &&
        subm["probid"] == probid
    }
    wrongs = submissionsA.count{|id,subm|
      !subm["correct"]
    }
    acc = submissionsA.find{|id,subm| subm["accepted"] }
    if acc
      return [2,wrongs*20 + (acc[1]["time"] - @starttime.to_i)]
    end
    dataid = getDataID(teamid,probid,submissions)
    dataid or return [3,0]
    last = submissionsA.find{|id,subm|
      subm["dataid"] == dataid-1 &&
        subm["correct"]
    }
    last or return [0,0]
    return [1,0]
  end
  def getDataID(teamid, probid, submissions=submissions)
    submissionsA = submissions.find_all{|id,subm|
      subm["teamid"] == teamid &&
        subm["probid"] == probid
    }
    submissionsB = submissionsA.find_all{|id,subm|
        subm["correct"]
    }
    dataid1 = submissionsB.map{|id,subm| subm["dataid"] }.max+1 rescue 1
    return nil if dataid1 >= 5
    return nil if dataid1 == 4 && submissionsA.any?{|id,subm|
      subm["dataid"] == 4 && !subm["accepted"]
    }
    return nil if submissionsA.any?{|id,subm|
      subm["accepted"]
    }
    return dataid1
  end
  def addSubmission(teamid,probid,outdata,program)
    YAML.transaction("#@dir/submissions.yml", {}) do|submissions|
      dataid = getDataID(teamid,probid,submissions)
      dataid or raise "Submission for this problem not allowed"
      subm_id = (submissions.keys.map(&:to_i)+[0]).max+1
      FileUtils.mkdir_p("contests/#@name/submissions")
      File.open("contests/#@name/submissions/output%04d" % subm_id, "wb") do|file|
        file.write outdata
      end
      File.open("contests/#@name/submissions/program%04d" % subm_id, "wb") do|file|
        file.write program
      end
      program_digest = Digest::MD5.hexdigest(program)
      is_correct = self.send("check_#{probid}",
        "contests/#@name/io/#{probid}#{dataid}",
        "contests/#@name/submissions/output%04d" % subm_id,
        "contests/#@name/io/#{probid}#{dataid}.ans"
      ) rescue false
      submissionsC = submissions.find_all{|id,subm|
        subm["teamid"] == teamid &&
          subm["probid"] == probid &&
          subm["dataid"] == dataid
      }
      submissionsD = submissions.find_all{|id,subm|
        subm["teamid"] == teamid &&
          subm["probid"] == probid &&
          subm["dataid"] == dataid-1
      }
      is_different = submissionsD.any? {|id,subm|
        subm["correct"] &&
          subm["program_digest"] != program_digest
      }
      is_accepted = is_correct && submissionsD.any? {|id,subm|
        subm["correct"] &&
          subm["program_digest"] == program_digest
      } && submissionsC.all? {|id,subm|
        subm["correct"]
      }
      submissions[subm_id] = {
        "teamid" => teamid,
        "probid" => probid,
        "dataid" => dataid,
        "program_digest" => program_digest,
        "time" => Time.now.to_i,
        "correct" => is_correct,
        "accepted" => is_accepted
      }
      next_dataid = getDataID(teamid,probid,submissions)
      if is_correct
        if is_accepted
          return 0
        elsif !next_dataid
          return 3
        elsif is_different
          return 4
        elsif dataid != 1
          return 2
        else
          return 1
        end
      else
        if !next_dataid
          return 12
        elsif dataid != 1
          return 11
        else
          return 10
        end
      end
    end
  end
  ("A".."Z").each do|probid|
    define_method("check_#{probid}") do|input,output,expect|
      output_data = File.read(output).gsub("\r","")
      expect_data = File.read(expect).gsub("\r","")
      output_data == expect_data
    end
  end
end

class Contests
  def initialize
    @preloaded_hash = {}
    Dir.new("contests").select{|i| i =~ /[a-zA-Z0-9\-_]+/ }.each do|idx|
      begin
        @preloaded_hash[idx] = Contest.new(idx)
      rescue SecurityError
        $stderr.puts ([$!.message]+$!.backtrace).join("\n")
      rescue
        $stderr.puts ([$!.message]+$!.backtrace).join("\n")
      end
    end
  end
  @@mutex = Mutex.new
  def [](idx)
    @@mutex.synchronize do
      begin
        if !@preloaded_hash[idx] || @preloaded_hash[idx].lastmod < File.mtime("contests/#{idx}/config.rb")
          @preloaded_hash[idx] = Contest.new(idx)
        end
        return @preloaded_hash[idx]
      rescue SecurityError
        $stderr.puts ([$!.message]+$!.backtrace).join("\n")
        @preloaded_hash.delete(idx)
        return nil
      rescue
        $stderr.puts ([$!.message]+$!.backtrace).join("\n")
        @preloaded_hash.delete(idx)
        return nil
      end
    end
  end
end

$contests = Contests.new

