## 事前準備
権限エラーで時間を取られるのを防ぐため、最初に一括設定します。

『sudo chown -R ec2-user:ec2-user public/』


## STEP 01：初期セットアップ


### 1. SSHログイン
```
ssh ec2-user@{IPアドレス} -i {秘密鍵ファイルのパス}
```


### 2. エディタ設定

作業効率化のため、Vimの設定を済ませます。
```
コマンド: vim ~/.vimrc
```
```
Vim Script
set number
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
```



### 3. 便利ツールの導入

```
sudo yum install vim screen -y
```
```
コマンド: vim ~/.screenrc
```

```
hardstatus alwayslastline "%{= bw}%-w%{= wk}%n%t*%{-}%+w"
```



## STEP 02：Docker環境構築


### 4. Dockerインストール

```
sudo yum install -y docker

sudo systemctl start docker

sudo systemctl enable docker

sudo usermod -a -G docker ec2-user
```
※ここで一度 exit して再ログインしてください。




### 5. Docker Composeインストール

```
sudo mkdir -p /usr/local/lib/docker/cli-plugins/

sudo curl -SL https://github.com/docker/compose/releases/download/v2.36.0/docker-

compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose

sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```




## STEP 03：設定ファイルの作成




### 6. compose.yml
```
コマンド: vim compose.yml
```


```
services:
  web:
    image: nginx:latest  
    ports: [ "80:80" ]
    volumes:
      - ./nginx/conf.d/:/etc/nginx/conf.d/
      - ./public/:/var/www/public/
      - image:/var/www/upload/image/
    depends_on: [ php ]
  php:
    container_name: php
    build: { context: ., target: php }
    volumes:
      - ./public/:/var/www/public/
      - image:/var/www/upload/image/
  mysql:
    container_name: mysql
    image: mysql:8.4
    environment:
      MYSQL_DATABASE: example_db 
      MYSQL_ALLOW_EMPTY_PASSWORD: 1
      TZ: Asia/Tokyo
    volumes: [ mysql:/var/lib/mysql ]
    command: >
      mysqld --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --max_allowed_packet=4MB
  redis:
    container_name: redis
    image: redis:latest
    ports: [ "6379:6379" ]
volumes: { mysql: , image: }
```


## 7. Nginx設定

```
mkdir -p nginx/conf.d
```
```
vim nginx/conf.d/default.conf
```



```
server {
    listen       0.0.0.0:80;
    server_name  _;
    charset      utf-8;
    client_max_body_size 6M;
    root /var/www/public;
    location ~ \.php$ {
        fastcgi_pass  php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include       fastcgi_params;
    }
    location /image/ {
        root /var/www/upload;
    }
}
```

## 8. PHP Dockerfile

```
vim Dockerfile
```


```
FROM php:8.4-fpm-alpine AS php
RUN apk add --no-cache autoconf build-base \
&& yes '' | pecl install redis \
&& docker-php-ext-enable redis
RUN docker-php-ext-install pdo_mysql
RUN install -o www-data -g www-data -d /var/www/upload/image/
COPY ./php.ini ${PHP_INI_DIR}/php.ini
```



## STEP 04：DB構築とファイル配置


### 9. MySQLテーブル作成
```
docker compose exec mysql mysql example_db 
```

を実行し、SQLを貼り付けます。


１行ずつお願いします




### SQL

```
CREATE TABLE `access_logs` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `user_agent` TEXT NOT NULL, `remote_ip` TEXT NOT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE `bbs_entries` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `user_id` INT UNSIGNED NOT NULL, `body` TEXT NOT NULL, `image_filename` TEXT DEFAULT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE `user_relationships` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `followee_user_id` INT UNSIGNED NOT NULL, `follower_user_id` INT UNSIGNED NOT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE `users` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` TEXT NOT NULL, `email` TEXT NOT NULL, `password` TEXT NOT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

ALTER TABLE `users` ADD COLUMN icon_filename TEXT DEFAULT NULL, ADD COLUMN introduction TEXT DEFAULT NULL, ADD COLUMN cover_filename TEXT DEFAULT NULL, ADD COLUMN birthday DATE DEFAULT NULL;
```



### 10. ファイル転送

ローカルPCのターミナルから実行します。

```
scp -i {秘密鍵のパス} -r {publicディレクトリのパス} ec2-user@{IPアドレス}:/home/ec2-user/
```


### 11. パーミッション修正

```
chmod 755 public/
chmod 644 public/*.php
chmod 755 public/setting/
chmod 644 public/setting/*.php
```




## STEP 05：起動


### 12. コンテナ起動

```
docker compose up -d --build
```


### 13. ブラウザ確認

```
http://{パブリックIPアドレス}/signup.php
```


