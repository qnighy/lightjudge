#!/usr/bin/ruby --encoding=UTF-8
# -*- coding: utf-8 -*-
require "webrick"
require "erb"
require "./contests"
require "./pages"

class LJServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(*args)
    super if args.size>0
  end
  def get_instance(config, *options)
    initialize(config,*options)
    self
  end
  def do_GET(req,res)
    do_GETorPOST(req,res,true)
  end
  def do_POST(req,res)
    do_GETorPOST(req,res,false)
  end
  def make403(res)
    res.content_type = "text/plain"
    res.body = "403 Forbidden\n"
    raise WEBrick::HTTPStatus::Forbidden
  end
  def make404(res)
    res.content_type = "text/plain"
    res.body = "404 Not Found\n"
    raise WEBrick::HTTPStatus::NotFound
  end
  def makeRedirect(res,path)
    res.set_redirect(WEBrick::HTTPStatus::Found, path)
  end
  def do_GETorPOST(req,res,is_get)
    if req.path =~ /\A\/([a-zA-Z0-9\-_]+)(\/.*)\z/
      contest_name,path = $1,$2
      contest = $contests[contest_name]
      if contest
        teamid = req.cookies.find{|c| c.name=="teamid" }.value.to_i rescue -1
        passwd = req.cookies.find{|c| c.name=="passwd" }.value rescue ""
        logged_in = (contest.teams[teamid.to_s][0] == passwd) rescue false
        unless logged_in
          teamid = passwd = nil
        end
        case path
        when is_get && "/"
          logged_in or makeRedirect(res,"/#{contest_name}/login")
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:top).get
        when is_get && "/teamlist"
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:teamlist).get
        when is_get && "/standings"
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:standings).get
        when is_get && "/login"
          !logged_in or makeRedirect(res,"/#{contest_name}/")
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:login).get
        when is_get && "/register"
          !logged_in or makeRedirect(res,"/#{contest_name}/")
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:register).get
        when is_get && "/problems"
          logged_in or makeRedirect(res,"/#{contest_name}/login")
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:problems).get
        when is_get && "/workplace"
          logged_in or makeRedirect(res,"/#{contest_name}/login")
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:workplace).get
        when is_get && /\A\/result\/([0-9]+)\z/
          res.content_type = "text/html"
          res.body = Page.new(contest,teamid,:result,$1.to_i).get
        when is_get && /\A\/input\/([A-Z])-([1234])\z/
          logged_in or makeRedirect(res,"/#{contest_name}/login")
          if File.exists?("contests/#{contest_name}/io/#$1#$2")
            res.content_type = "text/plain"
            res["Content-Disposition"] = "attachment; filename=\"#$1-#$2\""
            res.filename = "#$1-#$2"
            res.body = File.read("contests/#{contest_name}/io/#$1#$2")
          else
            make404(res)
          end
        when !is_get && "/login"
          !logged_in or makeRedirect(res,"/#{contest_name}/")
          teamidQ = req.query["teamid"].to_i rescue -1
          passwdQ = req.query["passwd"] rescue ""
          c1 = WEBrick::Cookie.new("teamid", teamidQ.to_s)
          c2 = WEBrick::Cookie.new("passwd", passwdQ.to_s)
          c1.max_age = 5 * 60 * 60
          c2.max_age = 5 * 60 * 60
          c1.path = "/#{contest_name}"
          c2.path = "/#{contest_name}"
          res.cookies << c1
          res.cookies << c2
          res.set_redirect(WEBrick::HTTPStatus::Found, "/#{contest_name}/")
        when !is_get && "/logout"
          logged_in or makeRedirect(res,"/#{contest_name}/login")
          c1 = WEBrick::Cookie.new("teamid", "-1")
          c2 = WEBrick::Cookie.new("passwd", "")
          c1.max_age = 5 * 60 * 60
          c2.max_age = 5 * 60 * 60
          c1.path = "/#{contest_name}"
          c2.path = "/#{contest_name}"
          res.cookies << c1
          res.cookies << c2
          makeRedirect(res,"/#{contest_name}/login")
        when !is_get && "/register"
          begin
            teamname = req.query["teamname"].gsub(/[^ -~]/, "")
            univname = req.query["univname"].gsub(/[^ -~]/, "")
            team = contest.addTeam(teamname,univname)
            page = Page.new(contest,teamid,:registered,team)
            res.content_type = "text/html"
            res.body = page.get; return
          rescue
            $stderr.puts ([$!.message]+$!.backtrace).join("\n")
            makeRedirect(res,"/#{contest_name}/register")
          end
        when !is_get && "/workplace"
          logged_in or makeRedirect(res,"/#{contest_name}/login")
          req.query["answer"].instance_variables.each do|var|
            p [var,req.query["answer"].instance_variable_get(var)]
          end
          result = contest.addSubmission(teamid,
            req.query["problem"].to_s || nil,
            req.query["answer"].to_s || nil,
            req.query["program"].to_s || nil)
          makeRedirect(res,"/#{contest_name}/result/#{result}")
        else
          make404(res)
        end
      else
        make404(res)
      end
    else
      make404(res)
    end
  end
end

s = WEBrick::HTTPServer.new(
  :Port => 8080
)
s.mount('/static', WEBrick::HTTPServlet::FileHandler, './static')
s.mount("/", LJServlet.new)
trap("INT") { s.shutdown }
s.start


