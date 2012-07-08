# LightJudge #

ICPC 国内予選 を練習するために作ってみたジャッジサーバーです。

特徴

- Ruby 1.9 さえあれば動く

注意

- スケーリングのことは何も考えていません。10チーム以内くらいの人数でひっそりやるくらいの状況を想定したので。
- まだ制作途中です。

## 実装済みの機能 ##

- ログイン・ユーザー登録
- 問題の閲覧
- 解答の提出
- 提出状況の概要の確認
- standingsの閲覧

## つかいかた ##

### Ruby のインストール ###

Linux, Macは知りません。適当にインストールしてください。

Windows の場合 RubyInstaller ( http://rubyinstaller.org/ ) がオススメです。

Ruby 1.9 を入れて下さい。手元の動作環境は1.9.3pl125でした。

!! **CygwinのRubyは1.8です** !! Cygwinはクソだな
!! **Mac OS X LionのプリインストールのRubyは1.8です** !! Mac OS X Lionはクソだな

### 起動 ###

    ruby lightjudge.rb

とやって起動したら、 http://localhost:8080/example/ を見に行って下さい。

!! **--encodingオプションが無いって言われたら→Ruby1.8を使っている可能性があります** !!

あとは適当にやってください。

### 編集 ###

contests/example/ を参考にしてがんばってください


