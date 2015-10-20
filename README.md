# Chinachu Sleep Scripts

## Overview
Chinachu サーバをスリープさせるためのスクリプトとそれを導入するためのスクリプトをまとめたもの。

## Description
[Chinachu](https://chinachu.moe/) ([GitHub](https://github.com/kanreisa/Chinachu)) を使っている中で、やっぱりスリープしたい思いが強くなったので、いろいろなページを参考 (後述) にしつつ、Chinachu の簡単インストールを見習い、お手軽に導入できるスリープ環境構築スクリプトを作ってみたというもの。

Chinachu サーバをスリープさせる際に、
* Chinachu サーバが起動したばかりではないか
* Chinachu が番組を録画しているか
* Chinachu がもうそろそろ録画を開始しようとしているか
* Chinachu サーバにログインしているユーザはいないか
をチェックし、全て問題なければ、次の番組の少し前 (マージン設定可能) に起動タイマをセットし、休止状態に入るようにしている。

他にもチェックすべきことは多々あるとは (個人的にも) 思っているが、とりあえずこんなところ。
(個人的に一番やりたいのは、Chinachu の Web UI にアクセスしているときにはスリープしないようにすることですかね。API 的には無理くさいけどね。)

## Testing environment
CentOS 7 (x86-64)。

    $ cat /etc/centos-release
    CentOS Linux release 7.1.1503 (Core)

Minimal でインストールしたけど、いろいろと入れたのでもうよくわかんない。

また、別の環境の場合は、適当に読み替えてください。

## File composition
後で書きます。

## Usage
環境によるが、Python 3.x は必須。pm-utils を使うならそれも。
後から systemd でもできることを知ったので、CentOS 7 だけど、pm-utils を使っている。
一応、systemd にも対応できるようにしたつもりだが、上手く動くかは知らない(笑)

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

/etc/profile:

    export PATH=/usr/local/python-3.4/bin:$PATH

pm-utils のインストール

    # yum install pm-utils

必要なパッケージの導入が済んだので、本題の方に。
まず、作業フォルダに移動。

    # cd /usr/local/src

クローン。

    # git clone https://github.com/gcch/Chinachu-Sleep-Script.git

移動。

    # cd Chinachu-Sleep-Script

設定ファイルを弄る。 (詳細は中身を参照。)

    # cp settings.sample settings
    # vi settings

インストールを開始する。

    # chmod +x setup.sh
    # ./setup.sh < settings

で、おしまい。
設定を変えたいときは、もう一度インストールをすればいい。

-----

SSH 経由の sudo だと、PATH が引き継がれず、Python 3.x をインストールしていても、「そんなのない！」と言われる場合があります。

    $ sudo ./setup.sh < settings
    please install python 3.x.

その時には、下記のように実行してみてください。

    $ export PATH=$PATH
    $ sudo PATH=$PATH ./setup.sh < settings.sample

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
