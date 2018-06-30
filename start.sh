#!/bin/sh

if ! grep -q 'location ~\* \\\.php$ {' /etc/nginx/conf.d/default.conf; then
    sed -i -e 's,^\([ \t]*index\) \(index.html.*\);,\1 index.php \2;,' /etc/nginx/conf.d/default.conf
    sed -i -e '/^}/i\
\
  location ~* \\.php$ {\
    fastcgi_pass    localhost:9000;\
    include         fastcgi_params;\
    fastcgi_param   SCRIPT_FILENAME    $document_root$fastcgi_script_name;\
    fastcgi_param   SCRIPT_NAME        $fastcgi_script_name;\
  }\
' /etc/nginx/conf.d/default.conf
    echo "**** php enabled"
fi

sed -i 's,\(memory_limit *= *\).*,\1'${MEMORY_LIMIT}',' /etc/php7/php.ini
sed -i 's,\(post_max_size *= *\).*,\1'${POST_MAX_SIZE}',' /etc/php7/php.ini
sed -i 's,\(upload_max_filesize *= *\).*,\1'${UPLOAD_MAX_FILESIZE}',' /etc/php7/php.ini
sed -i 's,\(pm\.max_children *= *\).*,\1'${MAX_CHILDREN}',' /etc/php7/php-fpm.d/www.conf

( echo "[www]"; env | sed -n "s/'/\\\\'/g;s/\([^=]*\)=\(..*\)/env[\1]='\2'/p" ) > /etc/php7/php-fpm.d//env.conf

for f in /config-*; do
    if test -x $f; then
        $f
    fi
done

echo "**** starting php"
php-fpm7
echo "**** starting nginx"
/usr/sbin/nginx