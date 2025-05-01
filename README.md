# wp-update
WordPress backup script using WP-CLI commands

# 注意事項

本ツールは、さくらインターネットのレンタルサーバーで動作検証しています。

ただし、シェルスクリプト等サーバー上に ssh ログインして WordPress を手動で圧縮したり、解凍できるスキルを思っていることを前提としています。

このツールは自由に改変、利用してもらって構いませんが、これを実行することで起こる問題については責任はとりません。

# このツールができること
バックアップをしてから、WordPress 本体のアップデート、プラグインのアップデート、言語のアップデートを行います。
テーマのアップデートはしません。

# ファイルの置き場
wp-backup-targets.dat

wp-update.csh

wp-update.csh 内の下記で指定されたフォルダ内の bin ディレクトリに置いてください。

set base_dir = "/home/${SERVER_USERID}/backup"

例：set back_dir = /home/userid/backup の場合、下記のディレクトリに入れます。

/home/userid/backup/bin/

# wp-backup-targets.dat の説明

WordPress のバックアップをする設定ファイルです。

本ファイルの形式は下記の形式にします。

バックアップフォルダ名:バックアップの保管日数:WordPress本体の言語:バックアップの圧縮形式:WordPress本体のフォルダPath

例：
バックアップフォルダ：/home/userid/backup/backup/sample1
バックアップの保管日数：7 （デフォルトは7）
WordPress本体の言語：ja （WordPress Core のアップデートにおいて、どの言語のバージョンにするか選択できます）
バックアップの圧縮形式：tar.gz （デフォルトは tar.gz。その他、 tar.bz2、tar.xz、zip を選択できます）
WordPress本体のフォルダPath：/home/userid/www/sample1

上記の例の場合には、下記の設定を wp-backup-targets.dat に追加してください。
複数行ある場合には、複数の WordPress で処理されます。
行に # があると、その行は無視されます（コメントできます）

sample1:7:ja:tar.gz:/home/userid/www/sample1

# wp-update.csh の説明
実際に実行する CSH プログラムです。

初期設定を行ったあと、

csh -xf wp-update.csh などで動作させたあとは、OSの cron によって自動化実行するタスク登録しておけばよいでしょう。

バックアップファイルについては、ファイル名に manually がつくと削除対象から外れます。

それ以外については、指定の日時がすぎると削除されるので注意が必要です。

# 初期設定

## ディレクトリの作成
ホームディレクトリ：/home/userid

バックアップディレクトリ：/home/userid/backup

WordPress のバックアップディレクトリ：/home/userid/backup/backup

本ツール実行ディレクトリ：/home/userid/backup/bin

WordPress本体ディレクトリ：/home/userid/www


と仮定します。

＊実行ログは、/home/userid/backup/logs/YYYYMMDD.log （年月日）に保存されます。

下記のように、バックアップのためのディレクトリを作成してください。

1. cd 
2. mkdir backup
3. chmod 700 backup
4. mkdir -p backup/bin backup/logs backup/backup
5. WP-CLI を /home/userid/backup/bin にインストールしてください。
wp コマンドとして実行できるようにしてください。
6. 次に、/home/userid/backup/bin に、下記を置いてください
wp-backup-targets.dat
wp-update.csh
7. wp-backup-target.dat を編集して、自分なりの環境になったものに書き換えてください。
8. wp-update.csh を編集して、自分なりの環境になったものに書き換えてください。
最低限に必要な変更は次の通り
set SERVER_USERID = "userid" （useridを変更）

あとは、 csh -xf wp-update.csh 

などで実行し、正しく実行できるか確認してください。

＊なお userid で期待しているのは $USER です。

ただ全ての環境でユーザー名の変数 $USER があるかどうかわからないので、手動設定するようにしてます。


