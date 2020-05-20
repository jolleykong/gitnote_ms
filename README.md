# GitNote Of MySQL

KK's learning note.

在2020年5月19日，GitNote就打不开了。
接下来使用VS Code with WSL2 ，来实现git note的功能。

# 一级标题
正文
## 二级标题
正文
### 三级标题
- 列表1
- 列表2
- 列表3  
1. 序列1
2. 序列2
正文
++下划线1++， ~~删除线1~~， 文字^上角标^， *斜体字*，

正文：
下面**粗体**是代码：
```
Git删除当前分支下的所有历史版本与log并同步至GitHub
git checkout --orphan latest_branch
git add -A
git commit -am "clean history"
git branch -D master
git branch -m master
git push -f origin master

```
代码结束了。