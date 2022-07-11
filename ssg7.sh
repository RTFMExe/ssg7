#/usr/bin/env bash

sitename="rtfmexe"
description="Short description"
baseurl="http://localhost:8000"
lang="en"
copyright="2022 © xxxx"

render_html(){
local title=$1
local content=$2

local html="<!DOCTYPE html>
<html lang=\"${lang:=en}\">
<head>
<meta charset=\"utf-8\">
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
<title>${title}</title>
<style type=\"text/css\">
body {
  margin:40px auto;
  max-width:650px;
  line-height:1.6;
  font-size:16px;
  padding:0 10px;
  font-family: monospace;
  background: #f6f5f4;
  color: #575b5d;
}

header {
  padding-bottom: 15px;
}

footer {
  padding-top: 15px;
}

h1,h2,h3 {
  font-size: 22px;
}

a:link,a:visited,a:hover,a:active {
  text-decoration: none;
  color: #3584e4;
}
</style>
</head>
<body>
<header>
<nav>
<a href=\"$baseurl\">$sitename</a> 
•
<a href=\"$baseurl/feed.xml\">feed</a>
</nav>
</header>
<main>
<article>
$content
</article>
</main>
<footer>
<small>$copyright. Built with <a href=https://github.com/rtfmexe/ssg7>ssg7.</a></small>
</footer>
</html>
"

printf "$html"
}

wrap_index_content(){
local content=$1

local index_content="

<h1>Posts</h1>
<ul>
$content
</ul>
"

printf "$index_content"
}

generate_rss_feed(){
local content=$1

local rss_feed="<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">
<channel>
  <title>$sitename</title>
  <link>$baseurl</link>
  <description>$description</description>
  <atom:link href=\"${baseurl}feed.xml\" rel=\"self\" type=\"application/rss+xml\" />
  $content
</channel>
</rss>
"

printf "$rss_feed"
}

usage() {
  printf "usage: $0 SOURCE DEST\n"
  exit 1
}

[[ -d $1 ]] && source_dir=$1 || usage
[[ ! -z $2 ]] && dest_dir=$2 || usage

# remove trailing slash from baseurl
baseurl=${baseurl%/}

posts_dir="$dest_dir/posts"
posts_url="$baseurl/posts"

mkdir -p $posts_dir

mdfiles=($source_dir/*.md)
for ((i=${#mdfiles[@]}-1;i>=0;i--));do
  filename="${mdfiles[$i]##*/}"
  read -r pubdate fs_title ext <<< ${filename//./ }
  post=$(markdown $source_dir/$filename)
  [[ $post =~ \<h1\>(.*)\</h1\> ]] && post_title=${BASH_REMATCH[1]}

  render_html "$post_title" "$post" > $posts_dir/$fs_title.html

  # generate posts list for index
  posts_list+="
  <li> 
  <a href=\"$posts_url/$fs_title.html\">$post_title</a>
  <small> — <date>$pubdate</date></small>
  </li>
  "

  # generate rss item
  rss_items+="
  <item>
  <title>"$post_title"</title>
  <pubDate>$(date -d $pubdate --rfc-2822)</pubDate>
  <link>"$posts_url/$fs_title.html"</link>
  <guid>"$posts_url/$fs_title.html"</guid>
  </item>
  "
done

index_content=$(wrap_index_content "$posts_list")
render_html "$sitename" "$index_content" > $dest_dir/index.html
generate_rss_feed "$rss_items" > $dest_dir/feed.xml