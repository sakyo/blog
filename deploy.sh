#!/bin/sh
cd /root/docs/blog
git pull
hexo g
echo "Finished."
