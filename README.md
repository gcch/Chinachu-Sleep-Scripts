# Chinachu Sleep Scripts (β)

## Overview
Chinachu サーバをスリープさせる際に必要なスクリプトと Chinachu REST API 経由で (一部の必要な) 情報を取得するスクリプト、そしてこれらを導入するためのスクリプトをまとめたもの。

動作はしますが、気になったところをちょこちょこ弄っているので、永遠にβ版かも。


## Description
世界一キュートなテレビ録画管理アプリ [Chinachu](https://chinachu.moe/) ([GitHub](https://github.com/kanreisa/Chinachu)) を使ってみたところ、Chinachu 自体の見た目は非常に素晴らしいと感じたのだが、以前から使用している Windows 環境での EpgTimer (EpgDataCap_Bon) と比べ、機能が少なめ、というか抑えられている (もちろん、Chinachu の思想、環境の違いでもあるとは思うが) ので、とりあえず視聴および録画をしていない時には、電気代の節約のためにスリープする機能だけでも用意しようと、いろいろなページを参考 (後述) にしつつ、Chinachu の簡単インストールを見習い、(比較的) お手軽に導入できるスリープ環境構築スクリプトを作ってみた。

現時点では S4 (ハイバネーション) 仕様。  
(というか、使ったマシンが S5 からの起動に対応してなかったため。)

動作としては、root 権限で cron で chinachu-check-status を走らせ、

* Chinachu WUI に誰かアクセスしていないか
* Chinachu が番組を録画していないか
* Chinachu がもうそろそろ録画を開始しようとしていないか
* Chinachu サーバが起動したばかりではないか
  * 完全停止 (S5)、ハイバネーション (S4)、スリープ (S3) 復帰時後のいずれの場合にも機能します。
* Samba 経由で Chinachu サーバにアクセスしているユーザはいないか
  * Samba が構築されている環境のみ機能します。
* Chinachu サーバにログインしているユーザはいないか

をチェックし、全て問題なければ、次の番組の少し前 (マージン設定可能) に起動タイマをセットし、ハイバネーションする。

また、指定した時間に、強制的に EPG 取得を行う機能も盛り込んだ。 (これも cron を使用。Chinachu をインストールしたユーザで実行。)

が、少し想定とは違う動作をしている。
正確には、タイミングによっては想定通りの動作をするが、(Chinachu の EPG 取得サイクルを超えて) 長期間電源が停止していた後 に、起動した直後に自動的に取得が行われるため、指定時刻より前に取得が開始される。とりあえず目標は達成できているのでよしとしておく。


## Testing environment
マシンは放置されていた EPSON Endeavor ST125E (Core 2 Duo P8700, 4GB RAM)。全く関係ない話だけど、エンコ能力が皆無に等しいので (放送波のリアルタイムノーエンコード以外の) ストリーミングは無理。

そして OS は CentOS 7 (x86-64)。

    $ cat /etc/centos-release
    CentOS Linux release 7.1.1503 (Core)

Minimal でインストールしたけど、いろいろと入れたのでもうよくわかんない。

また、別の環境の場合は、適当に読み替えてください。


## Components

### About scripts
今回登場するスクリプトたち。  
Linux についてわからないことだらけであることもあって、微妙なところもあるかもですが、直して頂ければと。
<dl>
    <dt>install.sh</dt>
    <dd>インストールスクリプト</dd>

    <dt>chinachu-sleep.sh</dt>
    <dd>次回起動時刻設定スクリプト<br />
        スリープ (ハイバネーション・サスペンド) 時および復帰時に実行される。<br />
        pm-utils、systemd のいずれにも使えるようになっている。</dd>

    <dt>chinachu-check-status.sh</dt>
    <dd>スリープ状態判定用スクリプト<br />
        追加で判定したいことがある場合には、この中に追記していく形になる。<br />
        スリープ可能状態のとき、正常終了 (0) となる。</dd>

    <dt>chinachu-api-get-connected-count.py</dt>
    <dd>Chinachu WUI アクセスユーザ数取得スクリプト<br />
        引数として、Chinachu WUI の URL を渡す必要あり。<br />
        WUI へのアクセスユーザ数が出力される。</dd>

    <dt>chinachu-api-get-next-time.py</dt>
    <dd>Chinachu 次回予約番組開始時刻取得スクリプト<br />
        引数として、Chinachu WUI の URL を渡す必要あり。<br />
        次に録画が予定されている番組の開始時刻が、UNIX タイムで出力される。</dd>

    <dt>chinachu-api-is-recording.py</dt>
    <dd>Chinachu 録画状態取得スクリプト<br />
        引数として、Chinachu WUI の URL を渡す必要あり。<br />
        録画中であるとき、正常終了 (0) となる。</dd>
</dl>

### About settings
設定の設定方法および設定項目に関して。  
``settings.sample`` を利用して設定するか、``install.sh`` を実行し、ガイドに従いながら入力する。  
推奨は前者。一応ファイル内に、(稚拙な) 英語で説明は書いてあるが、それでは伝わらない可能性があるので、日本語でも。   
後者のガイドに従いながらするパターンに関しては、下記設定項目と設定順序は一致しているので、上手く読んで欲しい。

設定項目:

    0                           # 電源管理の方法 (0: pm-utils / 1: systemd)
    chinachu                    # Chianchu をインストールしたユーザ (正確には、EPG 取得用 cron を実行するユーザ)
    /home/chinachu/chinachu     # Chinachu のインストールディレクトリ
    http://localhost:20772      # Chinachu WUI のアドレス (最後に "/" はつけないこと。認証なしの wuiOpenPort じゃないとダメ。)
    10                          # スリープ移行チェック (cron) を実行する周期 [分]
    600                         # スリープ状態から起動する際、録画開始よりどの程度前に起動するか [秒]
    900                         # 起動後、スリープに移行しない期間 [秒]
    3600                        # 次の録画が迫っている場合、どの程度の時間なら起動したまま待たせるか [秒]
    05:55 17:55                 # EPG 取得を行う時刻 (スペース or カンマ区切りで複数指定可能)


## Usage
環境によるが、Python 3.x は必須。pm-utils を使うならそれも。  
後から systemd でもできることを知ったので、CentOS 7 だけど、pm-utils を使っている。  
一応、systemd にも対応できるようにしたつもりだが、上手く動くかは試してないので知らない(笑)

時間の判定をするために date コマンドを多用していることもあって、GNU date じゃないと動かない (はず)。

Python 3.x のインストールはこんな感じ。

    # cd /usr/local/src
    # wget https://www.python.org/ftp/python/3.4.3/Python-3.4.3.tgz
    # tar zxvf Python-3.4.3.tgz
    # cd Python-3.4.3
    # ./configure --prefix=/usr/local/python-3.4
    # make
    # make install
    # vi /etc/profile
    # source /etc/profile

<dl>
    <dt>Add the below line to /etc/profile:</dt>
    <dd>export PATH=/usr/local/python-3.4/bin:$PATH</dd>
</dl>

pm-utils のインストール

    # yum install pm-utils

必要なパッケージの導入が済んだので、本題の方に。  
まず、作業フォルダに移動。

    # cd /usr/local/src

クローン。

    # git clone --depth 1 https://github.com/gcch/Chinachu-Sleep-Scripts.git ./chinachu-ss

移動。

    # cd chinachu-ss/

設定ファイルを弄る。 (詳細は中身を参照。)

    # cp settings.sample settings
    # vi settings

インストールを開始する。

    # chmod +x install.sh
    # ./install.sh < settings

で、おしまい。
設定を変えたいときは、もう一度インストールをすればいい。

動作確認は、下記コマンドを実行してみて、エラーがなく動作、設定が反映されていればスクリプト自体は問題ない。
最終的には、マシンが勝手にスリープし、録画前 or EPG 取得時刻前に自動起動すれば OK かと。

    # /etc/pm/sleep.d/81chinachu-sleep test1               # スリープ時の動作テスト (pm-utils)
    # /etc/pm/sleep.d/81chinachu-sleep test2               # スリープ回復時の動作テスト (pm-utils)
    # /usr/lib/systemd/system-sleep/chinachu-sleep test1   # スリープ時の動作テスト (systemd)
    # /usr/lib/systemd/system-sleep/chinachu-sleep test2   # スリープ回復時の動作テスト (systemd)
    # chinachu-check-status                                # スリープ移行可能状態チェック
    # crontab -l                                           # cron への登録状況の確認 (スリープコマンド)
    # crontab -l -u <chinachu-username>                    # cron への登録状況の確認 (Chinachu の EPG 取得コマンド)

---

SSH 経由の sudo だと、PATH が引き継がれず、Python 3.x をインストールしていても、「そんなのない！」と言われる場合があります。

    $ sudo ./install.sh < settings
    python3 is not found.

その時には、下記のように実行してみてください。

    $ export PATH=$PATH
    $ sudo PATH=$PATH ./setup.sh < settings


## References
参考にさせて頂いたサイト。
* [chinachu + pm-utils で自動起動 | haruo31's blog](http://haruo31.underthetree.jp/2013/09/04/chinachu-pm-utils-%E3%81%A7%E8%87%AA%E5%8B%95%E8%B5%B7%E5%8B%95/)
* [録画サーバー用スクリプト (GitHub Gist)](https://gist.github.com/jtwp470/ca92c6a7b3d1c819acdc)
* [サスペンドとハイバネート - ArchWiki](https://wiki.archlinuxjp.org/index.php/%E3%82%B5%E3%82%B9%E3%83%9A%E3%83%B3%E3%83%89%E3%81%A8%E3%83%8F%E3%82%A4%E3%83%90%E3%83%8D%E3%83%BC%E3%83%88)
* [電源管理 - ArchWiki](https://wiki.archlinuxjp.org/index.php/%E9%9B%BB%E6%BA%90%E7%AE%A1%E7%90%86)
* [ACPI Wakeup - MythTV Official Wiki](https://www.mythtv.org/wiki/ACPI_Wakeup)

## License
This script is released under the MIT license. See the LICENSE file.


## Author
* tag (Twitter: [@tag_ism](https://twitter.com/tag_ism "tag (@tag_ism) | Twitter") / Blog: http://karat5i.blogspot.jp/)
