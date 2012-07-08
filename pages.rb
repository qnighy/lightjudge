# -*- coding: utf-8 -*-

class Page
  def initialize(contest,teamid, type, *options)
    @contest = contest
    @teamid = teamid
    @type = type
    @options = options
  end
end

ERB.new(File.read("templates/main.erb"), 0, "%-").def_method(Page, "get", "templates/main.erb")
ERB.new(File.read("templates/teamlist.erb"), 0, "%-").def_method(Page, "get_teamlist", "templates/teamlist.erb")
ERB.new(File.read("templates/standings.erb"), 0, "%-").def_method(Page, "get_standings", "templates/standings.erb")
ERB.new(File.read("templates/login.erb"), 0, "%-").def_method(Page, "get_login", "templates/login.erb")
ERB.new(File.read("templates/register.erb"), 0, "%-").def_method(Page, "get_register", "templates/register.erb")
ERB.new(File.read("templates/registered.erb"), 0, "%-").def_method(Page, "get_registered", "templates/registered.erb")
ERB.new(File.read("templates/top.erb"), 0, "%-").def_method(Page, "get_top", "templates/top.erb")
ERB.new(File.read("templates/problems.erb"), 0, "%-").def_method(Page, "get_problems", "templates/problems.erb")
ERB.new(File.read("templates/workplace.erb"), 0, "%-").def_method(Page, "get_workplace", "templates/workplace.erb")
ERB.new(File.read("templates/result.erb"), 0, "%-").def_method(Page, "get_result", "templates/result.erb")

