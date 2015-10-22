# Chinachu Sleep Scripts
*現在、改良途中のため、正常に動作しない可能性があります。 (These scripts are under development now.)*

## Overview
Chinachu サーバをスリープさせるためのスクリプトと Chinachu REST API の情報を取得するスクリプト、そしてこれらを導入するためのスクリプトをまとめたもの。


## Description
[Chinachu](https://chinachu.moe/) ([GitHub](https://github.com/kanreisa/Chinachu)) を使っている中で、やっぱりスリープしたい思いが強くなったので、いろいろなページを参考 (後述) にしつつ、Chinachu の簡単インストールを見習い、(比較的) お手軽に導入できるスリープ環境構築スクリプトを作ってみた。

現時点では S4 (ハイバネーション) 仕様。  
(というか、使ったマシンが S5 からの起動に対応してなかったため。)

Chinachu サーバをスリープさせる際に、

* Chinachu WUI に誰かアクセスしていないか
* Chinachu が番組を録画していないか
* Chinachu がもうそろそろ録画を開始しようとしていないか
* Chinachu サーバが起動したばかりではないか
* Chinachu サーバにログインしているユーザはいないか
* (Samba が構築されている環境では) Samba 経由で Chinahcu サーバにアクセスしているユーザはいないか

をチェックし、全て問題なければ、次の番組の少し前 (マージン設定可能) に起動タイマをセットする。


## Testing environment
マシンは放置されていた EPSON Endeavor ST125E (Core 2 Duo P8600, 4GB RAM)。全く関係ない話だけど、リアルタイムストリーミングは無理。

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

    <dt>81chinachu-sleep.sh, chinachu-sleep.sh</dt>
    <dd>次回起動時刻設定スクリプト<br />
        スリープ (ハイバネーション・サスペンド) 時および復帰時に実行される。<br />
        前者が pm-utils 用、後者が systemd 用。やっていることは同じ。</dd>

    <dt>chinachu-check-status.sh</dt>
    <dd>スリープ状態判定用スクリプト<br />
        追加で判定したいことがある場合には、この中に追記していく形になる。<br />
        スリープ可能状態のとき、正常終了 (0) となる。</dd>

    <dt>chinachu-api-is-recording.py</dt>
    <dd>Chinachu 録画状態取得スクリプト<br />
        引数として、Chinachu WUI の URL を渡す必要あり。 (例: $ chinachu-is-recording <em>http://localhost:10772</em>)<br />
        録画中であるとき、正常終了 (0) となる。</dd>

    <dt>chinachu-api-get-next-time.py</dt>
    <dd>Chinachu 次回予約番組開始時刻取得スクリプト<br />
        引数として、Chinachu WUI の URL を渡す必要あり。 (例: $ chinachu-get-next-time <em>http://localhost:10772</em>)<br />
        次に録画が予定されている番組の開始時刻が、UNIX タイムで出力される。</dd>
</dl>

### About settings
設定に関して。  
ファイルは ``settings.sample`` を参考に設定するか、``install.sh`` を実行し、ガイドに従いながら入力する。  
推奨は前者。一応ファイル内に、(稚拙な) 英語で説明は書いてあるが、それでは伝わらない可能性があるので、日本語でも。   
後者のガイドに従いながらするパターンに関しては、下記内容と設定順序は一致しているので、上手く読んで欲しい。

    0                           # 電源管理の方法 (0: pm-utils / 1: systemd)
    http://localhost:10772      # Chinachu WUI のアドレス (最後に "/" はつけないこと)
    600                         # スリープ状態から起動する際、録画開始よりどの程度前に起動するか [秒]
    600                         # 起動後、スリープに移行しない期間 [秒]
    1800                        # 次の録画が迫っている場合、どの程度の時間なら起動したまま待たせるか [秒]
    5                           # スリープ移行チェック (cron) を実行する周期 [分]


## Usage
環境によるが、Python 3.x は必須。pm-utils を使うならそれも。  
後から systemd でもできることを知ったので、CentOS 7 だけど、pm-utils を使っている。  
一応、systemd にも対応できるようにしたつもりだが、上手く動くかは試してないので知らない(笑)

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

    # git clone https://github.com/gcch/Chinachu-Sleep-Scripts.git

移動。

    # cd Chinachu-Sleep-Scripts/

設定ファイルを弄る。 (詳細は中身を参照。)

    # cp settings.sample settings
    # vi settings

インストールを開始する。

    # chmod +x install.sh
    # ./install.sh < settings

で、おしまい。
設定を変えたいときは、もう一度インストールをすればいい。

---

SSH 経由の sudo だと、PATH が引き継がれず、Python 3.x をインストールしていても、「そんなのない！」と言われる場合があります。

    $ sudo ./install.sh < settings
    please install python 3.x.

その時には、下記のように実行してみてください。

    $ export PATH=$PATH
    $ sudo PATH=$PATH ./setup.sh < settings


## References
参考にさせて頂いたサイト。
* [chinachu + pm-utils で自動起動 | haruo31's blog](http://haruo31.underthetree.jp/2013/09/04/chinachu-pm-utils-%E3%81%A7%E8%87%AA%E5%8B%95%E8%B5%B7%E5%8B%95/)
* [録画サーバー用スクリプト (GitHub Gist)](https://gist.github.com/jtwp470/ca92c6a7b3d1c819acdc)
* [サスペンドとハイバネート - ArchWiki](https://wiki.archlinuxjp.org/index.php/%E3%82%B5%E3%82%B9%E3%83%9A%E3%83%B3%E3%83%89%E3%81%A8%E3%83%8F%E3%82%A4%E3%83%90%E3%83%8D%E3%83%BC%E3%83%88)
* [電源管理 - ArchWiki](https://wiki.archlinuxjp.org/index.php/%E9%9B%BB%E6%BA%90%E7%AE%A1%E7%90%86)


## License
This script is released under the MIT license. See the LICENSE file.


## Author
* tag (Twitter: [@tag_ism](https://twitter.com/tag_ism "tag (@tag_ism) | Twitter") / Blog: http://karat5i.blogspot.jp/)
