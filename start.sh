#!/bin/sh

#sed -i 's,\(memory_limit *= *\).*,\1'${MEMORY_LIMIT}',' /etc/php/7.0/fpm/php.ini
#sed -i 's,\(post_max_size *= *\).*,\1'${POST_MAX_SIZE}',' /etc/php/7.0/fpm/php.ini
#sed -i 's,\(upload_max_filesize *= *\).*,\1'${UPLOAD_MAX_FILESIZE}',' /etc/php/7.0/fpm/php.ini
#sed -i 's,\(pm\.max_children *= *\).*,\1'${MAX_CHILDREN}','/etc/php/7.0/fpm/pool.d/www.conf

#( echo "[www]"; env | sed -n "s/'/\\\\'/g;s/\([^=]*\)=\(..*\)/env[\1]='\2'/p" ) > /etc/php/7.0/fpm/pool.d/env.conf

php-fpm7 -F
