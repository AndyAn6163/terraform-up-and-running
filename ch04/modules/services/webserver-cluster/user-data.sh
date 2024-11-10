#!/bin/bash

# Shebang (Hashbang) : 是由 #! + 解釋器絕對路徑， 用於指名這個腳本的解釋器
# Shebang (Hashbang) : !/bin/bash 開頭的檔案在執行時會實際呼叫 /bin/bash 程式

# 現在腳本沒有完整的 DOCTYPE html 會無法正常啟動

# 此例子無法正常啟動
# cat > index.html << EOF 
# <h1>Hello World, Andy</h1>
# <p>DB address: ${db_address}</p>
# <p>DB port: ${db_port}</p>
# EOF  

# 此例子無法正常啟動
# echo "<h1>Hello World, Andy</h1>" >> index.html 
# echo "<p>DB address: ${db_address}</p>" >> index.html
# echo "<p>DB port: ${db_port}</p>" >> index.html

# 此例子可正常啟動
cat > index.html << EOF

<!DOCTYPE html>
<html>
  <head>
    <title>Server Website</title>
  </head>
  <body>
    <h1>Hello World, Andy</h1>
    <p>Server Port: ${server_port}</p>
    <p>DB Address: ${db_address}</p>
    <p>DB Port: ${db_port}</p>
  </body>
</html>

EOF

nohup busybox httpd -f -p ${server_port} &

# https://www.runoob.com/linux/linux-shell-io-redirections.html
# Shell 输入/输出重定向
# command > file	将输出重定向到 file。
# command < file	将输入重定向到 file。
# command >> file	将输出以追加的方式重定向到 file。
# Here Document 是 Shell 中的一种特殊的重定向方式，用来将输入重定向到一个交互式 Shell 脚本或程序。
# Here Document : command << delimiter document delimiter : 作用是将两个 delimiter 之间的内容(document) 作为输入传递给 command
# Linux cat 命令 : 命令用于连接文件并打印到标准输出设备上，它的主要作用是用于查看和连接文件。
# 因此 cat > index.html << EOF .... EOF 或者 cat << EOF > index.html ... EOF 意思是
# 将两个 EOF 之间的内容作为输入传递給 cat，cat 打印到标准输出设备上，因為输出重定向到 index.html，因此內容輸出到 index.html
